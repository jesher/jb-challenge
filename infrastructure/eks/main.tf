# EKS #######################

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  cluster_name                         = "jb-${var.environment}-${var.project}-cluster"
  cluster_version                      = "1.21"
  vpc_id                               = module.vpc.vpc_id
  subnets                              = [module.vpc.private_subnets[0], module.vpc.public_subnets[1]]
  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]

  worker_groups = [
    {
      name                          = "on-demand"
      instance_type                 = "t3.medium"
      asg_max_size                  = 1
      kubelet_extra_args            = "--node-labels=node.kubernetes.io/lifecycle=normal"
      suspended_processes           = ["AZRebalance"]
      root_volume_type              = "gp2"
      root_volume_size              = "50"
    },
    {
      name                          = "spot-2"
      spot_price                    = "0.0095"
      instance_type                 = "t3.small"
      asg_max_size                  = 1
      kubelet_extra_args            = "--node-labels=node.kubernetes.io/lifecycle=spot,"
      suspended_processes           = ["AZRebalance"]
      root_volume_type              = "gp2"
      root_volume_size              = "50"
    }
  ]

  tags = {
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "CONTEXT"                           = "DEV"
  }
}

resource "local_file" "cluster_kubeconfig" {
  content  = module.eks.kubeconfig
  filename = "${path.cwd}/outputs/kubeconfig"
}


resource "null_resource" "installation" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOF

pwd

helm repo update

helmfile --file ../../kubernetes/helmfile/helmfile.yaml --log-level=debug --environment $ENVIRONMENT sync

EOF
    environment = {
      KUBECONFIG      = local_file.cluster_kubeconfig.filename
      ENVIRONMENT     = var.environment
    }
  }
}
