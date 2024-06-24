variable "location" {
  type = string
  default = "eastus"
}
variable "base_name" {
  type = string
  default = "pocd7daaf54"
}
variable "environment" {
  type = string
  default = "dev"
}
variable "base_instance" {
  type = number
  default = 1
}

variable "tags" {
  type = map(string)
  default = {}
}