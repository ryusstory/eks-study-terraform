# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html

data "http" "AWSLoadBalancerControllerIAMPolicy" {
    url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json"

    request_headers = {
        Accept = "application/json"
    }
}

resource "aws_iam_policy" "load-balancer-policy" {
    name        = "AWSLoadBalancerControllerIAMPolicy"
    path        = "/"
    description = "AWS LoadBalancer Controller IAM Policy"

    policy = data.http.AWSLoadBalancerControllerIAMPolicy.body
}


data "aws_iam_policy_document" "eks_oidc_aws_lb_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_aws_lb_oidc" {
    assume_role_policy  = data.aws_iam_policy_document.eks_oidc_aws_lb_policy.json
    name                = "eks_aws_lb_oidc"
    managed_policy_arns = [aws_iam_policy.load-balancer-policy.arn]
}
# iam role for oidc end

data "http" "aws_load_balancer_controller" {
    url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/v2_2_0_full.yaml"
}

locals {
    serviceaccountcontents = <<EOT
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
EOT
}

resource "local_file" "aws_load_balancer_controller" {
    content  = replace(
        replace(
            data.http.aws_load_balancer_controller.body,
            "your-cluster-name", 
            aws_eks_cluster.eks_cluster.name
        ),
        "---\n/apiVersion: v1\nkind: ServiceAccount(.|\n)+?---/",
        "---"
    )
    filename = "./outputs/v2_2_0_full.yaml"
}

output "cert_manager" {
    value = "kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.4.3/cert-manager.yaml"
}
output "aws_load_balancer_controller" {
    value = "kubectl apply --validate=false -f ${local_file.aws_load_balancer_controller.filename}"
}
# echo "eksctl create iamserviceaccount --cluster=${aws_eks_cluster.eks_cluster.name} --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --approve" > /root/iamaccount
