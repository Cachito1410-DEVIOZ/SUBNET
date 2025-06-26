locals {
  map_rules_privend_inbound = [
    {
      ansg_rule_name                  = "DenyAnyCustomAnyInbound"
      ansg_source_address_prefix      = "*"
      ansg_destination_address_prefix = "*"
      ansg_source_port_range          = "*"
      ansg_destination_port_range     = "*"
      ansg_protocol                   = "*"
      ansg_access                     = "Deny"
      ansg_priority                   = "1000"
      ansg_description                = "Bloqueo de conexiones de entrada por default."
    },
  ]


  ## si son solo para Private Endpoint
  map_subnets_for_privend = {
    for key, value in var.snet_subnet_address : key => value
    if(lookup(value, "with_nsg_privend", false) == true)
  }

  tmp_rules_inbound_privend_subnet = [
    for key, value in local.map_subnets_for_privend :
    {
      ansg_rule_name                    = "RuleAllowInIntSubnet"
      ansg_source_address_prefixes      = value.snet_prefix # address subnet
      ansg_destination_address_prefixes = value.snet_prefix # address subnet
      ansg_source_port_range            = "*"
      ansg_destination_port_range       = "*"
      ansg_protocol                     = "*"
      ansg_access                       = "Allow"
      ansg_priority                     = "100"
      ansg_description                  = "Comunicación de servicios dentro una misma subnet. En address range subnet va el segmento de la subnet asignada del Private Endpoint."
      ansg_subnet_key                   = key
    }
  ]

  tmp_map_inbound_rules_for_privend = flatten([
    for k, v in local.map_subnets_for_privend : [
      for r in local.map_rules_privend_inbound : merge(r, { ansg_subnet_key = k })
    ]
  ])


  map_result_inbound_rules_for_privend = concat(
    local.tmp_map_inbound_rules_for_privend,
    local.tmp_rules_inbound_privend_subnet,
  )


}
