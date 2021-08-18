terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc_01"{
  cidr_block = var.base_cidr_block
}

resource "aws_subnet" "vpc_subnets" {
  count = length(var.subnet_ids)

  vpc_id     		  = aws_vpc.vpc_01.id
  cidr_block              = var.subnet_ids[count.index]
  availability_zone	  = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw_01" {
  vpc_id = aws_vpc.vpc_01.id
}

resource "aws_route_table" "internet_gw" {
  vpc_id = aws_vpc.vpc_01.id
  
  route = [
    {
      cidr_block  		 = "0.0.0.0/0"
      gateway_id 		 = aws_internet_gateway.igw_01.id 

      #The paremeters listed below are required to be set
      #Otherwise terraform fails
      carrier_gateway_id 	 = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id 	 = ""
      instance_id 		 = ""
      ipv6_cidr_block 		 = ""
      local_gateway_id 		 = ""
      nat_gateway_id 		 = ""
      network_interface_id 	 = ""
      transit_gateway_id 	 = ""
      vpc_endpoint_id 		 = ""
      vpc_peering_connection_id  = ""
    }
  ]

  tags = {
    Name = "internet_gw"
  }
}

resource "aws_route_table_association" "rt_association" {
  count = length(aws_subnet.vpc_subnets)

  subnet_id      = aws_subnet.vpc_subnets[count.index].id
  route_table_id = aws_route_table.internet_gw.id
}

resource "aws_network_acl" "nacl_az1" {
  vpc_id = aws_vpc.vpc_01.id

  subnet_ids = [aws_subnet.vpc_subnets[0].id]

  egress = [
    {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[0].cidr_block
      from_port  = 80
      to_port    = 80

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    },
    {
      protocol   = "tcp"
      rule_no    = 110
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[0].cidr_block
      from_port  = 443
      to_port    = 443

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    },
     #Allow subnets in this NACL to act as clients (i.e. send TCP packets from ephemeral TCP port range)
    {
      protocol   = "tcp"
      rule_no    = 120
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    }
  ]

  ingress = [
    {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[0].cidr_block
      from_port  = 80
      to_port    = 80
      
      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    },
    {
      protocol   = "tcp"
      rule_no    = 110
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[0].cidr_block
      from_port  = 443
      to_port    = 443

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    }
  ]

  tags = {
    Name = "nacl_az1"
  }
}

resource "aws_network_acl" "nacl_az2" {
  vpc_id = aws_vpc.vpc_01.id

  subnet_ids = [aws_subnet.vpc_subnets[1].id]

  egress = [
    {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[1].cidr_block
      from_port  = 80
      to_port    = 80

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    },
    {
      protocol   = "tcp"
      rule_no    = 110
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[1].cidr_block
      from_port  = 443
      to_port    = 443

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    },
     #Allow subnets in this NACL to act as clients (i.e. send TCP packets from ephemeral TCP port range)
    {
      protocol   = "tcp"
      rule_no    = 120
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    }
  ]

  ingress = [
    {
      protocol   = "tcp"
      rule_no    = 100
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[1].cidr_block
      from_port  = 80
      to_port    = 80
      
      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    },
    {
      protocol   = "tcp"
      rule_no    = 110
      action     = "allow"
      cidr_block = aws_subnet.vpc_subnets[1].cidr_block
      from_port  = 443
      to_port    = 443

      #These vars must be initialized
      #Otherwise it fails
      icmp_code       = 0
      icmp_type       = 0
      ipv6_cidr_block = ""
    }
  ]

  tags = {
    Name = "nacl_az2"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH on default SSH port 22"
  vpc_id      = aws_vpc.vpc_01.id

  ingress =[
    {
      description      = "SSH to the instance"
      protocol         = "tcp"
      from_port        = 22
      to_port          = 22
      cidr_blocks      = [aws_vpc.vpc_01.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
  
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow HTTP/HTTPS access"
  vpc_id      = aws_vpc.vpc_01.id

  ingress =[
    {
      description = "HTTP to the instance"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    },
    {
      description = "HTTPS to the instance"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    }
  ]
}

resource "aws_security_group" "allow_egress_all" {
  name        = "allow_egress_all"
  description = "Allow outbound traffic to all destinations"
  vpc_id      =  aws_vpc.vpc_01.id

  egress = [
    {
      description      = "Allow all outbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = true
   
    }
  ]
}
resource "aws_instance" "web" {
  count	= length(aws_subnet.vpc_subnets)

  ami		= "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.micro"
  subnet_id	= aws_subnet.vpc_subnets[count.index].id
 
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_web.id, aws_security_group.allow_egress_all.id]
  tags = {
    Name = "Web ${count.index}"
  }
}