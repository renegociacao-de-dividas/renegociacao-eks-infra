variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ca-central-1"
}

variable "default_vpc_id" {
  description = "Default VPC ID"
  type = string
  default = "vpc-06f9d8f53f94f2678"
}

variable "aws_subnet_1a_id" {
  description = "AWS subnet-1a ID"
  type = string
  default = "subnet-0603bc66a876e2cf8"
}

variable "aws_subnet_1b_id" {
  description = "AWS subnet-1b ID"
  type = string
  default = "subnet-08884f6c15856ab6b"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type = string
  default = "011706314791"
}