variable "name" {
    # 기본적인 리소스 이름에 붙을 prefix 혹은 postfix, 
    # ** 영어 대소문자, 숫자, (-)만 사용, 다른것도 사용가능하지만 eksctl에서 [a-zA-Z-] 만 지원
    type    = string
    default = "k8s"
}

variable "vpc_cidr" {
    # 새로만들 VPC의 CIDR, 아래 서브넷을 포함하도록 작성
    type    = string
    default = "192.168.0.0/16"
}

variable "public_subnet_cidrs" {
    # 퍼블릭 서브넷의 네트워크 대역, var.vpc_cidr의 대역대 내로 설정
    type = list
    default  = [
        "192.168.0.0/24",
        "192.168.1.0/24",
        "192.168.2.0/24"
    ]
}

variable "private_subnet_cidrs" {
    # 프라이빗 서브넷의 네트워크 대역, var.vpc_cidr의 대역대 내로 설정
    type = list
    default  = [
        "192.168.10.0/24",
        "192.168.11.0/24",
        "192.168.12.0/24"
    ]
}

variable "home_cidr" {
    # 접근할 집 주소 등 설정
    type = string
}

variable "eks_bastion_host" {
    # bastion 호스트 관련 설정 vpc_cidr의 대역 내에서 private_ip 설정 필요
    type = map
    default = {
        instance_type    = "t3.small"
        private_ip       = "192.168.0.100"
    }
}

variable "eks_cluster_version" {
    # eks 클러스터 버전
    type    = string
    default = "1.21"
}

variable "eks_nodegroup_config" {
    # 노드그룹 스펙 관련 설정
    type = map
    default = {
        instance_type = "t3.medium"
        desired_size  = "2"
        min_size      = "2"
        max_size      = "3"
        disk_volume   = "20"
    }
}
