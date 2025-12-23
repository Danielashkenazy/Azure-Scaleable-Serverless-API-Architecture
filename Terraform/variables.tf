variable vnet_address_space{
    description = "The address space for the virtual network"
    type        = string
    default     = "10.0.0.0/16"
}
variable apim_subnet_address_prefix {
    description = "The address prefix for the apim subnet"
    type        = string
    default     = "10.0.1.0/24"
}
variable pe_subnet_address_prefix {
    description = "The address prefix for the pe subnet"
    type        = string
    default     = "10.0.2.0/24"
}
variable "func_subnet_address_prefix" {
   description = "The address prefix for the func subnet"
   type        = string
   default     = "10.0.3.0/24"

}
variable "db_subnet_address_prefix" {
    description = "The address prefix for the db subnet"
    type        = string
    default     = "10.0.4.0/24"
  
}
variable db_admin_username {
    description = "The administrator username for the PostgreSQL server"
    type        = string
    default     = "dbadminuser"
}

variable db_admin_password {
    description = "The administrator password for the PostgreSQL server"
    type        = string
    default     = "P@ssw0rd1234!"
}
variable "openweather_api_key" {
  description = "The credential for accessing the OpenWeather API"
  type        = string
  default     = "323c5356a904bf6e6b8e27b9449fbb64"

}

variable "my_ip" {
  description = "Your public IP address for SCM access"
  type        = string
  default     = "5.29.14.43"
    }