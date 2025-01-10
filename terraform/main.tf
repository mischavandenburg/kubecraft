# Create Resource Group
resource "azurerm_resource_group" "rg" {
  location = local.vm.location
  name     = "kcUbuntuResourceGroup"
}

# Create randomized name for key vault, each key vault must have globally unique ID
resource "random_string" "azurerm_key_vault_name" {
  length  = 13
  lower   = true
  numeric = false
  special = false
  upper   = false
}

# Hold client identifying information for privilege & access control
data "azurerm_client_config" "current" {}

# Create key vault
resource "azurerm_key_vault" "vault" {
  name                       = "kcVault-${random_string.azurerm_key_vault_name.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  # Policies for the external secrets operator
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id # Remove this line and uncomment the next once ESO id is stored in local
    #object_id = local.key_vault.eso_object_id

    secret_permissions = local.key_vault.eso_secret_permissions
  }

  # Policies for the 'control panel' applying our Terraform configs
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = local.key_vault.admin_secret_permissions
  }
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
resource "azurerm_network_interface_security_group_association" "kc_terraform_associate" {
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

  computer_name  = local.vm.hostname
  admin_username = local.vm.admin_username

  admin_ssh_key {
    username   = local.vm.admin_username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }


  admin_ssh_key {
    username   = local.vm.admin_username
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7cKlVWUh8/PPsU4pSKjXucEEVDp99JG+EMUy7vf1CTCQoJ54OJ0ShFFPv5ddyDuZ4wVN04UlVXIna25TgDu3F1VpedzT+W7uqB+Evyz+lqtj/m57eLewjzB1w670OgNNE3XjgBG3FRqysyIOq+nG8X2LITVJVprrx7NoOwOZSGu92+8UQ4f0IyMcvvpFgzp+86zaHQ220fasEn8GZ/by2o94BV0Frk98RvnI9/woEQg/zavkQqERqSWl3VLzXNe2kJlcGG613fGZrbtsH2i3UV4yMOxFa1MInzlh4io6FmI9ic3YLJ8L+9BWxN9IdA0mE5N21SpWG9elWp/MmN8vzQvdqKJmKnjZfeLDpNXB9PTKsJ1hkch2ssb/OrfJ5dTIJNQZixL+f1ZumDzfAQXBMaMj8h+oCuiwfyVY9br8JSJeEM7AWVNavmRWdmv/o8XccGn0d2xqEwzBT4GOM/iKR45tI1xMckbfwS8R04OfxVWPB3qsffUwXN4i+wUVox5K1+qSjTcuXiLgdaXDwNaOshzi/iEK9y34StxJ8OxUL8eEuuU2xC49hfP7qqPqWefxqEVBzalpzG5GcokWFF0lmDX5WXj6dF1hKV31p1MglPyVi00RESWbHTAIWc/x5pPUX02tZ9FeFRXSTAAEce0E1WiSu+tbI0+ftUesjizhJIQ== cardno:23_421_713"
  }


}
