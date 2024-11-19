
# eks cluster policy
data "aws_iam_policy_document" "k8s-cluster-policy-doc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster-role" {
  name               = "${local.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.k8s-cluster-policy-doc.json
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "cluster-policy-role-attach1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-policy-role-attach2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

#eks cluster
resource "aws_eks_cluster" "k8s-cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private-us-east-1a.id, aws_subnet.private-us-east-1b.id]
  }

#Change Auth Mode from Config to EKS API
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-policy-role-attach1,
    aws_iam_role_policy_attachment.cluster-policy-role-attach2,
  ]
}


# Setup EKS AWS EBS CSI Add-on
data "tls_certificate" "eks" {
  url = aws_eks_cluster.k8s-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "k8s-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks.url
}

data "aws_iam_policy_document" "k8s-cluster-autoscaler-role-policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.k8s-oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.k8s-oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "k8s-cluster-autoscaler-role" {
  assume_role_policy = data.aws_iam_policy_document.k8s-cluster-autoscaler-role-policy.json
  name               = "k8s-cluster-autoscaler-role"
}

resource "aws_iam_role_policy_attachment" "k8s-cluster-autoscaler-role-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.k8s-cluster-autoscaler-role.name
}

resource "aws_eks_addon" "k8s-driver" {
  cluster_name             = aws_eks_cluster.k8s-cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.36.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.k8s-cluster-autoscaler-role.arn
}


#node group role
resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node-policy-attach1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "node-policy-attach2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "node-policy-attach3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}


resource "aws_iam_role_policy_attachment" "node-policy-attach4" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.k8s-cluster.version}/amazon-linux-2/recommended/release_version"
}

#worker node
resource "aws_eks_node_group" "k8s-node" {
  cluster_name    = aws_eks_cluster.k8s-cluster.name
  node_group_name = "k8s-node-group"
  version         = aws_eks_cluster.k8s-cluster.version
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = [aws_subnet.private-us-east-1a.id, aws_subnet.private-us-east-1b.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  capacity_type  = "SPOT"
  instance_types = ["t2.medium"]

  update_config {
    max_unavailable = 1
  }


  depends_on = [
    aws_iam_role_policy_attachment.node-policy-attach1,
    aws_iam_role_policy_attachment.node-policy-attach2,
    aws_iam_role_policy_attachment.node-policy-attach3,
    aws_iam_role_policy_attachment.node-policy-attach4,
  ]

  tags = {
      Name = k8s-node
  }

}