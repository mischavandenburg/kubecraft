locals {
  vm = {
    name           = "kcVM" # azurerm resource name
    hostname       = "ubuntu-kubecraft"
    location       = "East US" #"northeurope"
    size           = "Standard_B2ms"
    admin_username = "kubecraft"
  }
  key_vault = {
    secret_permissions = [
      "Get"
    ]
  }
}
