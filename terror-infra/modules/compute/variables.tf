variable "env" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ec2_sg_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "target_group_arn" {
  type = string
}
