## ✅ `terraform-aws-routetable/README.md`


### terraform-aws-routetable

A Terraform module to create and associate a route table for either public or private subnets in a VPC.

#### Features

- Creates a route table with route to Internet Gateway or NAT Gateway
- Associates the route table with one or more subnets
- Automatically sets route based on `is_public_route` flag

#### Usage

```hcl
module "example_route_table" {
  source = "../terraform-aws-routetable"

  environment     = "staging"
  vpc_id          = aws_vpc.main.id
  subnet_ids      = module.subnets.subnet_ids
  gateway_id      = aws_internet_gateway.igw.id
  is_public_route = true
}
```
