#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export PROJECT="example-gcp-project" # Find GCP Project ID in Project Settings
export APIGEE_HOST="#-#-#-#.nip.io" # Find the Apigee Env Group hostname associated with the lb-nb-apigee-pscneg load balancer
export APIGEE_PSC_HOST="#-#-#-#.nip.io" # Find the Apigee Env Group hostname associated with the lb-nb-apigee-mig load balancer
export APIGEE_ENV="test" # Find in Apigee Environments
export PSC_DOMAIN="#.#.#.#" # Find in Apigee Endpoint Attachments (host column)

gcloud config set project $PROJECT