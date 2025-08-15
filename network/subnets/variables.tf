variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
}

variable "subnet_cidrs" {
  description = "AWS subnet CIDRS"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "Availability zones for a give subnets"
  type        = list(string)
}

variable "is_subnets_public" {
  description = "Is given subnets cidr public"
  type        = bool
}

variable "tags" {
  description = "Subnet custom Tags"
  type        = map(string)
  default     = {}
}
