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

module "acm" {
    source                = "../modules/acm"
    domain_name           = var.domain_name
  alternative_name        = var.alternative_name
}

module "application_load_balancer" {
  source                = "../modules/alb"
  project_name          = module.terasvpc.project_name
  alb_security_group_id = module.security_group.alb_security_group_id
  public_subnet_az1_id  = module.terasvpc.public_subnet_az1_id
  public_subnet_az2_id  = module.terasvpc.public_subnet_az2_id
  teras-vpc_id          = module.terasvpc.teras-vpc_id
  certificate_arn       = module.acm.certificate_arn
}

module "ecs" {
  source                       =  "../modules/ecs"
  project_name                 = module.terasvpc.project_name
  ecs_tasks_execution_role_arn = module.ecs_task_execution_role.ecs_tasks_execution_role_arn
  container_image              = var.container_image 
  region                       = module.terasvpc.region
  private_app_subnet_az1_id    = module.terasvpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.terasvpc.private_app_subnet_az2_id
  ecs_security_group_id        = module.security_group.ecs_security_group_id
  alb_target_group_arn         = module.application_load_balancer.alb_target_group_arn
}

module "asg" {
  source           =  "../modules/asg"
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name
}