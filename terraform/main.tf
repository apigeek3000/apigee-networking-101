/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  subnet_region_name = { for subnet in var.exposure_subnets :
    subnet.region => "${subnet.region}/${subnet.name}"
  }
  psc_subnet_region_name = { for subnet in var.psc_ingress_subnets :
    subnet.region => "${subnet.region}/${subnet.name}"
  }
  apigee_instances_mig_map = var.mig_nb ? var.apigee_instances : {}
  apigee_instances_psc_map = var.psc_nb ? var.apigee_instances : {}
}


# ======= Enable APIs and set needed org policies at the project level ======= 
module "project" {
#  count           = var.mig_nb || var.psc_nb ? 1 : 0
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v28.0.0"
  name            = var.project_id
  parent          = var.project_parent
  billing_account = var.billing_account
  project_create  = var.project_create
  services = [
    "apigee.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "org-policy" {
  count       = var.mig_nb ? 1 : 0
  source      = "terraform-google-modules/org-policy/google"
  policy_for  = "project"
  project_id  = var.project_id
  constraint  = "constraints/compute.requireShieldedVm"
  policy_type = "boolean"
  enforce     = false
  #  version           = "~> 3.0.2"
}


# ======= VPC for VPC Peering (PSA) to Apigee ======= 
module "vpc" {
  count      = var.mig_nb || var.psc_nb ? 1 : 0
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v28.0.0"
  project_id = var.project_id
  name       = var.network
  subnets    = var.exposure_subnets
  psa_config = {
    ranges = {
      apigee-range         = var.peering_range
      apigee-support-range = var.support_range
    }
  }
}

# ======= Cert and public IP for Northbound Load Balancer(s) ======= 
module "nip-development-hostname" {
  count              = var.mig_nb ? 1 : 0
  source             = "github.com/apigee/terraform-modules/modules/nip-development-hostname"
  project_id         = var.project_id
  address_name       = "apigee-external"
  subdomain_prefixes = [for name, _ in var.apigee_envgroups : name]
}

module "nip-development-hostname-psc" {
  count              = var.psc_nb ? 1 : 0
  source             = "github.com/apigee/terraform-modules/modules/nip-development-hostname"
  project_id         = var.project_id
  address_name       = "apigee-external-psc"
  subdomain_prefixes = [for name, _ in var.apigee_envgroups : name]
}


# ======= Apigee setup (API Proxy done separately since not in Terraform) ======= 
module "apigee-x-core" {
#  count               = var.mig_nb || var.psc_nb ? 1 : 0
  source              = "github.com/apigee/terraform-modules/modules/apigee-x-core"
  project_id          = var.project_id
  ax_region           = var.ax_region
  apigee_environments = var.apigee_environments
  apigee_envgroups = {
    test = {
      hostnames = var.mig_nb && var.psc_nb ? [module.nip-development-hostname[0].hostname, module.nip-development-hostname-psc[0].hostname] : var.mig_nb ? [module.nip-development-hostname[0].hostname] : [module.nip-development-hostname-psc[0].hostname]
    }
  }
  apigee_instances = var.apigee_instances
  network          = module.vpc[0].network.id
}


# ======= Load balancer and MIG for Northbound Apigee Access ======= 
module "apigee-x-bridge-mig" {
  source      = "github.com/apigee/terraform-modules/modules/apigee-x-bridge-mig"
  for_each    = local.apigee_instances_mig_map
  project_id  = var.project_id
  network     = module.vpc[0].network.id
  subnet      = module.vpc[0].subnet_self_links[local.subnet_region_name[each.value.region]]
  region      = each.value.region
  endpoint_ip = module.apigee-x-core.instance_endpoints[each.key]
}

module "mig-l7xlb" {
  count           = var.mig_nb ? 1 : 0
  source          = "github.com/apigee/terraform-modules/modules/mig-l7xlb"
  project_id      = var.project_id
  name            = "apigee-xlb1"
  backend_migs    = [for _, mig in module.apigee-x-bridge-mig : mig.instance_group]
  ssl_certificate = [module.nip-development-hostname[0].ssl_certificate]
  external_ip     = module.nip-development-hostname[0].ip_address
}


# ======= PSC for Northbound Apigee Access ======= 
module "psc-ingress-vpc" {
  count                   = var.psc_nb ? 1 : 0
  source                  = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v28.0.0"
  project_id              = var.project_id
  name                    = var.psc_ingress_network
  auto_create_subnetworks = false
  subnets                 = var.psc_ingress_subnets
}

resource "google_compute_region_network_endpoint_group" "psc_neg" {
  project               = var.project_id
  for_each              = local.apigee_instances_psc_map
  name                  = "psc-neg-${each.value.region}"
  region                = each.value.region
  network               = module.psc-ingress-vpc[0].network.id
  subnetwork            = module.psc-ingress-vpc[0].subnet_self_links[local.psc_subnet_region_name[each.value.region]]
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = module.apigee-x-core.instance_service_attachments[each.value.region]
  lifecycle {
    create_before_destroy = true
  }
}

module "nb-psc-l7xlb" {
  count           = var.psc_nb == true ? 1 : 0
  source          = "github.com/apigee/terraform-modules/modules/nb-psc-l7xlb"
  project_id      = var.project_id
  name            = "apigee-xlb-psc"
  ssl_certificate = [module.nip-development-hostname-psc[0].ssl_certificate]
  external_ip     = module.nip-development-hostname-psc[0].ip_address
  psc_negs        = [for _, psc_neg in google_compute_region_network_endpoint_group.psc_neg : psc_neg.id]
}




# ======= PSC for Southbound including Service Attachment and Load Balancer to reach from Apigee to a sample MIG-based backend ======= 

module "backend-vpc" {
  count           = var.psc_sb_mig == true ? 1 : 0
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v28.0.0"
  project_id = module.project.project_id
  name       = var.backend_network
  subnets = [
    var.backend_subnet,
  ]
}

module "backend-example" {
  count           = var.psc_sb_mig == true ? 1 : 0
  source     = "github.com/apigee/terraform-modules/modules/development-backend"
  project_id = module.project.project_id
  name       = var.backend_name
  network    = module.backend-vpc[0].network.id
  subnet     = module.backend-vpc[0].subnet_self_links["${var.backend_subnet.region}/${var.backend_subnet.name}"]
  region     = var.backend_region
}

resource "google_compute_subnetwork" "psc_nat_subnet" {
  count           = var.psc_sb_mig == true ? 1 : 0
  name          = var.backend_psc_nat_subnet.name
  project       = module.project.project_id
  region        = var.backend_region
  network       = module.backend-vpc[0].network.id
  ip_cidr_range = var.backend_psc_nat_subnet.ip_cidr_range
  purpose       = "PRIVATE_SERVICE_CONNECT"
}

module "southbound-psc" {
  count           = var.psc_sb_mig == true ? 1 : 0
  source              = "github.com/apigee/terraform-modules/modules/sb-psc-attachment"
  project_id          = module.project.project_id
  name                = var.psc_name
  region              = var.backend_region
  apigee_organization = module.apigee-x-core.org_id
  nat_subnets         = [google_compute_subnetwork.psc_nat_subnet[0].id]
  target_service      = module.backend-example[0].ilb_forwarding_rule_self_link
  depends_on = [
    module.apigee-x-core.instance_endpoints
  ]
}

resource "google_compute_firewall" "allow_psc_nat_to_backend" {
  count           = var.psc_sb_mig == true ? 1 : 0
  name          = "psc-nat-to-demo-backend"
  project       = module.project.project_id
  network       = module.backend-vpc[0].network.id
  source_ranges = [var.backend_psc_nat_subnet.ip_cidr_range]
  target_tags   = [var.backend_name]
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}
