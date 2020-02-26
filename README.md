# bigiq-azure-terraform
BIG-IQ deployment in Azure using Terraform

# Overview
This example deploys a single BIG-IQ centralized manager in Azure cloud using terraform
[BIG-IQ Azure](images/bigiq.png "BIG-IQ Azure")

# Requirements
- bash
- gcc make
- Azure credentials
- ssh public/private key pair
- BIG-IQ license or trial key
- docker

# Running
- populate the .envVarsHelperExample.sh
    - create a service Principal client secret to use: 
    
        https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html
    -  ```bash # azure
        arm_resource_group=""
        arm_client_id=""
        arm_client_secret=""
        arm_subscription_id=""
        arm_tenant_id=""
        # creds
        # ssh_key_dir="$(echo $HOME)/.ssh"
        # ssh_key_name="id_rsa"
        ssh_key_dir=""
        ssh_key_name=""
        azure_ssh_key_name=""
        azure_pub_key_name=""
       ```
- populate env.auto.tfvars
    - ```hcl
    # set location
    # variable location { default = "usgovvirginia" }
    # variable region { default = "USGov Virginia" }
    # variable prefix { default = "scca" }
    # required
    location = "eastus2"
    region = "East US2"
    prefix = "bigiq-tf"
    bigIqLicenseKey1= "BIG-IQ-KEY-HERE"
    subscriptionID= "my-azure-subscriptionID"
    adminSourceRange= "192.168.2.0/24"
    # optional
    #adminAccountName="xadmin"
    #adminAccountPassword="mypassword!!"
      ```
- set environment variables for your current shell
    - ```bash
        . .envVarsHelperExample.sh
      ```
    - look for "env vars done"
- create container
    - ```bash
       make build
      ```
-  test container
    - ```bash
      make test
      ```
    - if all tests pass continue
- create bigiq in azure
    - ```bash
       make azure
      ```
    - note sometimes you may need to apply again for the management address to show up in the terraform outputs
- destroy bigiq in azure
    - ```bash
       make destroy
      ```

# Optional

- make shell
    - runs the container and drops you into a shell were you can run the terraform commands directly

