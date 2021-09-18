# 0. terraform eks

## 0.1. 테라폼 파일들 설명
```
│  00.provider.tf         # 테라폼 기본 환경 설정 파일
│  01.variables.tf        # 변수 설정 파일
│  10.vpc+subnets.tf      # VPC, 서브넷 배포 템플릿
│  20.eks_cluster_role.tf # eks 클러스터용 role 배포 템플릿
│  22.eks_cluster.tf      # eks 클러스터 배포 템플릿
│  23.eks_nodegroup.tf    # eks 노드그룹 배포 템플릿
│  30.eks_bastion_host.tf # eks 접속용 bastion host 배포 템플릿
│  README.md
└─outputs
```

# 1. 사전 작업

## 1.1. AWS credential 설정

`aws configure` 등으로 설정

https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-files.html

## 1.2. 테라폼 설치

https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started

# 2. 테라폼 배포

## 2.1. 변수 설정

[00.provider.tf ](../00.provider.tf)파일을 맥, Windows에 맞게 하나만 설정해주시면 됩니다.
```
# MacOS일 경우 아래 설정이 기본
shared_credentials_file = "%HOME/.aws/credentials"
# Windows일 경우 아래 설정이 기본
shared_credentials_file = "%USERPROFILE%/.aws/credentials"
```

[01.variables.tf](../01.variables.tf)

IP 대역, 인스턴스 타입 등 관련 설정등 포함

접속할 IP 주소 필수설정 eks_bastion_host.remote_public_ip
```hcl
variable "name" {
    # 기본적인 리소스 이름에 붙을 prefix 혹은 postfix, 
    # ** 영어 대소문자, 숫자, (-)만 사용, 다른것도 사용가능하지만 eksctl에서 [a-zA-Z-] 만 지원
    type    = string
    default = "k8s"
}

variable "eks_bastion_host" {
    # bastion 호스트 관련 설정 vpc_cidr의 대역 내에서 private_ip 설정 필요
    # remote_public_ip는 접근할 집 주소 등 설정
    type = map
    default = {
        instance_type    = "t3.small"
        private_ip       = "192.168.0.100"
        remote_public_ip = "0.0.0.0/32"
    }
}
```

## 2.2. 초기화

`terraform init`

## 2.3. 확인 및 배포

`terraform plan`

`terraform apply`

## 2.3. outputs 확인

output에는 현재 ssh 접속 스크립트와 kubeconfig 설정을 위한 명령어만 출력했습니다.

`terraform output`
```
PS D:\terraform> tf output
eks_bastion_host-sshcommand = "ssh -i ./outputs/aws_ssh_keypair.pem ec2-user@<IP ADDR>"
get-kubeconfig = "aws eks update-kubeconfig --name k8s-eks"
```

# 3. kubeconfig 설정

실행하면 자동으로 kubeconfig를 셋팅해줍니다.

```

aws eks update-kubeconfig --name k8s-eks

kubectl get node

```

# 4. Bastion Host

## 4.1. SSH 접속

+ 맥의 경우

    파일에 권한이 400으로 적용되어 바로 접근이 가능합니다.

+ 윈도우의 경우
    GUI를 통해 설정하려면 [여기](https://techsoda.net/windows10-pem-file-permission-settings/)와 같이 따라로 접속해서 따라하시면 됩니다

    아래는 위 절차를 스크립트로 실행가능하도록 해놨습니다.

    + CMD를 사용할 경우
     
        [cmd 스크립트](../windows-cmd.bat)를 실행하면 됩니다.

        ```
        .\scripts\windows-cmd.bat
        ```

    + Powershell을 사용할 경우

        [파워쉘용 스크립트](../windows-powershell.ps1)의 경우 파워쉘에서 스크립트가 기본적으로 막혀있어 해당 파일 내용을 파워쉘에 붙여넣으시면 됩니다.

## 4.2. Bastion Host의 접속kubectl 설정

+ configmap을 설정해야 하는 이유

    현재 배포된 k8s는 현재 테라폼이 실행되는 PC의 aws iam user를 통해 배포되고,

    Bastion Host는 PC의 access_key를 직접 사용하지 않기 위해 EC2용 Role을 만들어 IAM instance profile을 사용했습니다.

    그래서 Bastion Host에서도 kubectl을 사용하려면 해당 EC2에 부여된 ec2 iam instance profile role에 k8s 권한을 부여해야합니다.

+ 윈도우 CMD 의 경우 `/` 맥/파워쉘의 경우 `\` 을 사용해주세요.

    ```
    kubectl apply -f ./outputs/configmap.yaml
    kubectl apply -f .\outputs\configmap.yaml
    ```

+ warning이 뜨지만 정상적용완료.

# Bastion Host 접속

```
ssh -i ./outputs/aws_ssh_keypair.pem ec2-user@<IP ADDR>
aws eks update-kubeconfig --name k8s-eks
kubectl get node
```
