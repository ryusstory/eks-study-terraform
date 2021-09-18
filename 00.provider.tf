provider "aws" {
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    region                  = "ap-northeast-2"
    profile                 = "default"

    # shared_credentials_file 참고 > https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-files.html
    # MacOS일 경우 아래 설정이 기본
    # shared_credentials_file = "%HOME/.aws/credentials"
    # Windows일 경우 아래 설정이 기본
    shared_credentials_file = "%USERPROFILE%/.aws/credentials"
}