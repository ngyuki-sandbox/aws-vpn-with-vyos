////////////////////////////////////////////////////////////////////////////////////////////////////
/// VPC

resource "aws_vpc" "tokyo_vpc" {
    provider = "aws.tokyo"
    cidr_block = "10.8.0.0/24"
    tags {
        Name = "example-vpn"
    }
}

resource "aws_internet_gateway" "tokyo_igw" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
    tags {
        Name = "example-vpn"
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// Subnet

resource "aws_subnet" "tokyo_zone_a" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
    availability_zone = "ap-northeast-1a"
    cidr_block = "10.8.0.0/25"
    map_public_ip_on_launch = false
    tags {
        Name = "example-vpn-a"
    }
}

resource "aws_subnet" "tokyo_zone_c" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
    availability_zone = "ap-northeast-1c"
    cidr_block = "10.8.0.128/25"
    tags {
        Name = "example-vpn-c"
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// RouteTable

resource "aws_route_table" "tokyo_rt_main" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
    tags {
        Name = "example-vpn"
    }
    propagating_vgws = [
        "${aws_vpn_gateway.vgw.id}"
    ]
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tokyo_igw.id}"
    }
}

resource "aws_main_route_table_association" "tokyo_rt_main_assoc" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
    route_table_id = "${aws_route_table.tokyo_rt_main.id}"
}

////////////////////////////////////////////////////////////////////////////////////////////////////
/// SecurityGroup

resource "aws_security_group" "tokyo_sg" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
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
        cidr_blocks = ["192.168.8.0/24"]
    }
    egress {
        protocol = -1
        from_port = 0
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
}
