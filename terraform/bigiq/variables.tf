
# Azure Environment
variable prefix { default = "bigiq" }
variable uname { default = "xadmin" }
variable upassword { default = "2018F5Networks!!" }
variable location { default = "eastus2" }
variable region { default = "East US 2" }

variable "adminSourceRange" {  default = "*" }


# NETWORK
variable cidr { default = "10.90.0.0/16" }
variable "subnets" {
  type = "map"
  default = {
    "subnet1" = "10.90.1.0/24"
    "subnet2" = "10.90.2.0/24"
    "subnet3" = "10.90.3.0/24"
  }
}
variable f5vm01mgmt { default = "10.90.1.4" }
variable f5vm01ext { default = "10.90.2.4" }
variable f5vm01ext_sec { default = "10.90.2.11" }
variable f5vm01int { default = "10.90.3.4"}
variable f5vm02mgmt { default = "10.90.1.5" }
variable f5vm02ext { default = "10.90.2.5" }
variable f5vm02ext_sec { default = "10.90.2.12" }
variable f5vm02int { default = "10.90.3.5"}
variable backend01ext { default = "10.90.2.101" }

# BIGIQ Image
variable instance_type { default = "Standard_D4s_v3" }
variable image_name { default = "f5-bigiq-virtual-edition-byol" }
variable product { default = "f5-big-iq" }
variable bigip_version { default = "latest" }

# BIGIQ Setup
variable license1 { default = "" }
variable license2 { default = "" }
variable host1_name { default = "f5vm01" }
variable host2_name { default = "f5vm02" }
variable dns_servers { default = "8.8.8.8" }
variable dns_search_domains { default = "example.com" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone { default = "UTC" }
variable onboard_log { default = "/var/log/startup-script.log" }
#
variable "deploymentId" {
    default= "bigiq-test"
  
}
variable "subscriptionID" {
  default= "my-azure-subscription-id"
}
variable "allowUsageAnalytics" {
    default= false
  
}
variable intSubnetPrivateAddress { default = "10.90.3.4"}
variable "f5CloudLibsAzureTag" {
  description="release from f5-cloud-libs https://github.com/F5Networks/f5-cloud-libs-azure/releases"
  default="v2.12.0"
}
variable "f5CloudLibsTag" {
  description="release from f5-cloud-libs https://github.com/F5Networks/f5-cloud-libs/releases"
  default="v4.15.0"
}
variable "masterKey" {
  default= "2018F5Networks!!2018F5Networks!!"
}
variable "regPoolKeys" {
  default= "key-key-key-key"
}
variable "licensePoolKeys" {
  default= "pool-key-key-key"
}
variable "adminPassword" {
  default= "2018F5Networks!!"
}
variable timeZone { default = "UTC" }

variable ntpServer { default = "0.us.pool.ntp.org" }

variable "bigIqLicenseKey1" {
  default= "big-iq-key-key-key"
}

# adminusername
# adminpassword
# masterkey
# dnslabel
# instancename
# instance_type
# bigiqversion
# bigiqlicensekey
# licensepoolkeys
# regpoolkeys
# numberofinternalIps
# vnetname
# vnetresourcegroupname
# mgmtsubnetname
# mgmipaddress
# internalsubnetname
# internalipaddreessrangestart
# avsetchoice
# ntp_server
# timezone
# customimage
# restrictedsrcaddress
# tagvalues
# allowusageanalytics
# resourcegroupname
# region
# azureloginuser
# azureloginpassword


# TAGS
variable purpose { default = "public" }
variable environment { default = "f5env" } #ex. dev/staging/prod
variable owner { default = "f5owner" }
variable group { default = "f5group" }
variable costcenter { default = "f5costcenter" }
variable application { default = "f5app" }
