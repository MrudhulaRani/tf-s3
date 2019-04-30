output "vpc-cidr" {
  value = "${aws_vpc.vpc_s3.cidr_block}"
}

output "vm1_bastion_host_s3_pubilc_ip" {
  value = "${aws_instance.vm1_bastion_host_s3.public_ip}"
}
output "elb1_dns_name_ip" {
  value = "${aws_elb.elb1_s3.dns_name}"
}