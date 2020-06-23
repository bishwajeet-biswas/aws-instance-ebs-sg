#variables#
variable "cidr_vpc" {}
variable "vpc_name" {}
variable "environment_tag" {}
variable "az" {}
variable "cidr_pub" {}
variable "igw_name" {}


#######

resource "aws_vpc" "vpc" {
    cidr_block              = var.cidr_vpc
    # provider_alias          = "aws.${var.provider_alias}"
    enable_dns_support      = true
    enable_dns_hostnames    = true
    tags = {
        Environment         = var.environment_tag
        Name                = var.vpc_name
    }
  
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
      Environment           = var.environment_tag
      Name                  = var.igw_name
  }
}


resource "aws_subnet" "public_ip" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.cidr_pub
  map_public_ip_on_launch   = true
  availability_zone         = var.az
  tags = {
      Environment           =var.environment_tag
      Name                  = "pubcic-subnet"
  }
}


// route table needs to be added for resources in public subnet to use the internet gateway

resource "aws_route_table" "rtb_pubcic" {
    vpc_id                  =aws_vpc.vpc.id

    route {
        cidr_block          = "0.0.0.0/0"
        gateway_id          = aws_internet_gateway.igw.id
    }

    // route {
    //     cidr_block          = "10.20.0.0/16"
    //     gateway_id          = var.peering_id 
    // }

    tags = {
        Environment         = var.environment_tag
        Name                = "rtb_public"
    }
  
}

// once the route table is created, this needs to associated with the public subnet to make the subnet public

resource "aws_route_table_association" "rta_public_subnet" {
  subnet_id                 = aws_subnet.public_ip.id
  route_table_id            = aws_route_table.rtb_pubcic.id
}


##output####

output "vpc_id_created" {
  value                     = aws_vpc.vpc.id
}

output "public_subnet_id_created" {
  value                     = aws_subnet.public_ip.id
}