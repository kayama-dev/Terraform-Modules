#Configure aws provider
provider "aws" {
    region  = var.region
  profile = "Terraform-user"
}

#create vpc
module "terasvpc" {
    source                        = "../modules/vpc"
    region                        = var.region
    project_name                  = var.project_name 
    vpc_cidr                      = var.vpc_cidr 
    public_subnet_az1_cidr        = var.public_subnet_az1_cidr
    public_subnet_az2_cidr        = var.public_subnet_az2_cidr
    private_subnet_az1_cidr       = var.private_subnet_az1_cidr
    private_subnet_az2_cidr       = var.private_subnet_az2_cidr
    private_data_subnet_az1_cidr  = var.private_data_subnet_az1_cidr
    private_data_subnet_az2_cidr  = var.private_data_subnet_az2_cidr
  }

#create nat gateway
module "natgateway" {
source                      = "../modules/nat-gateway"
public_subnet_az1_id        = module.terasvpc.public_subnet_az1_id
internet_gateway            = module.terasvpc.internet_gateway
public_subnet_az2_id        = module.terasvpc.public_subnet_az2_id 
teras-vpc_id                = module.terasvpc.teras-vpc_id 
private_app_subnet_az1_id   = module.terasvpc.private_app_subnet_az1_id
private_data_subnet_az1_id  = module.terasvpc.private_data_subnet_az1_id
private_app_subnet_az2_id   = module.terasvpc.private_app_subnet_az2_id 
private_data_subnet_az2_id  = module.terasvpc.private_data_subnet_az2_id
}

module "security_group" {
  source = "../modules/security-groups"
  teras-vpc_id = module.terasvpc.teras-vpc_id
}

module "ecs_task_execution_role" {
  source = "../modules/ecs-task-execution-role"
  project_name = module.terasvpc.teras-vpc_id
}