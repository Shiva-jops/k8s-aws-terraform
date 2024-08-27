resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "pem_file" {
  filename        = pathexpand("~/.ssh/id_rsa")
  file_permission = "600"
  content         = tls_private_key.key_pair.private_key_pem
}

resource "aws_key_pair" "kube_kp" {
  key_name   = "kube_kp"
  public_key = trimspace(tls_private_key.key_pair.public_key_openssh)
}

resource "aws_network_interface" "kubenode" {
  for_each        = {for idx, inst in local.instances : inst => idx}
  subnet_id       = data.aws_subnets.public.ids[each.value]
  security_groups = [aws_security_group.egress_all.id]
  tags = {
    Name = local.instances[each.value]
  }
}

resource "aws_instance" "kubenode" {
  for_each      = toset(local.instances)
  ami           = data.aws_ami.ubuntu.image_id
  key_name      = aws_key_pair.kube_kp.key_name
  instance_type = var.aws_instance_type
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.kubenode[each.value].id
  }
  user_data = <<-EOT
              #!/usr/bin/env bash
              hostnamectl set-hostname ${each.value}
              cat <<EOF >> /etc/hosts
              ${aws_network_interface.kubenode["control_plane"].private_ip} controlplane
              ${aws_network_interface.kubenode["node_1"].private_ip} node1
              ${aws_network_interface.kubenode["node_2"].private_ip} node2
              EOF
              echo "PRIMARY_IP=$(ip route | grep default | awk '{ print $9 }')" >> /etc/environment
              EOT

  tags = {
    Name = each.value
  }
}

resource "aws_instance" "student_node" {
  ami             = data.aws_ami.ubuntu.image_id
  instance_type   = var.small_instance
  key_name        = aws_key_pair.kube_kp.key_name
  vpc_security_group_ids = [aws_security_group.student_node.id, aws_security_group.egress_all.id]
  tags = {
    "Name" = "student_node"
  }
  user_data = <<-EOT
                #!/usr/bin/env bash
                hostnamectl set-hostname "student-node"
                echo "${tls_private_key.key_pair.private_key_pem}" > /home/ubuntu/.ssh/id_rsa
                chown ubuntu:ubuntu/home/ubuntu/.ssh/id_rsa
                chmod 600 /home/ubuntu/.ssh/id_rsa
                curl -sS https://starship.rs/install.sh | sh -s --y
                echo 'eval "$(starship init bash)"' >> /home/ubuntu/.bashrc
                cat <<EOF >> /etc/hosts
                ${aws_network_interface.kubenode["control_plane"].private_ip} controlplane
                ${aws_network_interface.kubenode["node_1"].private_ip} node1
                ${aws_network_interface.kubenode["node_2"].private_ip} node2
                EOF
              EOT
}

resource "aws_network_interface_sg_attachment" "controlplane_sg_attachment" {
  network_interface_id = aws_instance.kubenode["control_plane"].primary_network_interface_id
  security_group_id = aws_security_group.control_plane.id
}
resource "aws_network_interface_sg_attachment" "controlplane_sg_attachment_weave" {
  network_interface_id = aws_instance.kubenode["control_plane"].primary_network_interface_id
  security_group_id    = aws_security_group.weave.id
}

resource "aws_network_interface_sg_attachment" "node1_sg_attachment" {
  network_interface_id = aws_instance.kubenode["node_1"].primary_network_interface_id
  security_group_id    = aws_security_group.worker_node.id
}

resource "aws_network_interface_sg_attachment" "node1_sg_attachment_weave" {
  network_interface_id = aws_instance.kubenode["node_1"].primary_network_interface_id
  security_group_id    = aws_security_group.weave.id
}

resource "aws_network_interface_sg_attachment" "node2_sg_attachment" {
  network_interface_id = aws_instance.kubenode["node_2"].primary_network_interface_id
  security_group_id    = aws_security_group.worker_node.id
}

resource "aws_network_interface_sg_attachment" "node2_sg_attachment_weave" {
  network_interface_id = aws_instance.kubenode["node_2"].primary_network_interface_id
  security_group_id    = aws_security_group.weave.id
}