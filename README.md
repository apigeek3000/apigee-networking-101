# apigee-networking-101
This includes deployment scripts for an Apigee PayG org with various methods of internal &amp; external networking enabled

## Prerequisites

1. Full access to deploy an Apigee organization & it's networking components (TODO: Get more specific)
2. Access to deploy API proxies on Apigee
3. Make sure the following tools are available in your terminal's $PATH (Cloud Shell has these preconfigured)
    * [gcloud SDK](https://cloud.google.com/sdk/docs/install)
    * unzip
    * curl

## Setup instructions

1. Clone the this repo to your machine

```bash
git clone https://github.com/apigeek3000/apigee-networking-101.git
```

2. Ensure you have an active GCP account selected in the Cloud shell

```sh
gcloud auth login
gcloud auth application-default login
```

3. Edit the `env.sh` and configure the ENV vars

* `PROJECT` the project where your Apigee organization is located
* `APIGEE_HOST` the externally reachable hostname of the Apigee environment group that contains APIGEE_ENV
* `APIGEE_ENV` the Apigee environment where the demo resources should be created

Now source the `env.sh` file

```bash
source ./env.sh
```

## Deploy Apigee Organization

To deploy Apigee X with only a basic internal ip endpoint, follow the [x-basic](https://github.com/apigee/terraform-modules/tree/main/samples/x-basic) guide

You may find it easier to test Apigee with an external HTTPS endpoint. Follow one of the following guides if that's the case:
- [x-l7xlb](https://github.com/apigee/terraform-modules/tree/main/samples/x-l7xlb)
- [x-nb-psc-xlb](https://github.com/apigee/terraform-modules/tree/main/samples/x-nb-psc-xlb)

## Deploy other Networking components

To deploy networking components together with Apigee (all but the API Proxy), follow this process:
1. Create a project in GCP, if not already created. Reference if needed [Creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
2. Set values in terraform.tfvars. project-id is the only value that needs to change to match the ID of the project created in step 1. Reference if needed for how to find project ID, see [Find the project name, number, and ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)
3. At the command prompt where you'll run the script, in the Terraform directory, run:
  * `terraform init`
  * `terraform plan`
  * `terraform apply -auto-approve`
4. Wait ~35-40 minutes for the script to complete. You'll see a message similar to "Apply complete!" and then move to the next section.


## Deploy Apigee components

Next, let's deploy our hello-user proxy. This proxy will include one `hello-user` proxy.

```bash
./terraform/deploy/deploy-hello-user.sh
```

To test the API call to the following API, https://{{API hostname}}/v1/hello-user, and substitute in your own API hostname or use the following curl command

```bash
curl -X GET "https://{{API hostname}}/v1/hello-user"
```


## Test Apigee

Note: It can take 24 hours for the certificate to move to Status of ACTIVE. From testing, it is usually much faster, less than 1 hour. If you see Status of FAILED_NOT_VISIBLE, the certificate is needs more time to validate. See [Domain status](https://cloud.google.com/load-balancing/docs/ssl-certificates/troubleshooting#domain-status) for more information. 

Go to Network Services > Load Balancing and select the load balancer named "apigee-xlb". In the Frontend section, click the link under the heading "Certificate". Verify that the cert in the load balancer is Status of ACTIVE. Once it is active, find the domain which is based on a public IP address created in the script. It will be in the form of #-#-#-#.nip.io. 

To test, put the nip.io domain into the browser, in this form: 
https://#-#-#-#.nip.io/hello-world

Example: 
https://34-117-214-37.nip.io/hello-world


## Conclusion & Cleanup

Congratulations! You've successfully deployed a test Apigee enviornment

To clean up the artifacts created run the following to delete your sample Apigee components:

```bash
source ./env.sh
./terraform/clean-up/clean-up-hello-user.sh
```

At the command prompt in the Terraform directory, run:
`terraform destroy -auto-approve`

Wait ~15-25 minutes for the components created by the Terraform script to be removed. You'll see a message similar to "Destroy complete!" 
