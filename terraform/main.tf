# Configure the Microsoft Azure Provider, replace Service Principal and Subscription with your own
provider "azurerm" {
  version = "=1.38.0"
}
# Deploy BIGIQ Module
module "bigiq" {
  source   = "./bigiq"
  bigIqLicenseKey1 = "${var.bigIqLicenseKey1}"
  subscriptionID = "${var.subscriptionID}"
  upassword      = "${var.adminAccountPassword}"
  uname         = "${var.adminAccountName}"
  adminSourceRange = "${var.adminSourceRange}"
  buildSuffix = "-${random_pet.buildSuffix.id}"
  prefix = "${var.projectPrefix}"
}


resource "random_pet" "buildSuffix" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    #ami_id = "${var.ami_id}"
    prefix = "${var.projectPrefix}"
  }
  #length = ""
  #prefix = "${var.projectPrefix}"
  separator = "-"
}