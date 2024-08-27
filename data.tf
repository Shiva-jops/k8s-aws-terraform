data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240801"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}
data "localos_public_ip" "cloudshell_ip" {}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
  filter {
    name   = "availability-zone"
    values = [
      "${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"
    ]
  }
}