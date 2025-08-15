resource "aws_route_table" "route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    # Dynamically choose route target
    gateway_id     = var.is_public_route ? var.gateway_id : null
    nat_gateway_id = var.is_public_route ? null : var.gateway_id
  }

  tags = {
    Environment = var.environment
    Name        = var.is_public_route ? "public-route-table" : "private-route-table"
    Tier        = var.is_public_route ? "public" : "private"
  }
}


resource "aws_route_table_association" "route_table_association" {
  count          = length(var.subnet_ids)
  subnet_id      = var.subnet_ids[count.index]
  route_table_id = aws_route_table.route_table.id
}
