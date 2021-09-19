variable eks_fargate_namespace {
  type = string
  default = "k8sfp"
}
variable eks_fargate_label {
  type = map
  default = {
      "node" = "fargate"
  }
}

resource "aws_iam_role" "eks_fargate_profile" {
  name = "${aws_eks_cluster.eks_cluster.name}-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_profile.name
}

resource "aws_eks_fargate_profile" "eks_fargate_profile" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "${aws_eks_cluster.eks_cluster.name}-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_profile.arn
  subnet_ids             = aws_subnet.private_subnets[*].id

  selector {
    namespace = var.eks_fargate_namespace
  }
}

resource "aws_eks_fargate_profile" "eks_fargate_profile_coredns" {
  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "${aws_eks_cluster.eks_cluster.name}-fargate-profile-coredns"
  pod_execution_role_arn = aws_iam_role.eks_fargate_profile.arn
  subnet_ids             = aws_subnet.private_subnets[*].id

  selector {
    namespace = "kube-system"
    labels = {"k8s-app": "kube-dns"}
  }
}
