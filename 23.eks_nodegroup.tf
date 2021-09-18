resource "aws_eks_node_group" "eks_nodegroup" {
    node_group_name = "${var.name}-eks_nodegroup"
    cluster_name    = aws_eks_cluster.eks_cluster.name
    node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
    subnet_ids      = aws_subnet.public_subnets[*].id
    instance_types  = [var.eks_nodegroup_config["instance_type"]]

    remote_access {
        ec2_ssh_key = aws_key_pair.eks_keypair.key_name
        source_security_group_ids = [
            aws_security_group.eks_bastion_host.id
        ]
    }

    scaling_config {
        desired_size = var.eks_nodegroup_config["desired_size"]
        max_size     = var.eks_nodegroup_config["max_size"]
        min_size     = var.eks_nodegroup_config["min_size"]
    }

    depends_on = [
        aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    ]
}
