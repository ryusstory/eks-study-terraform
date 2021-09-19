data "aws_caller_identity" "current" {}

# aws ami filter
data "aws_ami" "amazon-linux-2" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-ebs"]
    }
}

# aws key_pair 생성 관련 설정
resource "tls_private_key" "eks_keypair" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "aws_key_pair" "eks_keypair" {
    key_name   = "eks_keypair"
    public_key = tls_private_key.eks_keypair.public_key_openssh
}

resource "local_file" "eks_keypair" {
    content  = tls_private_key.eks_keypair.private_key_pem
    filename = "./outputs/aws_ssh_keypair.pem"
    file_permission = "0400"
}

# aws iam profile
resource "aws_iam_instance_profile" "eks_bastion_host" {
  name = "${var.name}-eks_bastion_host"
  role = aws_iam_role.eks_bastion_host.name
}

resource "aws_iam_role" "eks_bastion_host" {
    name = "${var.name}-eks_bastion_host_role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

data "aws_iam_policy" "AdministratorAccess" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "eks_bastion_host" {
  role       = aws_iam_role.eks_bastion_host.name
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
}

resource "aws_security_group" "eks_bastion_host" {
    name        = "${var.name}-eks_bastion_host"
    description = "Eks bastion host Security Group"
    vpc_id      = aws_vpc.eks.id

    ingress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = [aws_vpc.eks.cidr_block, var.home_cidr]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name}-eks_bastion_host"
    }
}

resource "aws_instance" "eks_bastion_host" {
    ami           = data.aws_ami.amazon-linux-2.image_id
    key_name      = aws_key_pair.eks_keypair.key_name
    subnet_id     = aws_subnet.public_subnets[0].id
    instance_type = var.eks_bastion_host["instance_type"]
    private_ip    = var.eks_bastion_host["private_ip"]

    associate_public_ip_address = true
    vpc_security_group_ids      = [aws_security_group.eks_bastion_host.id]
    iam_instance_profile        = aws_iam_instance_profile.eks_bastion_host.id

    root_block_device {
        volume_type = "gp3"
        volume_size = 20
        delete_on_termination = true
        tags = {
            Name = "${var.name}-bastion_host"
        }
    }
    
    tags = {
        Name = "${var.name}-bastion_host"
    }

    user_data = <<-EOF
        #!/bin/bash
        hostnamectl --static set-hostname eksctl-host

        # Install tools
        yum -y install git tree tmux jq lynx htop

        # Install eksctl
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        mv /tmp/eksctl /usr/local/bin

        # Install kubectl v1.21.2
        curl -LO https://dl.k8s.io/release/v1.21.2/bin/linux/amd64/kubectl
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

        # Install the full Amazon Corretto 11
        yum install java-11-amazon-corretto -y

        # Install Docker
        amazon-linux-extras install docker -y
        systemctl start docker && systemctl enable docker

        # Source bash-completion for kubectl
        source <(kubectl completion bash)
        echo 'source <(kubectl completion bash)' >>~/.bashrc 
        echo 'alias k=kubectl' >> ~/.bashrc
        echo 'complete -F __start_kubectl k' >>~/.bashrc

        # Install kubens kubectx
        git clone https://github.com/ahmetb/kubectx /opt/kubectx
        ln -s /opt/kubectx/kubens /usr/local/bin/kubens
        ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

        # Config convenience
        echo 'alias vi=vim' >> /etc/profile
        echo "sudo su -" >> /home/ec2-user/.bashrc

        # Change localtime
        sed -i "s/UTC/Asia\/Seoul/g" /etc/sysconfig/clock
        ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
        
        # set region
        mkdir ~/.aws/
        printf "[default]\nregion = ap-northeast-2\n" > ~/.aws/config

        # Setting for worker
        echo "${tls_private_key.eks_keypair.private_key_pem}" >> /root/.ssh/id_rsa
        chmod 400 /root/.ssh/id_rsa

        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
        chmod 700 get_helm.sh
        /get_helm.sh

        cat <<\EOT > /set_worker_node.sh
        #!/bin/bash
        WORKER_NODES=($(aws ec2 describe-instances --region ap-northeast-2 --filters "Name=tag:eks:nodegroup-name,Values=k8s-eks_nodegroup" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text))
        if [ -z "$WORKER_NODES" ]; then 
            echo "no WORKER_NODES"
        else 
            echo "WORKER_NODES exists"
            for ((worker=0; worker<$${#WORKER_NODES[@]}; worker++)); do
                echo "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$${WORKER_NODES[$worker]}" > /usr/local/bin/w$(echo $worker+1 | bc)
                chmod +x /usr/local/bin/w$(echo $worker+1 | bc)
            done;
        fi
        EOT
        chmod +x /set_worker_node.sh
        /set_worker_node.sh
        aws eks update-kubeconfig --name k8s-eks
    EOF
}

resource "local_file" "kubectl_permission_to_ec2_iam_role" {
    content  = yamlencode({
        "data": {
            "mapRoles": "- rolearn: ${aws_iam_role.eks_bastion_host.arn}\n  username: ${aws_iam_role.eks_bastion_host.name}\n  groups:\n    - system:masters\n"
        },
    })

    filename = "./outputs/configmap.yaml"
}
output "edit_configmap_for_bastion_host" {
    value = "kubectl edit -n kube-system configmap/aws-auth"
}

output "bastion_host_ssh_command" {
    value = "ssh -i ${local_file.eks_keypair.filename} ec2-user@${aws_instance.eks_bastion_host.public_ip}"
}
