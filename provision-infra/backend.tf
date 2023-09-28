terraform {
    backend "azurerm" {
        resource_group_name  = "XXXX"
        storage_account_name = "XXXXX"
        container_name       = "XXXXXXX"
        key                  = "terraform.tfstate"  #no need to change if you dont change the tfstate file name
        storage_account_access_key = data.azurerm_storage_account.storage_account.primary_access_key
    }
}