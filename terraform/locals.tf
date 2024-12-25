locals {
  vm = {
    name           = "kcVM" # azurerm resource name
    hostname       = "ubuntu-kubecraft"
    location       = "northeurope"
    size           = "Standard_B2ms"
    admin_username = "kubecraft"
  }
}
