variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = null
}

variable "app_subnet_name" {
  description = "Name of the application subnet"
  type        = string
}

variable "app_subnet_prefix" {
  description = "Address prefix for the application subnet"
  type        = string
}

variable "db_subnet_name" {
  description = "Name of the database subnet"
  type        = string
}

variable "db_subnet_prefix" {
  description = "Address prefix for the database subnet"
  type        = string
}

variable "pe_subnet_name" {
  description = "Name of the private endpoint subnet"
  type        = string
}

variable "pe_subnet_prefix" {
  description = "Address prefix for the private endpoint subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
