
variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_id" {
  description = "AWS Internet gateway id"
  type        = string
}

variable "subnet_ids" {
  description = "Either private or public subnet ids"
  type        = list(string)
  default     = []
}

variable "is_public_route" {
  description = "Is this a public route table?"
  type        = bool
}

variable "gateway_id" {
  description = "It should be internet gateway id for public route and nat gateway id for private"
  type        = string
}
