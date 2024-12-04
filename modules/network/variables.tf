variable "pj_name" {
  type        = string
  description = "PJ名"
}

variable "vpc_cidr" {
  type        = string
  description = "VPCのCIDR"
}

variable "alb_public_subnets" {
  type = list(object(
    {
      az   = string
      cidr = string
    }
  ))
  description = "ALBで利用するパブリックサブネット情報のリスト"
}

variable "web_private_subnets" {
  type = list(object(
    {
      az   = string
      cidr = string
    }
  ))
  description = "webサーバで利用するプライベートサブネット情報のリスト"
}

variable "db_private_subnets" {
  type = list(object(
    {
      az   = string
      cidr = string
    }
  ))
  description = "DBで利用するプライベートサブネット情報のリスト"
}
