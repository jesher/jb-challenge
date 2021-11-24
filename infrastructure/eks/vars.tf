variable "aws_region" {
  description = "region aws"
  default = "us-east-1"
}

variable "environment" {
  description = "type environment"
  default = "dev"
}

variable "project" {
  description = "name project"
  default = "challenger"
}

variable "oidc_thumbprint_list" {
  type    = list(any)
  default = []
}

