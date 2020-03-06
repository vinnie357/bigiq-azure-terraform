
# Create a Resource Group for the new Virtual Machine
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}rg${var.buildSuffix}"
  location = "${var.location}"
}

# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}network${var.buildSuffix}"
  address_space       = ["${var.cidr}"]
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
}

# Create the Management Subnet within the Virtual Network
resource "azurerm_subnet" "mgmt" {
  name                 = "${var.prefix}mgmt${var.buildSuffix}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet1"]}"
}

# Create the External Subnet within the Virtual Network
resource "azurerm_subnet" "External" {
  name                 = "${var.prefix}External${var.buildSuffix}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet2"]}"
}

# Create the Internal Subnet within the Virtual Network
resource "azurerm_subnet" "Internal" {
  name                 = "${var.prefix}Internal${var.buildSuffix}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet3"]}"
}

# Obtain Gateway IP for each Subnet
locals {
  depends_on = ["azurerm_subnet.mgmt", "azurerm_subnet.External"]
  mgmt_gw    = "${cidrhost(azurerm_subnet.mgmt.address_prefix, 1)}"
  ext_gw     = "${cidrhost(azurerm_subnet.External.address_prefix, 1)}"
  int_gw     = "${cidrhost(azurerm_subnet.Internal.address_prefix, 1)}"
}

# Create a Public IP for the Virtual Machines
resource "azurerm_public_ip" "lbpip" {
  name                         = "${var.prefix}lb-pip${var.buildSuffix}"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Dynamic"
  domain_name_label            = "${var.prefix}lbpip"
}

# Create Availability Set
resource "azurerm_availability_set" "avset" {
  name                         = "${var.prefix}avset${var.buildSuffix}"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create Azure LB
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}lb${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.lbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "${var.prefix}BackendPool1${var.buildSuffix}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "${var.prefix}tcpProbe${var.buildSuffix}"
  protocol            = "tcp"
  port                = 443
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "https_rule" {
  name                           = "${var.prefix}HTTPRule${var.buildSuffix}"
  resource_group_name            = "${azurerm_resource_group.main.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
}

resource "azurerm_lb_rule" "ssh_rule" {
  name                           = "${var.prefix}SSHRule${var.buildSuffix}"
  resource_group_name            = "${azurerm_resource_group.main.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  protocol                       = "tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
}

# Create a Network Security Group with some rules
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}nsg${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  # https://support.f5.com/csp/article/K15612
security_rule {
    name                       = "allow_admin_SSH"
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.adminSourceRange}"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_admin_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "${var.adminSourceRange}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow_mgmt_SSH"
    description                = "Allow SSH access"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_mgmt_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_DCD"
    description                = "Allow DCD access"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9300"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_MONGO"
    description                = "Allow MongoDb access"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  #bigiq 7
  security_rule {
    name                       = "allow_corosync_UDP"
    description                = "Allow corosync access"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "5404"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  #bigiq 7
  security_rule {
    name                       = "allow_corosync2_UDP"
    description                = "Allow corosync2 access"
    priority                   = 107
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "5405"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  #bigiq 7
  security_rule {
    name                       = "allow_pacemaker_UDP"
    description                = "Allow pacemaker access"
    priority                   = 108
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "2224"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  # bigiq 6
  security_rule {
    name                       = "allow_api_TCP"
    description                = "Allow api access"
    priority                   = 109
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "28015"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  # bigiq 6
  security_rule {
    name                       = "allow_api2_TCP"
    description                = "Allow api2 access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "29015"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Name           = "${var.environment}-bigip-sg"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Create a Public IP for the Virtual Machines
resource "azurerm_public_ip" "f5vmpip01" {
  name                = "${var.prefix}vm01-mgmt-pip01${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Dynamic"

  tags = {
    Name = "${var.prefix}-f5vm-public-ip"
  }
}
resource "azurerm_public_ip" "f5vmpip02" {
  name                = "${var.prefix}vm02-mgmt-pip02${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Dynamic"

  tags = {
    Name = "${var.prefix}-f5vm-public-ip"
  }
}

# Create the first network interface card for Management 
resource "azurerm_network_interface" "vm01-mgmt-nic" {
  name                      = "${var.prefix}vm01-mgmt-nic${var.buildSuffix}"
  location                  = "${azurerm_resource_group.main.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.mgmt.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01mgmt}"
    public_ip_address_id          = "${azurerm_public_ip.f5vmpip01.id}"
  }

  tags = {
    Name           = "${var.environment}-vm01-mgmt-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_network_interface" "vm02-mgmt-nic" {
  name                      = "${var.prefix}vm02-mgmt-nic${var.buildSuffix}"
  location                  = "${azurerm_resource_group.main.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.mgmt.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02mgmt}"
    public_ip_address_id          = "${azurerm_public_ip.f5vmpip02.id}"
  }

  tags = {
    Name           = "${var.environment}-vm02-mgmt-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Create the second network interface card for External
resource "azurerm_network_interface" "vm01-ext-nic" {
  name                = "${var.prefix}vm01-ext-nic${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool"]
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01ext}"
    primary			  = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01ext_sec}"
  }

  tags = {
    Name           = "${var.environment}-vm01-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
    f5_cloud_failover_label = "saca"
    f5_cloud_failover_nic_map = "external"
  }
}

resource "azurerm_network_interface" "vm02-ext-nic" {
  name                = "${var.prefix}vm02-ext-nic${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool"]
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02ext}"
    primary			  = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02ext_sec}"
  }

  tags = {
    Name           = "${var.environment}-vm01-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
    f5_cloud_failover_label = "saca"
    f5_cloud_failover_nic_map = "external"
  }
}

# resource "azurerm_network_interface" "backend01-ext-nic" {
#   name                = "${var.prefix}-backend01-ext-nic${var.buildSuffix}"
#   location            = "${azurerm_resource_group.main.location}"
#   resource_group_name = "${azurerm_resource_group.main.name}"
#   network_security_group_id = "${azurerm_network_security_group.main.id}"

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = "${azurerm_subnet.External.id}"
#     private_ip_address_allocation = "Static"
#     private_ip_address            = "${var.backend01ext}"
#     primary			  = true
#   }

#   tags = {
#     Name           = "${var.environment}-backend01-ext-int"
#     environment    = "${var.environment}"
#     owner          = "${var.owner}"
#     group          = "${var.group}"
#     costcenter     = "${var.costcenter}"
#     application    = "app1"
#   }
# }

# Create the third network interface card for Internal
resource "azurerm_network_interface" "vm01-int-nic" {
  name                = "${var.prefix}vm01-int-nic${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
  #depends_on          = ["azurerm_lb_backend_address_pool.backend_pool"]
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.Internal.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01int}"
    primary			  = true
  }

  tags = {
    Name           = "${var.environment}-vm01-int-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_network_interface" "vm02-int-nic" {
  name                = "${var.prefix}vm02-int-nic${var.buildSuffix}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
  #depends_on          = ["azurerm_lb_backend_address_pool.backend_pool"]
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.Internal.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02int}"
    primary			  = true
  }

  tags = {
    Name           = "${var.environment}-vm02-int-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Associate the Network Interface to the BackendPool
resource "azurerm_network_interface_backend_address_pool_association" "bpool_assc_vm01" {
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool", "azurerm_network_interface.vm01-ext-nic"]
  network_interface_id    = "${azurerm_network_interface.vm01-ext-nic.id}"
  ip_configuration_name   = "secondary"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "bpool_assc_vm02" {
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool", "azurerm_network_interface.vm02-ext-nic"]
  network_interface_id    = "${azurerm_network_interface.vm02-ext-nic.id}"
  ip_configuration_name   = "secondary"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
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
# onboard-debug
resource "local_file" "onboard_debug" {
  content     = "${data.template_file.vm_onboard.rendered}"
  filename    = "${path.module}/onboard-debug.sh"
}

# Create F5 BIGIQ VMs
resource "azurerm_virtual_machine" "f5vm01" {
  name                         = "${var.prefix}f5vm01${var.buildSuffix}"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm01-mgmt-nic.id}"
#   network_interface_ids        = ["${azurerm_network_interface.vm01-mgmt-nic.id}", "${azurerm_network_interface.vm01-ext-nic.id}", "${azurerm_network_interface.vm01-int-nic.id}"]
  network_interface_ids        = ["${azurerm_network_interface.vm01-mgmt-nic.id}", "${azurerm_network_interface.vm01-int-nic.id}"]
  vm_size                      = "${var.instance_type}"
  availability_set_id          = "${azurerm_availability_set.avset.id}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "f5-networks"
    offer     = "${var.product}"
    sku       = "${var.image_name}"
    version   = "${var.bigip_version}"
  }

  storage_os_disk {
    name              = "${var.prefix}vm01-osdisk${var.buildSuffix}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}vm01"
    admin_username = "${var.uname}"
    admin_password = "${var.upassword}"
    custom_data    = "${data.template_file.vm_onboard.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name          = "${var.image_name}"
    publisher     = "f5-networks"
    product       = "${var.product}"
  }

  tags = {
    Name           = "${var.environment}-f5vm01"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
#     provisioner "local-exec" {
#     # revoke license for byol
#     when    = "destroy"
#     interpreter = ["/bin/bash", "-c"]
#     command = <<-EOF
#     https://{{HOST}}/mgmt/tm/util/bash
#     POST
#       {
# 	    "command": "run",
# 	    "utilCmdArgs": "-c \'tmsh create cli transaction;tmsh modify cli preference pager disabled display-threshold 0; tmsh revoke sys license;tmsh submit cli transaction\'"
#       }
#     EOF
#   }
}

# resource "azurerm_virtual_machine" "f5vm02" {
#   name                         = "${var.prefix}f5vm02${var.buildSuffix}"
#   location                     = "${azurerm_resource_group.main.location}"
#   resource_group_name          = "${azurerm_resource_group.main.name}"
#   primary_network_interface_id = "${azurerm_network_interface.vm02-mgmt-nic.id}"
#   network_interface_ids        = ["${azurerm_network_interface.vm02-mgmt-nic.id}", "${azurerm_network_interface.vm02-ext-nic.id}", "${azurerm_network_interface.vm02-int-nic.id}"]
#   vm_size                      = "${var.instance_type}"
#   availability_set_id          = "${azurerm_availability_set.avset.id}"

#   # Uncomment this line to delete the OS disk automatically when deleting the VM
#   delete_os_disk_on_termination = true


#   # Uncomment this line to delete the data disks automatically when deleting the VM
#   delete_data_disks_on_termination = true

#   storage_image_reference {
#     publisher = "f5-networks"
#     offer     = "${var.product}"
#     sku       = "${var.image_name}"
#     version   = "${var.bigip_version}"
#   }

#   storage_os_disk {
#     name              = "${var.prefix}vm02-osdisk${var.buildSuffix}"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }

#   os_profile {
#     computer_name  = "${var.prefix}vm02"
#     admin_username = "${var.uname}"
#     admin_password = "${var.upassword}"
#     custom_data    = "${data.template_file.vm_onboard.rendered}"
# }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }

#   plan {
#     name          = "${var.image_name}"
#     publisher     = "f5-networks"
#     product       = "${var.product}"
#   }

#   tags = {
#     Name           = "${var.environment}-f5vm02"
#     environment    = "${var.environment}"
#     owner          = "${var.owner}"
#     group          = "${var.group}"
#     costcenter     = "${var.costcenter}"
#     application    = "${var.application}"
#   }
# }

# # backend VM
# resource "azurerm_virtual_machine" "backendvm" {
#     name                  = "backendvm"
#     location                     = "${azurerm_resource_group.main.location}"
#     resource_group_name          = "${azurerm_resource_group.main.name}"

#     network_interface_ids = ["${azurerm_network_interface.backend01-ext-nic.id}"]
#     vm_size               = "Standard_DS1_v2"

#     storage_os_disk {
#         name              = "backendOsDisk"
#         caching           = "ReadWrite"
#         create_option     = "FromImage"
#         managed_disk_type = "Premium_LRS"
#     }

#     storage_image_reference {
#         publisher = "Canonical"
#         offer     = "UbuntuServer"
#         sku       = "16.04.0-LTS"
#         version   = "latest"
#     }

#     os_profile {
#         computer_name  = "backend01"
#         admin_username = "${var.uname}"
#         admin_password = "${var.upassword}"
#         custom_data = <<-EOF
#               #!/bin/bash
#               apt-get update -y
#               apt-get install -y docker.io
#               docker run -d -p 80:80 --net=host --restart unless-stopped -e F5DEMO_APP=website -e F5DEMO_NODENAME='F5 Azure' -e F5DEMO_COLOR=ffd734 -e F5DEMO_NODENAME_SSL='F5 Azure (SSL)' -e F5DEMO_COLOR_SSL=a0bf37 chen23/f5-demo-app:ssl
#               EOF
#     }

#     os_profile_linux_config {
#         disable_password_authentication = false
#     }

#   tags = {
#     Name           = "${var.environment}-backend01"
#     environment    = "${var.environment}"
#     owner          = "${var.owner}"
#     group          = "${var.group}"
#     costcenter     = "${var.costcenter}"
#     application    = "${var.application}"
#   }
# }


# Run Startup Script
resource "azurerm_virtual_machine_extension" "f5vm01-run-startup-cmd" {
  name                 = "${var.environment}f5vm01-run-startup-cmd${var.buildSuffix}"
#   depends_on           = ["azurerm_virtual_machine.f5vm01", "azurerm_virtual_machine.backendvm"]
  depends_on           = ["azurerm_virtual_machine.f5vm01"]
  location             = "${var.region}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm01.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "mkdir -p /var/log/cloud/azure;mkdir -p /config/cloud;cat /var/lib/waagent/CustomData > /config/cloud/init.sh; chmod +x /config/cloud/init.sh;bash /config/cloud/init.sh  &>> /var/log/cloud/azure/install.log"
    }
  SETTINGS

  tags = {
    Name           = "${var.environment}-f5vm01-startup-cmd"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# resource "azurerm_virtual_machine_extension" "f5vm02-run-startup-cmd" {
#   name                 = "${var.environment}-f5vm02-run-startup-cmd${var.buildSuffix}"
#   depends_on           = ["azurerm_virtual_machine.f5vm02", "azurerm_virtual_machine.backendvm"]
#   location             = "${var.region}"
#   resource_group_name  = "${azurerm_resource_group.main.name}"
#   virtual_machine_name = "${azurerm_virtual_machine.f5vm02.name}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "bash /var/lib/waagent/CustomData 2"
#     }
#   SETTINGS

#   tags = {
#     Name           = "${var.environment}-f5vm02-startup-cmd"
#     environment    = "${var.environment}"
#     owner          = "${var.owner}"
#     group          = "${var.group}"
#     costcenter     = "${var.costcenter}"
#     application    = "${var.application}"
#   }
# }


resource "null_resource" "wait" {
   #https://ilhicas.com/2019/08/17/Terraform-local-exec-run-always.html
   triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOF
        checks=0
        while [[ "$checks" -lt 4 ]]; do
            echo "waiting on: https://${azurerm_public_ip.f5vmpip01.ip_address}"  
            curl -sk --retry 15 --retry-connrefused --retry-delay 10 https://${azurerm_public_ip.f5vmpip01.ip_address}
        if [ $? == 0 ]; then
            echo "mgmt ready"
            break
        fi
        echo "mgmt not ready yet"
        let checks=checks+1
        sleep 10
        done
    EOF
    interpreter = ["bash", "-c"]
  }
}