
output "subnet_ids" {
  description = "List of either public or private subnet ids"
  value       = [for subnet in aws_subnet.subnet : subnet.id]
}
