resource "aws_vpn_gateway" "vgw" {
    provider = "aws.tokyo"
    vpc_id = "${aws_vpc.tokyo_vpc.id}"
    tags {
        Name = "example-vpn"
    }
}

resource "aws_customer_gateway" "cgw" {
    provider = "aws.tokyo"
    bgp_asn = 65000
    ip_address = "${aws_eip.vyos.public_ip}"
    type = "ipsec.1"
    tags {
        Name = "example-vpn"
    }
}

resource "aws_vpn_connection" "vpn" {
    provider = "aws.tokyo"
    vpn_gateway_id = "${aws_vpn_gateway.vgw.id}"
    customer_gateway_id = "${aws_customer_gateway.cgw.id}"
    type = "ipsec.1"
    static_routes_only = false
    tags {
        Name = "example-vpn"
    }
}
