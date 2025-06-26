#Variables globales 
variable "globals" {
  description = "Variables globales estaticas: app_code, env_name, env_code, provisioned_by y rsgr_sequential. Valor permitido: module.app.globals"
  type = object({
    app_code        = string
    env_name        = string
    env_code        = string
    provisioned_by  = string
    rsgr_sequential = string
  })

  validation {
    condition     = length(var.globals.app_code) == 4
    error_message = "Application code must be a 4 letters string."
  }
  validation {
    condition     = contains(["tfc"], var.globals.provisioned_by)
    error_message = "Provisioned_by permited values are: tfc."
  }
}

variable "location_code" {
  description = "Lista que especifica los códigos de las regiones del recurso. Ejemplos: \"eu2\" o \"cu1\""
  type        = string
}

#variables privadas
variable "snet_subnet_address" {
  description = "Mapa con los valores prefix_address de cada subnet"
  type = map(object({
    snet_prefix           = list(string)
    snet_srv_code         = string
    resource_sequential   = string
    service_endpoints_sub = optional(list(string))
    ansg_name_association = optional(string)
    delegation_name       = optional(string)
    enable_privend_netpol = optional(bool)
    with_nsg_privend      = optional(bool)
    with_nsg_azml         = optional(bool)
  }))

  validation {
    condition = alltrue([
      for k, v in var.snet_subnet_address : (length(v.snet_srv_code) >= 3) && (length(v.snet_srv_code) <= 4) && can(regex("^[a-z]+$", v.snet_srv_code))
    ])
    error_message = "La variable 'snet_srv_code' tiene que ser minimo de 3 caracteres a maximo 4 caracteres y solo son caracteres de a-z en minusculas."
  }
}

variable "vnet_name" {
  description = "Mapa que especifica el nombre de las vnets. Ejemplo: vnet_name = module.environment.vnet_name"
  type        = map(any)
}

variable "snet_vnet_rg_name" {
  description = "Resource group de la vnet de ambiente, aplica para el uso de environment-data"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Mapa que especifica los tags personalizados para el recurso. Ejemplo: {tag01=\"valor01\"}"
  type        = map(any)
  default     = {}
}

variable "lgan_infr_id" {
  description = "Id de los log analitycs obtenidos desde el módulo environment. Ejemplo: snet_lgan_infr_id = module.environment.lgan_infr_ids"
  type        = map(string)
}
