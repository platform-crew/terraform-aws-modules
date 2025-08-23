# --------------------
# Fargate Security Group
# --------------------
# Justification: Terraform agent runs in private subnets, no public IPs, egress via NAT Gateway only.
#tfsec:ignore:AVD-AWS-0104
resource "aws_security_group" "terraform_agent_sg" {
  name        = "${var.environment}-terraform-agent-sg"
  description = "Security group for Terraform Fargate agent (egress controlled via NAT Gateway)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.egress_cidr_blocks
    description = "Required for Terraform Agent to access registries, APIs, and cloud services. Outbound traffic is restricted via private subnet + NAT Gateway."
  }

  tags = {
    Name              = "${var.environment}-terraform-agent-sg"
    Environment       = var.environment
    Purpose           = "Terraform Agent"
    SecurityNote      = "Outbound egress allowed but traffic forced through NAT Gateway. No direct internet exposure."
    ComplianceJustify = "Terraform agent runs arbitrary code and requires external connectivity; NAT provides control and monitoring."
  }
}

# --------------------
# ECS Cluster
# --------------------
resource "aws_ecs_cluster" "terraform_agents" {
  name = "${var.environment}-terraform-agents-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --------------------
# IAM Role for ECS Task
# --------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# Attach ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --------------------
# ECS Task Definition (Terraform Agent)
# --------------------
resource "aws_ecs_task_definition" "terraform_agent_task" {
  family                   = "${var.environment}-terraform-agent"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      command   = var.container_command
      environment = [
        { name = "AWS_DEFAULT_REGION", value = var.region },
        { name = "TFC_AGENT_TOKEN", value = var.tfc_agent_token },
        { name = "TFC_AGENT_NAME", value = "${var.environment}-${var.region}-agent" },
        { name = "TFC_AGENT_POOL", value = var.tfc_agent_pool }
      ]
      # Optional: add logging here if needed
    }
  ])
}

# --------------------
# ECS Service (Terraform Agent)
# --------------------
resource "aws_ecs_service" "terraform_agent_service" {
  name            = "${var.environment}-terraform-agent-service"
  cluster         = aws_ecs_cluster.terraform_agents.id
  task_definition = aws_ecs_task_definition.terraform_agent_task.arn
  desired_count   = var.desired_count
  launch_type     = var.launch_type

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.terraform_agent_sg.id]
    assign_public_ip = false
  }
}

# --------------------
# Application Auto Scaling Target
# --------------------
resource "aws_appautoscaling_target" "ecs_scaling_target" {
  max_capacity       = var.max_task_count
  min_capacity       = var.min_task_count
  resource_id        = "service/${aws_ecs_cluster.terraform_agents.name}/${aws_ecs_service.terraform_agent_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# --------------------
# Scale on CPU
# --------------------
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "${var.environment}-ecs-scale-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_value # e.g. 50% CPU
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# --------------------
# Scale on Memory (Optional)
# --------------------
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  name               = "${var.environment}-ecs-scale-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_scaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_scaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_value # e.g. 60% memory
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
