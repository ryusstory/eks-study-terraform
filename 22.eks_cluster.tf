resource "aws_eks_cluster" "eks_cluster" {
    name     = "${var.name}-eks"
    role_arn = aws_iam_role.eks_cluster_role.arn
    version  = var.eks_cluster_version
    vpc_config {
        subnet_ids              = aws_subnet.public_subnets[*].id
        security_group_ids      = [
            aws_security_group.eks_bastion_host.id
        ]
        public_access_cidrs     = [
            var.eks_bastion_host["remote_public_ip"]
        ]
        endpoint_private_access = true
    }

    depends_on = [
        aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
        aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
    ]
}

output "get-kubeconfig" {
    value = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks_cluster.name}"
}
