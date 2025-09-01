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

project_id = "INSERT YOUR PROJECT_ID HERE"

mig_nb = true  # Set to true to create a Apigee network bridge, which are proxies in a MIG behind a Load Balancer, to reach Apigee Northbound (client to Apigee)
psc_nb = true  # Set to true to create a PSC Backend / NEG behind a Load Balancer to reach Apigee Northbound (client to Apigee)
psc_sb_mig = true # Set to true to create a PSC Backend behind Apigee to reach a southbound, private service (Apigee to backend service)

# Since this is a Proof of Concept / PoC-ready script, no need to change settings below. Changing will customize the setup. 
# Full testing has not been done on customization, so if you customize and encounter errors, please report them and the suggestion is to return to values provided to get the script working.  

ax_region = "us-central1"

apigee_instances = {
  us-central1-instance = {
    region       = "us-central1"
    ip_range     = "10.0.0.0/22"
    environments = ["test"]
  }
}

apigee_environments = {
  test = {
    display_name = "Test"
    description  = "Environment created by apigee/terraform-modules"
    node_config  = null
    iam          = null
    envgroups    = ["test"]
    type         = null
  }
}


# must add a domain here, though only nip.io domain will be used, so doesn't matter what you add here
apigee_envgroups = {
  test = {
    hostnames = ["example.com"]
  }
}

network = "vpc-northbound-peering"

exposure_subnets = [
  {
    name               = "apigee-exposure"
    ip_cidr_range      = "10.100.0.0/24"
    region             = "us-central1"
    secondary_ip_range = null
  }
]

psc_ingress_network = "vpc-northbound-psc"

psc_ingress_subnets = [
  {
    name               = "apigee-psc-us-central1"
    ip_cidr_range      = "10.101.0.0/24"
    region             = "us-central1"
    secondary_ip_range = null
  }
]

peering_range = "10.0.0.0/22"
support_range = "10.1.0.0/28"

backend_network = "vpc-southbound-backend"
backend_region  = "us-central1"
backend_subnet = {
  name               = "backend-us-central1"
  ip_cidr_range      = "10.200.0.0/28"
  region             = "us-central1"
  secondary_ip_range = null
}
backend_psc_nat_subnet = {
  ip_cidr_range = "10.0.4.0/22"
  name          = "psc-nat-us-central1"
}

psc_name = "apigeepscsb"
