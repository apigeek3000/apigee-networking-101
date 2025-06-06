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

variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "mig_nb" {
  description = "Set to true to create a Apigee network bridge, which are proxies in a MIG behind a Load Balancer, to reach Apigee Northbound (client to Apigee)"
  type        = bool
}

variable "psc_nb" {
  description = "Set to true to create a PSC Backend / NEG behind a Load Balancer to reach Apigee Northbound (client to Apigee)"
  type        = bool
}

variable "psc_sb_mig" {
  description = "Set to true to create a PSC Endpoint, Service Attachment and Load Balancer for Apigee to reach Southhbound (client to Apigee)"
  type        = bool
}

variable "ax_region" {
  description = "GCP region for storing Apigee analytics data (see https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
}

variable "apigee_envgroups" {
  description = "Apigee Environment Groups."
  type = map(object({
    hostnames = list(string)
  }))
  default = null
}

variable "apigee_instances" {
  description = "Apigee Instances (only one instance for EVAL orgs)."
  type = map(object({
    region       = string
    ip_range     = string
    environments = list(string)
  }))
  default = null
}

variable "apigee_environments" {
  description = "Apigee Environments."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    node_config = optional(object({
      min_node_count = optional(number)
      max_node_count = optional(number)
    }))
    iam       = optional(map(list(string)))
    envgroups = list(string)
    type      = optional(string)
  }))
  default = null
}

variable "exposure_subnets" {
  description = "Subnets for exposing Apigee services"
  type = list(object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  }))
  default = []
}

variable "network" {
  description = "VPC name."
  type        = string
}

variable "peering_range" {
  description = "Peering CIDR range"
  type        = string
}

variable "support_range" {
  description = "Support CIDR range of length /28 (required by Apigee for troubleshooting purposes)."
  type        = string
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "project_parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.project_parent == null || can(regex("(organizations|folders)/[0-9]+", var.project_parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = false
}

variable "psc_ingress_network" {
  description = "PSC ingress VPC name."
  type        = string
}

variable "psc_ingress_subnets" {
  description = "Subnets for exposing Apigee services via PSC"
  type = list(object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  }))
  default = []
}

variable "backend_name" {
  description = "Name for the Demo Backend"
  type        = string
  default     = "demo-backend"
}

variable "backend_network" {
  description = "Peered Backend VPC name."
  type        = string
}

variable "backend_region" {
  description = "GCP Region Backend (ensure this matches backend_subnet.region)."
  type        = string
}

variable "backend_subnet" {
  description = "Subnet to host the backend service."
  type = object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  })
}

variable "backend_psc_nat_subnet" {
  description = "Subnet to host the PSC NAT."
  type = object({
    name          = string
    ip_cidr_range = string
  })
}

variable "psc_name" {
  description = "PSC name."
  type        = string
}
