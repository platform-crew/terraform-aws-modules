# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-rds-${var.rds_db_name}-subnet-group"
  subnet_ids = var.rds_subnet_ids

  tags = {
    Name        = "${var.environment}-rds-${var.rds_db_name}-subnet-group"
    Environment = var.environment
  }
}

# Security Group
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-${var.rds_db_name}-sg"
  description = "Allow PostgreSQL access from application SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.rds_requester_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-rds-${var.rds_db_name}-sg"
    Environment = var.environment
  }
}

# RDS Instance
resource "aws_db_instance" "rds_db" {
  identifier                          = "${var.environment}-rds-${var.rds_db_name}"
  engine                              = "postgres"
  engine_version                      = var.rds_engine_version
  instance_class                      = var.rds_instance_class
  db_name                             = var.rds_db_name
  username                            = var.rds_db_username
  password                            = var.rds_db_password
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  multi_az              = true
  storage_type          = "gp3"
  storage_encrypted     = true

  vpc_security_group_ids     = [aws_security_group.rds.id]
  db_subnet_group_name       = aws_db_subnet_group.this.name
  backup_retention_period    = var.rds_backup_retention_period
  backup_window              = var.rds_backup_window
  auto_minor_version_upgrade = var.rds_auto_minor_version_upgrade
  maintenance_window         = var.rds_maintenance_window
  deletion_protection        = var.rds_enable_delete_protection
  publicly_accessible        = false
  apply_immediately          = false
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.environment}-rds-${var.rds_db_name}-final"

  tags = {
    Name        = "${var.environment}-rds-${var.rds_db_name}"
    Environment = var.environment
  }
}
