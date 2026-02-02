provider "aws" {
  region = var.region
}

# Auto-calculate subnet CIDRs if not provided
locals {
  # Calculate number of subnets based on availability zones
  num_azs = length(var.availability_zones)

  # Auto-calculate public subnet CIDRs: 10.x.1.0/24, 10.x.2.0/24, etc.
  auto_public_cidrs = [
    for i in range(local.num_azs) : cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]

  # Auto-calculate private subnet CIDRs: 10.x.10.0/24, 10.x.20.0/24, etc.
  auto_private_cidrs = [
    for i in range(local.num_azs) : cidrsubnet(var.vpc_cidr, 8, (i + 1) * 10)
  ]

  # Use provided CIDRs or fall back to auto-calculated ones
  public_subnet_cidrs  = var.public_subnet_cidrs != null ? var.public_subnet_cidrs : local.auto_public_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs != null ? var.private_subnet_cidrs : local.auto_private_cidrs
}

module "vpc" {
  source   = "../../modules/vpc"
  vpc_cidr = var.vpc_cidr
  env      = var.env
}

module "networking" {
  source               = "../../modules/networking"
  vpc_id               = module.vpc.vpc_id
  env                  = var.env
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "security" {
  source = "../../modules/security"
  vpc_id = module.vpc.vpc_id
  env    = var.env
}
module "alb" {
  source            = "../../modules/alb"
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

module "compute" {
  source             = "../../modules/compute"
  env                = var.env
  private_subnet_ids = module.networking.private_subnet_ids
  ec2_sg_id          = module.security.ec2_sg_id
  instance_type      = var.instance_type
  target_group_arn   = module.alb.target_group_arn
}

module "rds" {
  source             = "../../modules/rds"
  env                = var.env
  private_subnet_ids = module.networking.private_subnet_ids
  db_sg_id           = module.security.db_sg_id
  db_instance_class  = var.db_instance_class
  db_username        = var.db_username
}
