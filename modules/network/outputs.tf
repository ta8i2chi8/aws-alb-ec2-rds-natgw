output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPCのID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "パブリックサブネットのID"
}

output "web_private_subnet_ids" {
  value       = aws_subnet.web_private[*].id
  description = "Webサーバで利用するプライベートサブネットのID"
}

output "db_private_subnet_ids" {
  value       = aws_subnet.db_private[*].id
  description = "DBで利用するプライベートサブネットのID"
}
