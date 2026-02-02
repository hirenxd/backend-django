region            = "ap-south-1"
env               = "prod"
vpc_cidr          = "10.1.0.0/16"
instance_type     = "t3.micro"
db_instance_class = "db.t3.micro"
# public_subnet_cidrs and private_subnet_cidrs are auto-calculated from vpc_cidr
# Uncomment below to override auto-calculation:
# public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones = ["ap-south-1a", "ap-south-1b"]
db_username        = "dbadmin"
