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

if [ -z "$PROJECT" ]; then
  echo "No PROJECT variable set"
  exit
fi

# Optional Variable
# if [ -z "$APIGEE_HOST" ]; then
#   echo "No APIGEE_HOST variable set"
#   exit
# fi

# Optional Variable
# if [ -z "$APIGEE_PSC_HOST" ]; then
#   echo "No APIGEE_PSC_HOST variable set"
#   exit
# fi

if [ -z "$APIGEE_ENV" ]; then
  echo "No APIGEE_ENV variable set"
  exit
fi

# Optional Variable
# if [ -z "$PSC_DOMAIN" ]; then
#   echo "No PSC_DOMAIN variable set"
#   exit
# fi

echo "Passed variable tests"

TOKEN=$(gcloud auth print-access-token)

echo "Installing apigeecli"
curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
export PATH=$PATH:$HOME/.apigeecli/bin

echo "Deploying Apigee artifacts..."

if [ "$PSC_DOMAIN" ]; then
  echo "Updating proxy code with custom variables"
  sed -i "" -e "s/{{psc-domain}}/$PSC_DOMAIN/g" "$PWD/apiproxy/targets/private-psc.xml"
fi

echo "Creating and Deploying Apigee hello-user proxy..."
REV=$(apigeecli apis create bundle -f ./apiproxy -n hello-user --org "$PROJECT" --token "$TOKEN" --disable-check | jq ."revision" -r)
apigeecli apis deploy --wait --name hello-user --ovr --rev "$REV" --org "$PROJECT" --env "$APIGEE_ENV" --token "$TOKEN"

echo " "
echo "All the Apigee artifacts are successfully deployed!"

if [ "$APIGEE_HOST" ]; then
  export PROXY_URL="$APIGEE_HOST/v1/hello-user"
  echo " "
  echo "Your Proxy URL is: https://$PROXY_URL"
  echo "The above URL calls to a private southbound endpoint. Add the proxy suffix /external to call the external southbound endpoint"
fi

if [ "$APIGEE_PSC_HOST" ]; then
  export PROXY_PSC_URL="$APIGEE_PSC_HOST/v1/hello-user"
  echo " "
  echo "Your Proxy PSC URL is: https://$PROXY_PSC_URL"
  echo "The above URL calls to a private southbound endpoint. Add the proxy suffix /external to call the external southbound endpoint"
fi

echo " "
