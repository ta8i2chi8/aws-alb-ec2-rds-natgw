module "network" {
  source = "./modules/network"

  pj_name  = "training-tf"
  vpc_cidr = "13.0.0.0/16"
  alb_public_subnets = [
    {
      az   = "ap-northeast-1a"
      cidr = "13.0.0.0/24"
    },
    {
      az   = "ap-northeast-1c"
      cidr = "13.0.1.0/24"
    }
  ]
  web_private_subnets = [
    {
      az   = "ap-northeast-1a"
      cidr = "13.0.2.0/24"
    }
  ]
  db_private_subnets = [
    {
      az   = "ap-northeast-1a"
      cidr = "13.0.3.0/24"
    },
    {
      az   = "ap-northeast-1c"
      cidr = "13.0.4.0/24"
    }
  ]
}

module "compute" {
  source = "./modules/compute"

  pj_name                = "training-tf"
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  web_private_subnet_ids = module.network.web_private_subnet_ids
}

module "database" {
  source = "./modules/database"

  pj_name               = "training-tf"
  vpc_id                = module.network.vpc_id
  db_private_subnet_ids = module.network.db_private_subnet_ids
  rds_security_group_ingress_rules = {
    referenced_security_group_id = module.compute.web_security_group_id
    from_port                    = "3306"
    to_port                      = "3306"
  }
  rds_username = "admin"
  rds_password = "Passworddesu" # 本来ここに記述すべきではない（tfvarsファイル等に書く）
}
