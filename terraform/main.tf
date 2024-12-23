# Create Resource Group
resource "azurerm_resource_group" "rg" {
  location = local.vm.location
  name     = "vm-resource_group"
}

# Create virtual network
resource "azurerm_virtual_network" "kc_terraform_network" {
  name                = "kcVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "kc_terraform_subnet" {
  name                 = "kcSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.kc_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "kc_terraform_public_ip" {
  name                = "kcPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "kc_terraform_nsg" {
  name                = "kcNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "kc_terraform_nic" {
  name                = "kcNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "kc_nic_configuration"
    subnet_id                     = azurerm_subnet.kc_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.kc_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.kc_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.kc_terraform_nsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "kc_terraform_vm" {
  name                  = local.vm.name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.kc_terraform_nic.id]
  size                  = local.vm.size

  os_disk {
    name                 = "kcOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "hostname"
  admin_username = local.vm.admin_username

  admin_ssh_key {
    username   = local.vm.admin_username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }
}
