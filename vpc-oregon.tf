////////////////////////////////////////////////////////////////////////////////////////////////////
/// VPC

resource "aws_vpc" "oregon_vpc" {
    provider = "aws.oregon"
    cidr_block = "192.168.8.0/24"
    tags {
        Name = "example-vpn"
    }
}

resource "aws_internet_gateway" "oregon_igw" {
    provider = "aws.oregon"
    vpc_id = "${aws_vpc.oregon_vpc.id}"
    tags {
        Name = "example-vpn"
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// Subnet

resource "aws_subnet" "oregon_zone_a" {
    provider = "aws.oregon"
    vpc_id = "${aws_vpc.oregon_vpc.id}"
    availability_zone = "oregon-west-2a"
    cidr_block = "192.168.8.0/25"
    map_public_ip_on_launch = false
    tags {
        Name = "example-vpn-a"
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// RouteTable

resource "aws_route_table" "oregon_rt_main" {
    provider = "aws.oregon"
    vpc_id = "${aws_vpc.oregon_vpc.id}"
    tags {
        Name = "example-vpn"
    }
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.oregon_igw.id}"
    }
    route {
        cidr_block = "10.8.0.0/24"
        instance_id = "${aws_instance.vyos.id}"
    }
}

resource "aws_main_route_table_association" "oregon_rt_main_assoc" {
    provider = "aws.oregon"
    vpc_id = "${aws_vpc.oregon_vpc.id}"
    route_table_id = "${aws_route_table.oregon_rt_main.id}"
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// SecurityGroup

resource "aws_security_group" "oregon_sg" {
    provider = "aws.oregon"
    vpc_id = "${aws_vpc.oregon_vpc.id}"
    tags {
        Name = "example-vpn"
    }
    ingress {
        protocol = -1
        from_port = 0
        to_port = 0
        self = true
    }
    ingress {
        protocol = "tcp"
        from_port = 22
        to_port = 22
        cidr_blocks = "${var.my_cidr_blocks}"
    }
    ingress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["10.8.0.0/24"]
    }
    egress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}
