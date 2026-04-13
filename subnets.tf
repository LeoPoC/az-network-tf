# -----------------------------------------------------------------------------
# App Subnet
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "app" {
  name                 = var.app_subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.app_subnet_prefix]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# -----------------------------------------------------------------------------
# Database Subnet
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "database" {
  name                 = var.db_subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.db_subnet_prefix]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]

  delegation {
    name = "fs-delegation"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# -----------------------------------------------------------------------------
# Private Endpoint Subnet
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "private_endpoint" {
  name                              = var.pe_subnet_name
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [var.pe_subnet_prefix]
  private_endpoint_network_policies = "Enabled"
}

# -----------------------------------------------------------------------------
# NSG Associations
# -----------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint" {
  subnet_id                 = azurerm_subnet.private_endpoint.id
  network_security_group_id = azurerm_network_security_group.private_endpoint.id
}
