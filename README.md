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

1. Clone the apigee-samples repo, and switch to the cors directory

```bash
git clone https://github.com/apigeek3000/apigee-networking-101.git
```

2. Ensure you have an active GCP account selected in the Cloud shell

```sh
gcloud auth login
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

# Deploy Networking components

## Deploy Apigee components

Next, let's deploy our hello-world proxy. This proxy will include one `hello-world` proxy.

```bash
./deploy-hello-world.sh
```

## Conclusion & Cleanup

Congratulations! You've successfully deployed a test Apigee enviornment

To clean up the artifacts created run the following to delete your sample Apigee components:

```bash
source ./env.sh
./clean-up-hello-world.sh
```