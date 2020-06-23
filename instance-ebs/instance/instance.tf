#variables#
variable "environment_tag" {}
variable "sg_bastion" {}
variable "keypair_name" {}
variable "ami_name" {}
variable "instance_type" {}
variable "public_key_path" {}
variable "vpc_name" {}
variable "subnet_public" {}
variable "bastion_name" {}
variable "provider_alias" {}
variable "root_vol_size" {}
variable "root_vol_type" {}
variable "data1_vol_size" {}
variable "data1_vol_type" {}
variable "data2_vol_size" {}
variable "data2_vol_zone" {}
variable "data2_vol_type" {}
#############################

resource "aws_key_pair" "ec2key" {
    key_name            = var.keypair_name
    public_key          = file(var.public_key_path)
}

########bastion setup##########

resource "aws_security_group" "sg_22" {
    name                = var.sg_bastion
    vpc_id              = var.vpc_name
    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["103.95.81.214/32", "103.95.81.215/32"]
    }

    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "icmp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress  {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
        Environment     = var.environment_tag
        Name            = var.sg_bastion
    }
  
}



resource "aws_instance" "testpublicinstance" {
    ami                     = var.ami_name
    instance_type           = var.instance_type

    root_block_device {
    // device_name           = "/dev/sda1"
    volume_size           = var.root_vol_size
    volume_type           = var.root_vol_type
    delete_on_termination = true
    encrypted             = false
    }
    
    ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = var.data1_vol_size
    volume_type           = var.data1_vol_type
    delete_on_termination = true
    encrypted             = false
    }


    subnet_id               = var.subnet_public
    vpc_security_group_ids  = [aws_security_group.sg_22.id]
    key_name                = aws_key_pair.ec2key.key_name
    user_data               = file("${path.module}/mount.sh")

    tags = {
        Environment         = var.environment_tag
        Name                = var.bastion_name
    }
}

// lets create additional data volumes
// Note: if data volumes are mentioned outside "aws_instance" resource, 
// device name has to start with xvd* 
// if devices are named with sd* it won't mount. 
// Note-- using ebs aws_ebs_volume is dangerous -- once deployed; if you again try to terraform apply, it will recreate the whole instance again. 
// 

resource "aws_ebs_volume" "data-vol" {
 availability_zone          = var.data2_vol_zone // "us-east-1a"
 size                       = var.data2_vol_size
 type                       = var.data2_vol_type // "standard", "gp2", "io1", "sc1" or "st1" (Default: "gp2").
 tags = {
        Name                = "data-volume"
        Environment         = var.environment_tag
 }

}
resource "aws_volume_attachment" "vol_attachment" {
 device_name = "/dev/xvdc"      // device name has to start and be in sequence of xvd*
 volume_id = aws_ebs_volume.data-vol.id
 instance_id = aws_instance.testpublicinstance.id
}

