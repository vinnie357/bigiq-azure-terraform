# debug Onboarding scripts
data "template_file" "vm_onboard_debug" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname        	      = "${var.uname}"
    upassword        	  = "${var.upassword}"
    onboard_log		      = "${var.onboard_log}"
    bigIqLicenseKey1      = "${var.bigIqLicenseKey1}"
    ntpServer             = "${var.ntpServer}"
    timeZone              = "${var.timeZone}"
    licensePoolKeys       = "${var.licensePoolKeys}"
    regPoolKeys           = "${var.regPoolKeys}"
    adminPassword         = "${var.adminPassword}"
    masterKey             = "${var.masterKey}"
    f5CloudLibsTag        = "${var.f5CloudLibsTag}"
    f5CloudLibsAzureTag   = "${var.f5CloudLibsAzureTag}"
    intSubnetPrivateAddress = "${var.intSubnetPrivateAddress}"
    allowUsageAnalytics   = "${var.allowUsageAnalytics}"
    location              = "${var.location}"
    subscriptionID        = "${var.subscriptionID}"
    deploymentId          =  "${var.deploymentId}"
    hostName1           =  "${var.host1_name}.example.com"
    hostName2              = "${var.host2_name}.example.com"
    discoveryAddressSelfip = "${var.f5vm01ext}/24"
    discoveryAddress      = "${var.f5vm01ext}"
    dnsSearchDomains       = "${var.dns_search_domains}"
    dnsServers              = "${var.dns_servers}"
  }
}

resource "local_file" "onboard_file" {
  content     = "${data.template_file.vm_onboard_debug.rendered}"
  filename    = "${path.module}/onboard-debug-bash.sh"
}