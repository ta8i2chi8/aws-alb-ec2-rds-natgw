variable "pj_name" {
  type        = string
  description = "PJ名"
}

variable "vpc_id" {
  type        = string
  description = "VPCのID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "パブリックサブネットのIDのリスト"
}

variable "web_private_subnet_ids" {
  type        = list(string)
  description = "Webサーバで利用するプライベートサブネットのIDのリスト"
}
