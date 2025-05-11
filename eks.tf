data "aws_iam_policy_document" "policyDocEKS" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}



data "aws_iam_policy_document" "policyDocNodeEKS" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "policySnsSub" {
  name        = "policySnsSub"
  path        = "/"
  description = "policySnsSub"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "roleEKS" {
  name               = "roleEKS"
  assume_role_policy = data.aws_iam_policy_document.policyDocEKS.json

  inline_policy {
    name = "EKSEC2Policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
        ],
        Resource = "*",
      }],
    })
  }
}

resource "aws_iam_role" "roleNodeEKS" {
  name               = "roleNodeEKS"
  assume_role_policy = data.aws_iam_policy_document.policyDocNodeEKS.json
}

resource "aws_iam_role" "roleNodeSecrets" {
  name = "roleNodeSecrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            replace("${aws_eks_cluster.clusterrenegociacao-dividas.identity.0.oidc.0.issuer}:sub", "https://", "") = "system:serviceaccount:default:irsasecrets"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.roleEKS.name
}

resource "aws_iam_role_policy_attachment" "policyEKSAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.roleEKS.name
}

resource "aws_iam_role_policy_attachment" "policyRoleNodeEKS" {
  role       = aws_iam_role.roleNodeEKS.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cniPolicyRoleNodeEKS" {
  role       = aws_iam_role.roleNodeEKS.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecrPolicyRoleNodeEKS" {
  role       = aws_iam_role.roleNodeEKS.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "elbPolicyRoleNodeEKS" {
  role       = aws_iam_role.roleNodeEKS.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy_attachment" "sns_sub_policy_attachment" {
  role       = aws_iam_role.roleNodeSecrets.name
  policy_arn = aws_iam_policy.policySnsSub.arn
}

resource "aws_iam_role_policy_attachment" "ec2PolicyRoleNodeEKS" {
  role       = aws_iam_role.roleNodeEKS.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_eks_cluster" "clusterrenegociacao-dividas" {
  name     = "renegociacao-dividas"
  role_arn = aws_iam_role.roleEKS.arn

  vpc_config {
    subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.policyEKSAmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.policyEKSAmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "appNodeGrouprenegociacao-dividas" {
  cluster_name    = aws_eks_cluster.clusterrenegociacao-dividas.name
  node_group_name = "appNoderenegociacao-dividas"
  node_role_arn   = aws_iam_role.roleNodeEKS.arn
  subnet_ids      = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]

  launch_template {
    id      = aws_launch_template.eks_node_template.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 3
    max_size     = 7
    min_size     = 1
  }

  capacity_type = "SPOT"

  tags = {
    "Name"                           = "eks-node-app"
    "eks.amazonaws.com/capacityType" = "SPOT"
  }

  depends_on = [
    aws_iam_role_policy_attachment.policyRoleNodeEKS,
    aws_iam_role_policy_attachment.cniPolicyRoleNodeEKS,
    aws_iam_role_policy_attachment.ec2PolicyRoleNodeEKS,
  ]
}


data "tls_certificate" "thumbprint_eks" {
  url = aws_eks_cluster.clusterrenegociacao-dividas.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "oidc_eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.thumbprint_eks.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.clusterrenegociacao-dividas.identity.0.oidc.0.issuer
}

resource "aws_launch_template" "eks_node_template" {
  name_prefix   = "eks-node-template-"
  instance_type = "t3.large"

  metadata_options {
    http_tokens   = "optional"
    http_endpoint = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
