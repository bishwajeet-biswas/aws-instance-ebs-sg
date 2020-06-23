provider "aws" {
  alias                   = "north"
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/creds"
  profile                 = "jeet-terraform"
}

provider "aws" {
  alias                   = "ohio"
  region                  = "us-east-2"
  shared_credentials_file = "~/.aws/creds"
  profile                 = "jeet-terraform"
}

module "vpc" {
  source            = "./vpc"
  providers = {
    aws   = aws.north
  }
  vpc_name          = "vpc-terraform"
  cidr_vpc          = "10.10.0.0/16"
  environment_tag   = "terraform"
  cidr_pub          = "10.10.1.0/24"
  az                = "us-east-1a"
  igw_name          = "testigw"
}


module "instance" {
  source            = "./instance"
  providers = {
  aws               = aws.north
  }
  provider_alias    = "north-virginia"
  vpc_name          = module.vpc.vpc_id_created
  subnet_public     = module.vpc.public_subnet_id_created
  environment_tag   = "terraform"
  sg_bastion        = "ssh-sg"
  bastion_name      = "bastion-server"
  keypair_name      = "ec2-pair"
  ami_name          = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  public_key_path   = "~/.ssh/id_rsa_jeet.pub"
  root_vol_size     = "20"
  root_vol_type     = "gp2"
  data1_vol_size    = "50"
  data1_vol_type    = "gp2"
  data2_vol_zone    = "us-east-1a"
  data2_vol_size    = 30
  data2_vol_type    = "gp2"
}
