resource_group_name = "rg-network-demo"
location            = "eastus"

vnet_name          = "vnet-main"
vnet_address_space = ["10.0.0.0/16"]

app_subnet_name   = "snet-app"
app_subnet_prefix = "10.0.1.0/24"

db_subnet_name   = "snet-database"
db_subnet_prefix = "10.0.2.0/24"

pe_subnet_name   = "snet-private-endpoint"
pe_subnet_prefix = "10.0.3.0/24"

tags = {
  Environment = "dev"
  Project     = "network-infra"
  ManagedBy   = "terraform"
}
