output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "private_subnets" {
  value = data.aws_subnet_ids.private.ids
}

output "ec2_name_tag" {
  value = "tracking-ec2"
}
