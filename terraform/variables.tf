variable "bigIqLicenseKey1" {
  description = "big-iq-key-key-key-byol"
}
variable "subscriptionID" {
  default= "Azure-subscriptionID"
}
variable "adminAccountName" {
  description = "BIG-IQ admin account name ex: xadmin"
}

variable "adminAccountPassword" {
  description = "BIG-IQ admin account password"
}

variable "adminSourceRange" {
    description = "network or address with CIDR where admin traffic will source from ex: 192.168.2.0/24"
  
}
