variable "env" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_username" {
  description = "Master username for RDS database"
  type        = string
  default     = "dbadmin"
}
