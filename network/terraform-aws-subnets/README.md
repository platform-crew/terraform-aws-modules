# terraform-aws-subnets

A reusable Terraform module to create public or private subnets across multiple availability zones in a given VPC.

## Features

- Creates multiple subnets based on provided CIDRs and AZs
- Supports public or private subnet types
- Adds meaningful tags for identification and management

## Usage

```hcl
module "example_subnets" {
  source = "../terraform-aws-subnets"

  environment        = "staging"
  vpc_id             = aws_vpc.main.id
  subnet_cidrs       = ["10.0.0.0/20", "10.0.16.0/20"]
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  is_subnets_public  = false

  tags = {
    Project = "example"
  }
}
