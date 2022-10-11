output "target" {
  description = "Target EC2 instance ID"
  value = aws_instance.target.id
}

output "target_ip" {
  description = "Target EC2 instance IP"
  value = aws_instance.target.public_ip
}

output "source" {
  description = "Source EC2 instance ID"
  value = aws_instance.source.id
}

output "source_ip" {
  description = "Source EC2 instance IP"
  value = aws_instance.source.public_ip
}
