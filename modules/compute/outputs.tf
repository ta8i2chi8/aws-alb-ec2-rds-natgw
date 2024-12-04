output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALBで利用しているセキュリティグループのID"
}

output "web_security_group_id" {
  value       = aws_security_group.wordpress_server.id
  description = "EC2で利用しているセキュリティグループのID"
}
