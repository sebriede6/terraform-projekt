terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    # Füge azurerm hinzu, wenn nicht schon vorhanden für andere Zwecke
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0" # oder eine aktuellere, passende Version
    }
  }
}