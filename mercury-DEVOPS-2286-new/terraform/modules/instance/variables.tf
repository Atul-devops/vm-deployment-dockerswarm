variable "instance_name" {
    type = string
    description = "The name of the instance to be deployed"
}

variable "location" {
  type = string
  description = "The zone where the instance is deployed"
}

variable "machine_type" {
  type = string
  description = "The machine type of the instance"
}

variable "disk_size" {
  type = number
  description = "Size of boot disk"
}
variable "AZ_DATABASE" {
  type = string
  description = "AZ_DATABASE"
}
