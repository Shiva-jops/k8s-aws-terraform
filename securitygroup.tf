resource "aws_security_group" "egress_all" {
  name   = "egress_all"
  vpc_id = data.aws_vpc.default_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_vpc" {
  name   = "ingress_vpc"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }
}

resource "aws_security_group" "student_node" {
  name   = "student_node"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    description = "Login SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.localos_public_ip.cloudshell_ip.cidr]
  }
  ingress {
    description = "EC2 Instance Connect"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.206.107.24/29"]
  }
}

resource "aws_security_group" "control_plane" {
  name   = "control_plane"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    description     = "Login SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.student_node.id]
  }
  ingress {
    description = "API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }
  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }

}

resource "aws_security_group" "worker_node" {
  name   = "worker node"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    description     = "Login SSG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.student_node.id]
  }
  ingress {
    description     = "kubelet api"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.control_plane.id]
  }
  ingress {
    description = "Node Port"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "weave" {
  name   = "weave"
  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    description     = "Weave TCP"
    from_port       = 6783
    to_port         = 6783
    protocol        = "tcp"
    security_groups = [aws_security_group.control_plane.id, aws_security_group.worker_node.id]
  }
  ingress {
    description     = "Weave UDP"
    from_port       = 6783
    to_port         = 6783
    protocol        = "udp"
    security_groups = [aws_security_group.control_plane.id, aws_security_group.worker_node.id]
  }
}