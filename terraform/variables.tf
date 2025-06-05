variable "ami" {
  description = "AMI ID for EC2"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "subnet_a" {
  description = "Subnet A (private)"
  type        = string
}

variable "subnet_b" {
  description = "Subnet B (private)"
  type        = string
}
