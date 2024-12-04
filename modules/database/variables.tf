variable "pj_name" {
  type        = string
  description = "PJ名"
}

variable "vpc_id" {
  type        = string
  description = "VPCのID"
}

variable "db_private_subnet_ids" {
  type        = list(string)
  description = "DBで利用するプライベートサブネットのIDのリスト"
}

variable "rds_security_group_ingress_rules" {
  type = object({
    referenced_security_group_id = string
    from_port                    = string
    to_port                      = string
  })
  description = "DB用セキュリティグループのインバウンドルール"
}

variable "rds_username" {
  description = "RDSのユーザー名"
  type        = string
}

variable "rds_password" {
  description = "RDSのパスワード"
  type        = string
  sensitive   = true
}
