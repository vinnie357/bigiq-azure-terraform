setup env vars:
```bash
export ARM_RESOURCE_GROUP=${arm_resource_group}
export ARM_SUBSCRIPTION_ID=${arm_subscription_id}
export ARM_TENANT_ID=${arm_tenant_id}
export ARM_CLIENT_ID=${arm_client_id}
export ARM_CLIENT_SECRET=${arm_client_secret}
```
start container:
```bash
make dev
```

# list location and regions

az account list-locations

bash-5.0#  az account list-locations | grep -i 'east us'
    "displayName": "East US",
    "displayName": "East US 2",

# list market place images
https://docs.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest


az vm image list -f CentOS


az vm image list -f Ubuntu

## list publisher
az vm image list-publishers -l eastus --query "[?starts_with(name, 'f5-networks')]"

## list offers
-l location -p publisher
az vm image list-offers -l eastus -p f5-networks
# f5-big-ip-advanced-waf,f5-big-ip-best,f5-big-iq
az vm image list-offers -l eastus -p f5-networks --query "[?starts_with(name, 'f5-big-iq')]"

# list skus
-l location --offer -p publisher
az vm image list-skus -l eastus --offer f5-big-iq -p f5-networks

# image details
```bash
latest=$(az vm image list -p f5-networks --all --query \
    "[?offer=='f5-big-iq'].version" -o tsv | sort -u | tail -n 1)
az vm image show -l eastus -f f5-big-iq -p f5-networks --sku f5-bigiq-virtual-edition-byol --version ${latest}

#example:
{
  "automaticOsUpgradeProperties": {
    "automaticOsUpgradeSupported": false
  },
  "dataDiskImages": [],
  "hyperVgeneration": null,
  "id": "/Subscriptions/9872233-3242345234-12324411/Providers/Microsoft.Compute/Locations/eastus/Publishers/f5-networks/ArtifactTypes/VMImage/Offers/f5-big-iq/Skus/f5-bigiq-virtual-edition-byol/Versions/7.0.001000",
  "location": "eastus",
  "name": "7.0.001000",
  "osDiskImage": {
    "operatingSystem": "Linux",
    "sizeInBytes": 102005473792,
    "sizeInGb": 95
  },
  "plan": {
    "name": "f5-bigiq-virtual-edition-byol",
    "product": "f5-big-iq",
    "publisher": "f5-networks"
  },
  "tags": null
}
```