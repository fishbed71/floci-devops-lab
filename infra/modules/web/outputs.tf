output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "launch_template_version" {
  value = aws_launch_template.this.latest_version
}

output "target_group_arn" {
  value = aws_lb_target_group.web.arn
}
