variable "region" { type = string }
variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "instance_type" { type = string }
variable "db_instance_class" { type = string }

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (optional - auto-calculated from vpc_cidr if not provided)"
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (optional - auto-calculated from vpc_cidr if not provided)"
  type        = list(string)
  default     = null
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "db_username" {
  description = "Master username for RDS database"
  type        = string
  default     = "dbadmin"
}
