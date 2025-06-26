resource "azurerm_subnet" "subnet" {
  for_each             = { for key, value in var.snet_subnet_address : key => value }
  name                 = format("%s%s%s%s", local.subnet_name, each.value.snet_srv_code, var.globals.env_code, each.value.resource_sequential)
  address_prefixes     = each.value.snet_prefix
  resource_group_name  = local.rsgr
  virtual_network_name = local.vnet_name
  service_endpoints    = try(each.value.service_endpoints_sub, null)

  dynamic "delegation" {
    for_each = [{ "delegation" = each.value.delegation_name }, {}][(try(each.value.delegation_name, null) != null) ? 0 : 1]
    content {
      name = format("%s%s%s%s%s%s", local.dele_code, each.key, local.subnet_name, each.value.snet_srv_code, var.globals.env_code, each.value.resource_sequential)
      service_delegation {
        name = each.value.delegation_name
      }
    }
  }

  private_endpoint_network_policies = coalesce(each.value.enable_privend_netpol, false) ? "Enabled" : "Disabled"

  lifecycle {
    precondition {
      condition = (
        (try(each.value.delegation_name, null) != null) && contains(local.delegation_names, try(each.value.delegation_name, null) == null ? "" : each.value.delegation_name)
        ) || (
        try(each.value.delegation_name, null) == null
      )
      error_message = format("El valor del nombre del delegation ingresado no es valido. Los valores permitidos son: %s", join(", ", local.delegation_names))
    }

    ignore_changes = [delegation]
  }
}

resource "azurerm_network_security_group" "ansg" {
  for_each            = local.map_nsg_created
  name                = format("%s%s%s%s", local.ansg_name, each.value.snet_srv_code, var.globals.env_code, each.value.resource_sequential)
  location            = local.location_region
  resource_group_name = local.rsgr
  tags                = merge(var.tags, local.tags)

  dynamic "security_rule" {
    for_each = { for value in flatten(values(local.map_result_rules_inbound)) : "${value["ansg_subnet_key"]}_${value["ansg_rule_name"]}" => value if(length(value) > 0) && value["ansg_subnet_key"] == each.key }
    content {
      name                         = security_rule.value["ansg_rule_name"]
      description                  = security_rule.value["ansg_description"]
      priority                     = security_rule.value["ansg_priority"]
      direction                    = "Inbound"
      access                       = security_rule.value["ansg_access"]
      protocol                     = security_rule.value["ansg_protocol"]
      source_port_range            = try(security_rule.value["ansg_source_port_range"], null)
      source_port_ranges           = try(security_rule.value["ansg_source_port_ranges"], null)
      destination_port_range       = try(security_rule.value["ansg_destination_port_range"], null)
      destination_port_ranges      = try(security_rule.value["ansg_destination_port_ranges"], null)
      source_address_prefix        = try(security_rule.value["ansg_source_address_prefix"], null)
      source_address_prefixes      = try(security_rule.value["ansg_source_address_prefixes"], null)
      destination_address_prefix   = try(security_rule.value["ansg_destination_address_prefix"], null)
      destination_address_prefixes = try(security_rule.value["ansg_destination_address_prefixes"], null)
    }
  }

  dynamic "security_rule" {
    for_each = { for value in flatten(values(local.map_result_rules_outbound)) : "${value["ansg_subnet_key"]}_${value["ansg_rule_name"]}" => value if(length(value) > 0) && value["ansg_subnet_key"] == each.key }
    content {
      name                         = security_rule.value["ansg_rule_name"]
      description                  = security_rule.value["ansg_description"]
      priority                     = security_rule.value["ansg_priority"]
      direction                    = "Outbound"
      access                       = security_rule.value["ansg_access"]
      protocol                     = security_rule.value["ansg_protocol"]
      source_port_range            = try(security_rule.value["ansg_source_port_range"], null)
      source_port_ranges           = try(security_rule.value["ansg_source_port_ranges"], null)
      destination_port_range       = try(security_rule.value["ansg_destination_port_range"], null)
      destination_port_ranges      = try(security_rule.value["ansg_destination_port_ranges"], null)
      source_address_prefix        = try(security_rule.value["ansg_source_address_prefix"], null)
      source_address_prefixes      = try(security_rule.value["ansg_source_address_prefixes"], null)
      destination_address_prefix   = try(security_rule.value["ansg_destination_address_prefix"], null)
      destination_address_prefixes = try(security_rule.value["ansg_destination_address_prefixes"], null)
    }
  }


  lifecycle {
    ignore_changes = [security_rule]
  }
}

# Asociar por default cuando se crea una subnet
resource "azurerm_subnet_network_security_group_association" "ansg" {
  for_each                  = local.map_nsg_created
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.ansg[each.key].id
}

# Cuando se requiera asociar una subnet existente
resource "azurerm_subnet_network_security_group_association" "snet_ansg" {
  for_each                  = local.map_nsg_existing
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = data.azurerm_network_security_group.apgw[each.key].id
}

resource "azurerm_monitor_diagnostic_setting" "diagset_for_nsg_exist" {
  for_each                   = local.map_nsg_existing
  name                       = format("%s%s", each.value["ansg_name_association"], "_lgan_infr")
  target_resource_id         = data.azurerm_network_security_group.apgw[each.key].id
  log_analytics_workspace_id = var.lgan_infr_id[local.map_locations_code[var.location_code]]

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }

  lifecycle {
    ignore_changes = [enabled_log, metric]
  }

  depends_on = [
    data.azurerm_network_security_group.apgw,
    azurerm_subnet_network_security_group_association.snet_ansg
  ]
}

resource "azurerm_monitor_diagnostic_setting" "diagset_for_nsg_to_create" {
  for_each                   = local.map_nsg_created
  name                       = format("%s%s%s%s%s", local.ansg_name, each.value["snet_srv_code"], var.globals.env_code, each.value["resource_sequential"], "_lgan_infr")
  target_resource_id         = azurerm_network_security_group.ansg[each.key].id
  log_analytics_workspace_id = var.lgan_infr_id[local.map_locations_code[var.location_code]]

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }

  lifecycle {
    ignore_changes = [enabled_log, metric]
  }

  depends_on = [
    azurerm_network_security_group.ansg,
    azurerm_subnet_network_security_group_association.ansg
  ]
}
