terraform {
  backend "azurerm" {
    resource_group_name  = "rg-24-08-on-riede-zwatz-sebastian"
    storage_account_name = "tfstateriedese15d90037" 
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate" # Pfad zur State-Datei im Container
  }
}