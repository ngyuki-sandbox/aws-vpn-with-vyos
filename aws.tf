////////////////////////////////////////////////////////////////////////////////
/// AWS Provider

provider "aws" {
    alias = "tokyo"
    region = "ap-northeast-1"
}

provider "aws" {
    alias = "oregon"
    region = "us-west-2"
}
