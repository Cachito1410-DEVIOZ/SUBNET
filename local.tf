locals {

  map_locations_code = {
    eu2 = "eastus2"
    cu1 = "centralus"
  }

  tags = {
    codApp         = upper(var.globals.app_code)
    environment    = upper(var.globals.env_name)
    lbsVersion     = "1.3"
    moduleVersion  = file("${path.module}/version")
    provisioned_by = upper(var.globals.provisioned_by)
  }

  snet_code       = "snet"
  ansg_code       = "ansg"
  rsgr_code       = "rsgr"
  dele_code       = "dlgt"
  vnet_name       = var.vnet_name[local.map_locations_code[var.location_code]]
  location_region = local.map_locations_code[lower(var.location_code)]
  rsgr            = length(var.snet_vnet_rg_name) == 0 ? upper(format("%s%s%s%s%s", local.rsgr_code, var.location_code, var.globals.app_code, var.globals.env_code, var.globals.rsgr_sequential)) : upper(var.snet_vnet_rg_name[local.map_locations_code[var.location_code]])
  subnet_name     = lower(format("%s%s%s", local.snet_code, var.location_code, var.globals.app_code))
  ansg_name       = lower(format("%s%s%s", local.ansg_code, var.location_code, var.globals.app_code))

  list_subnets = [for value in var.snet_subnet_address : value]
  map_nsg_existing = {
    for key, value in var.snet_subnet_address : key => merge(value, { ansg_subnet_key = key })
    if(lookup(value, "ansg_name_association", null) != null)
  }
  map_nsg_created = {
    for key, value in var.snet_subnet_address : key => merge(value, { ansg_subnet_key = key })
    if(lookup(value, "ansg_name_association", null) == null)
  }

  delegation_names = [
    "GitHub.Network/networkSettings",
    "Microsoft.ApiManagement/service",
    "Microsoft.Apollo/npu",
    "Microsoft.App/environments",
    "Microsoft.App/testClients",
    "Microsoft.AVS/PrivateClouds",
    "Microsoft.AzureCosmosDB/clusters",
    "Microsoft.BareMetal/AzureHostedService",
    "Microsoft.BareMetal/AzureHPC",
    "Microsoft.BareMetal/AzurePaymentHSM",
    "Microsoft.BareMetal/AzureVMware",
    "Microsoft.BareMetal/CrayServers",
    "Microsoft.BareMetal/MonitoringServers",
    "Microsoft.Batch/batchAccounts",
    "Microsoft.CloudTest/hostedpools",
    "Microsoft.CloudTest/images",
    "Microsoft.CloudTest/pools",
    "Microsoft.Codespaces/plans",
    "Microsoft.ContainerInstance/containerGroups",
    "Microsoft.ContainerService/managedClusters",
    "Microsoft.ContainerService/TestClients",
    "Microsoft.Databricks/workspaces",
    "Microsoft.DBforMySQL/flexibleServers",
    "Microsoft.DBforMySQL/servers",
    "Microsoft.DBforMySQL/serversv2",
    "Microsoft.DBforPostgreSQL/flexibleServers",
    "Microsoft.DBforPostgreSQL/serversv2",
    "Microsoft.DBforPostgreSQL/singleServers",
    "Microsoft.DelegatedNetwork/controller",
    "Microsoft.DevCenter/networkConnection",
    "Microsoft.DevOpsInfrastructure/pools",
    "Microsoft.DocumentDB/cassandraClusters",
    "Microsoft.Fidalgo/networkSettings",
    "Microsoft.HardwareSecurityModules/dedicatedHSMs",
    "Microsoft.Kusto/clusters",
    "Microsoft.LabServices/labplans",
    "Microsoft.Logic/integrationServiceEnvironments",
    "Microsoft.MachineLearningServices/workspaces",
    "Microsoft.Netapp/volumes",
    "Microsoft.Network/dnsResolvers",
    "Microsoft.Network/managedResolvers",
    "Microsoft.Network/fpgaNetworkInterfaces",
    "Microsoft.Network/networkWatchers",
    "Microsoft.Network/virtualNetworkGateways",
    "Microsoft.Orbital/orbitalGateways",
    "Microsoft.PowerPlatform/enterprisePolicies",
    "Microsoft.PowerPlatform/vnetaccesslinks",
    "Microsoft.ServiceFabricMesh/networks",
    "Microsoft.ServiceNetworking/trafficControllers",
    "Microsoft.Singularity/accounts/networks",
    "Microsoft.Singularity/accounts/npu",
    "Microsoft.Sql/managedInstances",
    "Microsoft.Sql/managedInstancesOnebox",
    "Microsoft.Sql/managedInstancesStage",
    "Microsoft.Sql/managedInstancesTest",
    "Microsoft.Sql/servers",
    "Microsoft.StoragePool/diskPools",
    "Microsoft.StreamAnalytics/streamingJobs",
    "Microsoft.Synapse/workspaces",
    "Microsoft.Web/hostingEnvironments",
    "Microsoft.Web/serverFarms",
    "NGINX.NGINXPLUS/nginxDeployments",
    "PaloAltoNetworks.Cloudngfw/firewalls",
    "Qumulo.Storage/fileSystems",
    "Oracle.Database/networkAttachments",
  ]


  map_default_rules_inbound = [
    {
      ansg_rule_name                  = "DenyAnyCustomAnyInbound"
      ansg_source_address_prefix      = "*"
      ansg_destination_address_prefix = "*"
      ansg_source_port_range          = "*"
      ansg_destination_port_range     = "*"
      ansg_protocol                   = "*"
      ansg_access                     = "Deny"
      ansg_priority                   = "1000"
      ansg_description                = "Bloqueo de conexiones de entrada por defecto"
    },
  ]

  tmp_default_rules_inbound_subnet = [
    for key, value in local.map_nsg_created :
    {
      ansg_rule_name                    = "RuleAllowInIntSubnet"
      ansg_source_address_prefixes      = value.snet_prefix # address subnet
      ansg_destination_address_prefixes = value.snet_prefix # address subnet
      ansg_source_port_range            = "*"
      ansg_destination_port_range       = "*"
      ansg_protocol                     = "*"
      ansg_access                       = "Allow"
      ansg_priority                     = "100"
      ansg_description                  = ""
      ansg_subnet_key                   = key

    } if((lookup(value, "with_nsg_privend", null) == null) && (lookup(value, "with_nsg_azml", null) == null))
  ]

  map_default_rules_outbound = [
    {
      ansg_rule_name                  = "DenyAnyCustomAnyOutbound"
      ansg_source_address_prefix      = "*"
      ansg_destination_address_prefix = "*"
      ansg_source_port_range          = "*"
      ansg_destination_port_range     = "*"
      ansg_protocol                   = "*"
      ansg_access                     = "Deny"
      ansg_priority                   = "1000"
      ansg_description                = "Bloqueo de conexiones de salida por Default"
    },
  ]

  tmp_default_rules_outbound_subnet = [
    for key, value in local.map_nsg_created :
    {
      ansg_rule_name                    = "RuleAllowInOutSubnet"
      ansg_source_address_prefixes      = value.snet_prefix # address subnet
      ansg_destination_address_prefixes = value.snet_prefix # address subnet
      ansg_source_port_range            = "*"
      ansg_destination_port_range       = "*"
      ansg_protocol                     = "*"
      ansg_access                       = "Allow"
      ansg_priority                     = "100"
      ansg_description                  = ""
      ansg_subnet_key                   = key
    } if((lookup(value, "with_nsg_privend", null) == null) && (lookup(value, "with_nsg_azml", null) == null))
  ]

  map_inbound_rules_by_subnet_default = flatten(concat([
    for k, v in local.map_nsg_created : [
      for r in local.map_default_rules_inbound : merge(r, { ansg_subnet_key = k })
    ] if((lookup(v, "with_nsg_privend", null) == null) && (lookup(v, "with_nsg_azml", null) == null))
  ], local.tmp_default_rules_inbound_subnet))

  map_outbound_rules_by_subnet_default = flatten(concat([
    for k, v in local.map_nsg_created : [
      for r in local.map_default_rules_outbound : merge(r, { ansg_subnet_key = k })
    ] if((lookup(v, "with_nsg_privend", null) == null) && (lookup(v, "with_nsg_azml", null) == null))
  ], local.tmp_default_rules_outbound_subnet))


  map_result_rules_inbound = {
    for key, value in local.map_nsg_created : key => flatten(concat([
      for r1 in local.map_result_inbound_rules_for_privend : r1 if "${r1.ansg_subnet_key}" == "${key}"
      ], [
      for r2 in local.map_inbound_rules_by_subnet_default : r2 if "${r2.ansg_subnet_key}" == "${key}"
    ]))
  }


  map_result_rules_outbound = {
    for key, value in local.map_nsg_created : key => flatten(concat([
      for r1 in local.map_result_outbound_rules_for_azml : r1 if "${r1.ansg_subnet_key}" == "${key}"
      ], [
      for r2 in local.map_outbound_rules_by_subnet_default : r2 if "${r2.ansg_subnet_key}" == "${key}"
    ]))
  }

}
