# Terraform Cloud Agent on AWS Fargate

This module provisions a **Terraform Cloud Agent** running on **AWS ECS Fargate**, with secure networking, IAM, logging, and autoscaling.
It enables private, scalable, and resilient execution of Terraform workloads connected to [Terraform Cloud](https://developer.hashicorp.com/terraform/cloud-docs/agents).

---

## 📐 Architecture Overview

- **ECS Cluster** (Fargate) dedicated to running Terraform Cloud agents.
- **Security Group**:
  - Runs in **private subnets** (no public IPs).
  - Egress only via **NAT Gateway**.
- **IAM Role**: Grants tasks minimal permissions for ECS execution.
- **CloudWatch Logs**: Collects agent logs (1-day retention).
- **ECS Task Definition**: Runs the Terraform Cloud agent container with environment variables for region and authentication.
- **ECS Service**: Manages desired task count and ensures availability.
- **Auto Scaling**: Scales tasks based on CPU and/or memory utilization.

---

## 🚀 Usage

```hcl
module "tfc_agent" {
  source = "./modules/tfc-agent"

  environment        = "dev"
  region             = "us-east-1"
  vpc_id             = "vpc-1234567890abcdef"
  private_subnets    = ["subnet-12345", "subnet-67890"]

  container_image    = "hashicorp/tfc-agent:latest"
  container_name     = "terraform"
  tfc_agent_token    = "your-tfc-agent-token"

  desired_count      = 2
  min_task_count     = 1
  max_task_count     = 5
  cpu_target_value   = 70
  memory_target_value= 70
}
````

---

## ⚙️ Inputs

| Variable              | Description                                   | Type   | Default                        |
| --------------------- | --------------------------------------------- | ------ | ------------------------------ |
| `environment`         | Environment name (e.g., dev, staging, prod)   | string | n/a                            |
| `region`              | AWS region                                    | string | n/a                            |
| `vpc_id`              | VPC ID where ECS tasks run                    | string | n/a                            |
| `private_subnets`     | List of private subnet IDs                    | list   | n/a                            |
| `egress_cidr_blocks`  | CIDR blocks allowed for egress                | list   | `["0.0.0.0/0"]`                |
| `task_cpu`            | Fargate task CPU units                        | string | `"512"`                        |
| `task_memory`         | Fargate task memory (MiB)                     | string | `"1024"`                       |
| `container_image`     | Agent container image                         | string | `"hashicorp/tfc-agent:latest"` |
| `container_name`      | Name of the container in ECS task             | string | `"terraform"`                  |
| `tfc_agent_token`     | Terraform Cloud agent token (sensitive)       | string | n/a                            |
| `desired_count`       | Number of tasks to run                        | number | `1`                            |
| `launch_type`         | ECS launch type                               | string | `"FARGATE"`                    |
| `min_task_count`      | Minimum number of tasks                       | number | `1`                            |
| `max_task_count`      | Maximum number of tasks                       | number | `3`                            |
| `cpu_target_value`    | Target CPU utilization (%) for autoscaling    | number | `70`                           |
| `memory_target_value` | Target memory utilization (%) for autoscaling | number | `70`                           |

---

## 📤 Outputs

This module does not currently export outputs, but you may extend it to expose:

* ECS cluster name
* ECS service name
* Security group ID
* Log group name

---

## 🔒 Security Notes

* ECS tasks run **only in private subnets** with egress restricted through NAT Gateway.
* Secrets (e.g., `tfc_agent_token`) are injected via environment variables and marked as **sensitive**.
* Logging uses **AWS-managed KMS** by default; extend if customer-managed KMS is required.
* IAM roles are scoped to **execution only** (no extra AWS privileges by default).

---

## 📊 Scaling Behavior

* **CPU scaling**: Increases/decreases tasks based on average CPU utilization.
* **Memory scaling**: Optional; triggered by memory utilization.
* Both policies have **cooldowns** (60s) to prevent thrashing.

---

## 🛠️ Requirements

* Terraform `>= 1.12.1`
* AWS Provider `~> 5.0`
* An existing VPC with private subnets + NAT Gateway

---

## 📖 References

* [Terraform Cloud Agents](https://developer.hashicorp.com/terraform/cloud-docs/agents)
* [AWS ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
* [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
