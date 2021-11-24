module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name                 = "jb-${var.environment}-${var.project}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/jb-${var.environment}-${var.project}-cluster" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/jb-${var.environment}-${var.project}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = {
    Example    = "jb-${var.environment}-${var.project}-cluster"
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}


resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}