output "subscription" {
  description = "Id de la suscripcion usada para el despliegue"
  value       = data.azurerm_subscription.current.subscription_id
}

output "snet_subnets_name" {
  description = "Nombre de las Subnets creadas."
  value       = { for region in keys(azurerm_subnet.subnet) : region => azurerm_subnet.subnet[region].name }
}

output "snet_subnets_id" {
  description = "Ids de las Subnets creadas."
  value       = { for region in keys(azurerm_subnet.subnet) : region => azurerm_subnet.subnet[region].id }
}

output "snet_subnet_name" {
  description = "Name de la Subnet, unicamente el primero para especificos"
  value       = values(azurerm_subnet.subnet)[0].name
}

output "snet_subnet_id" {
  description = "Name de la Subnet, unicamente el primero para casos especificos"
  value       = values(azurerm_subnet.subnet)[0].id
}

output "snet_list_subnets_name" {
  description = "Lista de los nombres de las Subnets aprovionadas."
  value       = [for region in keys(azurerm_subnet.subnet) : azurerm_subnet.subnet[region].name]
}

