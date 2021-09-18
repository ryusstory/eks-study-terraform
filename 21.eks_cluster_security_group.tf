# resource "aws_security_group" "eks_cluster_control_plane" {
#     name        = "${var.name}-eks_cluster_control_plane"
#     description = "Control Plane Security Group"
#     vpc_id      = aws_vpc.eks.id
#     tags = {
#         Name = "${var.name}-eks_cluster_control_plane"
#     }
# }

# resource "aws_security_group" "eks_cluster_nodegroup" {
#     name        = "${var.name}-eks_cluster_nodegroup"
#     description = "${var.name}-Nodegroup security group"
#     vpc_id      = aws_vpc.eks.id
#     ingress {
#         protocol  = "tcp"
#         from_port = 0
#         to_port   = 0
#         self      = true
#     }
#     ingress {
#         protocol  = "tcp"
#         from_port = 443
#         to_port   = 443
#         security_groups = [aws_security_group.eks_cluster_control_plane.id]
#     }
#     ingress {
#         protocol  = "tcp"
#         from_port = 1025
#         to_port   = 65535
#         security_groups = [aws_security_group.eks_cluster_control_plane.id]
#     }
#     egress {
#         from_port        = 0
#         to_port          = 0
#         protocol         = "-1"
#         cidr_blocks      = ["0.0.0.0/0"]
#     }    
#     tags = {
#         Name = "${var.name}-eks_cluster_nodegroup"
#     }
# }

# resource "aws_security_group_rule" "eks_cluster_control_plane_inbound" {
#     security_group_id = aws_security_group.eks_cluster_control_plane.id
#     type              = "ingress"
#     from_port         = 443
#     to_port           = 443
#     protocol          = "tcp"
#     source_security_group_id = aws_security_group.eks_cluster_nodegroup.id
# }

# resource "aws_security_group_rule" "eks_cluster_control_plane_outbound" {
#     security_group_id = aws_security_group.eks_cluster_control_plane.id
#     type              = "egress"
#     from_port         = 1025
#     to_port           = 65535
#     protocol          = "tcp"
#     source_security_group_id = aws_security_group.eks_cluster_nodegroup.id
# }
