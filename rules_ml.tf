locals {
  ## LBS 1.6
  ## https://bcp-ti.atlassian.net/wiki/spaces/CTTIIPUB/pages/388249112/LBS+-+Azure+Machine+Learning#3.----Configuraci%C3%B3n-de-Subnet-y-NSG

  map_rules_azml_outbound = [
    {
      ansg_rule_name                  = "AzureMachineLearningTCP"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureMachineLearning"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443", "8787", "18881"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "120"
      ansg_description                = "Conexión con Azure Machine Learning mediante TCP"
    },
    {
      ansg_rule_name                  = "AzureMachineLearningUDP"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureMachineLearning"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["5831"]
      ansg_protocol                   = "Udp"
      ansg_access                     = "Allow"
      ansg_priority                   = "130"
      ansg_description                = "Conexión con Azure Machine Learning mediante UDP"
    },
    {
      ansg_rule_name                  = "BatchNodeManagement"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "BatchNodeManagement"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "140"
      ansg_description                = "Conexión con BatchNodeManagement"
    },
    {
      ansg_rule_name                  = "Storage"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "Storage"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443", "445"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "150"
      ansg_description                = "Conexión con Storage Account"
    },
    {
      ansg_rule_name                  = "AzureActiveDirectory"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureActiveDirectory"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["80", "443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "160"
      ansg_description                = "Conexión con Azure Active Directory (Entra ID)"
    },
    {
      ansg_rule_name                  = "AzureResourceManager"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureResourceManager"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "170"
      ansg_description                = "Conexión con Azure Resource Manager"
    },
    {
      ansg_rule_name                  = "AzureFrontDoor.Frontend"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureFrontDoor.Frontend"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "180"
      ansg_description                = "Conexión con Azure Front Door-FrontEnd"
    },
    {
      ansg_rule_name                  = "MicrosoftContainerRegistry"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "MicrosoftContainerRegistry"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "190"
      ansg_description                = "Conexión con Azure Container Registry"
    },
    {
      ansg_rule_name                  = "AzureFrontDoor.FirstParty"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureFrontDoor.FirstParty"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "200"
      ansg_description                = "Conexión con Azure Front Door-FirstParty"
    },
    {
      ansg_rule_name                  = "AzureMonitor"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureMonitor"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "210"
      ansg_description                = "Conexión con Azure Monitor"
    },
    {
      ansg_rule_name                  = "Keyvault"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "AzureKeyVault"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "220"
      ansg_description                = "Conexión con Azure KeyVault"
    },
    {
      ansg_rule_name                  = "VirtualNetwork"
      ansg_source_address_prefix      = "VirtualNetwork"
      ansg_destination_address_prefix = "VirtualNetwork"
      ansg_source_port_range          = "*"
      ansg_destination_port_ranges    = ["443"]
      ansg_protocol                   = "Tcp"
      ansg_access                     = "Allow"
      ansg_priority                   = "230"
      ansg_description                = "Conexión con redes complementarias (ejem: DNS)"
    }
  ]


  ## si son solo para Machine Learning
  map_subnets_for_azml = {
    for key, value in var.snet_subnet_address : key => value
    if(lookup(value, "with_nsg_azml", false) == true)
  }

  map_outbound_rules_for_azml = flatten([
    for k, v in local.map_subnets_for_azml : [
      for r in local.map_rules_azml_outbound : merge(r, { ansg_subnet_key = k })
    ]
  ])

  map_result_outbound_rules_for_azml = local.map_outbound_rules_for_azml

}

