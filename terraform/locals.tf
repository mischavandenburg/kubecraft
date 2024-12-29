locals {
  vm = {
    name           = "kcVM" # azurerm resource name
    hostname       = "ubuntu-kubecraft"
    location       = "East US" #"northeurope"
    size           = "Standard_B2ms"
    admin_username = "kubecraft"
  }
  key_vault = {
    key_permissions = [
      "Get"
    ]
    secret_permissions = [
      "Get"
    ]
    storage_permissions = [
      "Get"
    ]
  }
}
