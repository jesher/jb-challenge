resource "aws_iam_role" "ecr-role" {
  name               = "jb-${var.environment}-ecr-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "eks.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ecr-policy" {
  name   = "jb-${var.environment}-ecr-policy"
  role   = aws_iam_role.ecr-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}


resource "aws_iam_role" "cert-manager-role" {
  name               = "jb-${var.environment}-cert-manager-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "eks.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}


resource "aws_iam_role_policy" "cert-manager-policy" {
  name   = "jb-${var.environment}-cert-manager-policy"
  role   = aws_iam_role.cert-manager-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF

}
## IAM autoscaling ##
resource "aws_iam_policy" "eks-autoscaling-policy" {
  name        = "jb-${var.environment}-eks-autoscaling-policy"
  description = "policy for k8s administrator autoscaling"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions",
        "autoscaling:DescribeTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF

}

data "tls_certificate" "cluster" {
  url = module.eks.cluster_oidc_issuer_url
}
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint], var.oidc_thumbprint_list)
  url             = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_role" "aws_node" {
  name               = "jb-${var.environment}-eks-autoscaling-rol"
  assume_role_policy = templatefile("policies/oidc_assume_role_policy.json", { OIDC_ARN = aws_iam_openid_connect_provider.cluster.arn, OIDC_URL = replace(aws_iam_openid_connect_provider.cluster.url, "https://", ""), NAMESPACE = "kube-system", SA_NAME = "jb-${var.environment}-cluster-sa" })
  depends_on         = [aws_iam_openid_connect_provider.cluster]
}
resource "aws_iam_role_policy_attachment" "aws_node" {
  role       = aws_iam_role.aws_node.name
  policy_arn = aws_iam_policy.eks-autoscaling-policy.arn
  depends_on = [aws_iam_role.aws_node]
}

