/*
aws ec2 describe-images --owners aws-marketplace --filters \
    Name=name,Values="CentOS Linux 7 *" \
    Name=virtualization-type,Values=hvm \
    Name=architecture,Values=x86_64 \
    Name=root-device-type,Values=ebs
*/

data "aws_ami" "vyos" {
    provider = "aws.oregon"
    most_recent = true
    filter { name = "name", values = ["VyOS *"] }
    filter { name = "virtualization-type", values = ["hvm"] }
    filter { name = "architecture", values = ["x86_64"] }
    owners = ["aws-marketplace"]
}

data "aws_ami" "oregon_centos" {
    provider = "aws.oregon"
    most_recent = true
    filter { name = "name", values = ["CentOS Linux 7 *"] }
    filter { name = "virtualization-type", values = ["hvm"] }
    filter { name = "architecture", values = ["x86_64"] }
    filter { name = "root-device-type", values = ["ebs"] }
    owners = ["aws-marketplace"]
}

data "aws_ami" "tokyo_centos" {
    provider = "aws.tokyo"
    most_recent = true
    filter { name = "name", values = ["CentOS Linux 7 *"] }
    filter { name = "virtualization-type", values = ["hvm"] }
    filter { name = "architecture", values = ["x86_64"] }
    filter { name = "root-device-type", values = ["ebs"] }
    owners = ["aws-marketplace"]
}

resource "aws_instance" "vyos" {
    provider = "aws.oregon"
    ami = "${data.aws_ami.vyos.id}"
    instance_type = "t2.micro"
    key_name = "${var.my_key_name}"
    vpc_security_group_ids = [
        "${aws_security_group.oregon_sg.id}"
    ]
    subnet_id = "${aws_subnet.oregon_zone_a.id}"
    source_dest_check = false
    associate_public_ip_address = true
    private_ip = "192.168.8.10"
    tags {
        Name = "example-vpn-vyos"
    }
}

resource "aws_eip" "vyos" {
    provider = "aws.oregon"
    instance = "${aws_instance.vyos.id}"
    vpc = true
}

resource "aws_instance" "ore" {
    provider = "aws.oregon"
    ami = "${data.aws_ami.oregon_centos.id}"
    instance_type = "t2.nano"
    key_name = "${var.my_key_name}"
    vpc_security_group_ids = [
        "${aws_security_group.oregon_sg.id}"
    ]
    subnet_id = "${aws_subnet.oregon_zone_a.id}"
    associate_public_ip_address = true
    private_ip = "192.168.8.20"
    tags {
        Name = "example-vpn-ore"
    }
}

resource "aws_instance" "sv01" {
    provider = "aws.tokyo"
    ami = "${data.aws_ami.tokyo_centos.id}"
    instance_type = "t2.nano"
    key_name = "${var.my_key_name}"
    vpc_security_group_ids = [
        "${aws_security_group.tokyo_sg.id}"
    ]
    subnet_id = "${aws_subnet.tokyo_zone_a.id}"
    associate_public_ip_address = true
    private_ip = "10.8.0.100"
    tags {
        Name = "example-vpn-sv01"
    }
}

resource "aws_instance" "sv02" {
    provider = "aws.tokyo"
    ami = "${data.aws_ami.tokyo_centos.id}"
    instance_type = "t2.nano"
    key_name = "${var.my_key_name}"
    vpc_security_group_ids = [
        "${aws_security_group.tokyo_sg.id}"
    ]
    subnet_id = "${aws_subnet.tokyo_zone_c.id}"
    associate_public_ip_address = true
    private_ip = "10.8.0.200"
    tags {
        Name = "example-vpn-sv02"
    }
}

output "vyos" {
    value = "${aws_eip.vyos.public_ip}"
}

output "ore" {
    value = "${aws_instance.ore.public_ip}"
}

output "sv01" {
    value = "${aws_instance.sv01.public_ip}"
}

output "sv02" {
    value = "${aws_instance.sv02.public_ip}"
}
