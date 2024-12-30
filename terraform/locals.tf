locals {
  vm = {
    name           = "kcVM" # azurerm resource name
    hostname       = "ubuntu-kubecraft"
    location       = "northeurope"
    size           = "Standard_B2ms"
    admin_username = "kubecraft"
  }
  key_vault = {
    eso_secret_permissions = [
      "Get",
      "List"
    ]
    admin_secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
    # Placeholder for the external secrets operator identifier
    # eso_object_id = ""
  }
}
