output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "ec2_ips" {
  value = aws_instance.web[*].public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
