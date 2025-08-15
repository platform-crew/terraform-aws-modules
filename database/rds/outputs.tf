# Outputs
output "rds_endpoint" {
  description = "RDS endpoint URL"
  value       = aws_db_instance.rds_db.endpoint
}

output "rds_resource_id" {
  description = "RDS resource ID"
  value       = aws_db_instance.rds_db.resource_id
}
