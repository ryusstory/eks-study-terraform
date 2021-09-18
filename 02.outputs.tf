
output "eks_bastion_host-sshcommand" {
    value = "ssh -i ${local_file.eks_keypair.filename} ec2-user@${aws_instance.eks_bastion_host.public_ip}"
}

output "configmap" {
    value = "kubectl apply -f ./outputs/configmap.yaml"
}