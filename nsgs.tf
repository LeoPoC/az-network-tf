# -----------------------------------------------------------------------------
# NSG – App Subnet
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.app_subnet_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # Allow HTTPS inbound
  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP inbound
  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow app subnet to talk to database subnet
  security_rule {
    name                       = "Allow-App-To-DB-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5432", "1433", "3306"]
    source_address_prefix      = var.app_subnet_prefix
    destination_address_prefix = var.db_subnet_prefix
  }

  # Allow outbound to private endpoint subnet
  security_rule {
    name                       = "Allow-App-To-PE-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.app_subnet_prefix
    destination_address_prefix = var.pe_subnet_prefix
  }

  # Deny all other inbound
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -----------------------------------------------------------------------------
# NSG – Database Subnet
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "database" {
  name                = "nsg-${var.db_subnet_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # Allow inbound from app subnet on DB ports
  security_rule {
    name                       = "Allow-App-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5432", "1433", "3306"]
    source_address_prefix      = var.app_subnet_prefix
    destination_address_prefix = var.db_subnet_prefix
  }

  # Deny all other inbound
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny direct internet outbound from DB subnet
  security_rule {
    name                       = "Deny-Internet-Outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# -----------------------------------------------------------------------------
# NSG – Private Endpoint Subnet
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "private_endpoint" {
  name                = "nsg-${var.pe_subnet_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # Allow inbound from VNet only
  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Deny all other inbound
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny internet outbound
  security_rule {
    name                       = "Deny-Internet-Outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}
