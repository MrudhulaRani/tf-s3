resource "aws_vpc" "vpc_s3" {
  cidr_block = "${var.cidr_vpc}"
  tags {
    Name = "vpc_s3"
  }
}

resource "aws_internet_gateway" "igw_s3" {
  vpc_id = "${aws_vpc.vpc_s3.id}"
  tags {
    Name="igw_s3"
  }
}

resource "aws_route_table" "rtb1_wi_s3" {
  vpc_id = "${aws_vpc.vpc_s3.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw_s3.id}"
  }
  tags {
    Name="rtb1_wi_s3"
  }
}

resource "aws_route_table" "rtb2_woi_s3" {
  vpc_id = "${aws_vpc.vpc_s3.id}"
  route {
    cidr_block = "${var.cidr_sn_pb1_s3}"
  }
  route {
    cidr_block = "${var.cidr_sn_pv1_s3}"
  }
  route {
    cidr_block = "${var.cidr_sn_pv2_s3}"
  }
  tags {
    Name="rtb2_woi_s3"
  }
}

resource "aws_network_acl" "nacl1_s3" {
  vpc_id = "${aws_vpc.vpc_s3.id}"
  subnet_ids = ["${aws_subnet.sn_pb1_s3.id}","${aws_subnet.sn_pv1_s3.id}","${aws_subnet.sn_pv2_s3.id}"]
  ingress {
    action = "allow"
    from_port = 0
    protocol = "-1"
    rule_no = 100
    to_port = 0
  }
  egress {
    action = "allow"
    from_port = 0
    protocol = "-1"
    rule_no = 100
    to_port = 0
  }
  tags {
    Name="nacl1_s3"
  }
}

resource "aws_security_group" "sg1_s3" {
  name = "sg1_s3_allow_ssh_http"
  vpc_id = "${aws_vpc.vpc_s3.id}"
  tags {
    Name="sg1_s3"
  }
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "sn_pb1_s3" {
  cidr_block = "${var.cidr_sn_pb1_s3}"
  vpc_id = "${aws_vpc.vpc_s3.id}"
  availability_zone = "${var.az1}"
  map_public_ip_on_launch = true
  tags {
    Name="sn_pb1_s3"
  }
}

resource "aws_subnet" "sn_pv1_s3" {
  cidr_block = "${var.cidr_sn_pv1_s3}"
  vpc_id = "${aws_vpc.vpc_s3.id}"
  availability_zone = "${var.az1}"
  map_public_ip_on_launch = false
  tags {
    Name="sn_pv1_s3"
  }
}

resource "aws_subnet" "sn_pv2_s3" {
  cidr_block = "${var.cidr_sn_pv2_s3}"
  vpc_id = "${aws_vpc.vpc_s3.id}"
  availability_zone = "${var.az2}"
  map_public_ip_on_launch = false
  tags {
    Name="sn_pv2_s3"
  }
}

resource "aws_route_table_association" "rtb1_pb1_asn-s3" {
  route_table_id = "${aws_route_table.rtb1_wi_s3.id}"
  subnet_id = "${aws_subnet.sn_pb1_s3.id}"
}

resource "aws_route_table_association" "rtb2_pv1_asn_s3" {
  route_table_id = "${aws_route_table.rtb2_woi_s3.id}"
  subnet_id = "${aws_subnet.sn_pv1_s3.id}"
}

resource "aws_route_table_association" "rtb2_pv2_asn_s3" {
  route_table_id = "${aws_route_table.rtb2_woi_s3.id}"
  subnet_id = "${aws_subnet.sn_pv2_s3.id}"
}

resource "aws_instance" "vm1_bastion_host_s3" {
  ami = "${var.bastion_host_ami2}"
  instance_type = "${var.instance_type2}"
  subnet_id = "${aws_subnet.sn_pb1_s3}"
  key_name = "cli"
  security_groups = ["${aws_security_group.sg1_s3.id}"]
  associate_public_ip_address = true
  tags {
    Name="vm1_bastion_host_s3"
  }
}

resource "aws_elb" "elb1_s3" {
  "listener" {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  name = "elb1_s3"
  availability_zones = ["${var.az1}","${var.az2}"]
  security_groups = ["${aws_security_group.sg1_s3.id}"]
  subnets = ["${aws_subnet.sn_pb1_s3.id}","${aws_subnet.sn_pv1_s3.id}","${aws_subnet.sn_pv2_s3.id}"]
  tags {
    Name="elb1_s3"
  }
}

resource "aws_elb_attachment" "elb1_atc_s3" {
  elb = "${aws_elb.elb1_s3.id}"
  instance = ""
}

resource "aws_launch_configuration" "lc1_s3" {
  image_id = "${var.ami1}"
  instance_type = "${var.instance_type1}"
  key_name = "cil"
  name = "lc1_s3"
  user_data = <<-EOF
              #!/bin/bash
              yum install nginx -y
              service nginx start
              EOF
  security_groups = ["${aws_security_group.sg1_s3.id}"]
}

resource "aws_autoscaling_group" "asc1_s3" {
  max_size = 5
  min_size = 2
  name = "asc1_s3"
  availability_zones = ["${var.az1}","${var.az2}"]
  launch_configuration = "${aws_launch_configuration.lc1_s3.name}"
  load_balancers = ["${aws_elb.elb1_s3.name}"]
  vpc_zone_identifier = ["${aws_subnet.sn_pv1_s3.id}","${aws_subnet.sn_pv2_s3.id}"]
}