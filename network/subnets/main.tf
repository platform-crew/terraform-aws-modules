locals {
  subnets = {
    for idx, az in var.availability_zones :
    az => {
      az   = az
      cidr = var.subnet_cidrs[idx]
    }
  }
}


resource "aws_subnet" "subnet" {
  for_each                = local.subnets
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = var.is_subnets_public

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = var.is_subnets_public ? "public-subnet" : "private-subnet"
    Tier        = var.is_subnets_public ? "public" : "private"
  })
}
