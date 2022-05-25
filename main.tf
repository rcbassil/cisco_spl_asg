provider "aws" {
  profile = "personal"
  region  = var.aws_region
}

resource "aws_vpc" "cisco_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "cisco_test"
  }
}


resource "aws_subnet" "pub_sub1" {
  vpc_id                  = "${aws_vpc.cisco_vpc.id}"
  cidr_block              = var.pub_sub1_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "pub_sub2" {
  vpc_id                  = "${aws_vpc.cisco_vpc.id}"
  cidr_block              = var.pub_sub2_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.az2

  tags = {
    Name = "public_subnet_2"
  }
}


resource "aws_subnet" "prv_sub1" {
  vpc_id                  = "${aws_vpc.cisco_vpc.id}"
  cidr_block              = var.prv_sub1_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = var.az1

  tags = {
    Name = "private_subnet_1"
  }
}

resource "aws_subnet" "prv_sub2" {
  vpc_id                  = "${aws_vpc.cisco_vpc.id}"
  cidr_block              = var.prv_sub2_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = var.az2

  tags = {
    Name = "private_subnet_2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.cisco_vpc.id}"

  tags = {
    Name = "cisco_test_ig"
  }
}

resource "aws_route_table" "pub_sub1_r" {
  vpc_id = "${aws_vpc.cisco_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "public_aws_route_table"
  }
}


resource "aws_route_table_association" "internet_for_pub_sub1" {
  subnet_id      = "${aws_subnet.pub_sub1.id}"
  route_table_id = "${aws_route_table.pub_sub1_r.id}"
}

resource "aws_route_table_association" "internet_for_pub_sub2" {
  subnet_id      = "${aws_subnet.pub_sub2.id}"
  route_table_id = "${aws_route_table.pub_sub1_r.id}"
}

# Default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "web_sg" {
  name        = "instance_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.cisco_vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
    security_groups = [
      "${aws_security_group.elb.id}",
    ]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elb security group to access
# the ELB over HTTP
resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"

  vpc_id = "${aws_vpc.cisco_vpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = [aws_internet_gateway.gw]
}

# NAT EIPs
resource "aws_eip" "nat_eip1" {
  vpc   = true
  count = "1"

  tags = {
    Name = "nat_eip1"
  }
}

resource "aws_eip" "nat_eip2" {
  vpc   = true
  count = "1"

  tags = {
    Name = "nat_eip2"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw1" {
  allocation_id = element(aws_eip.nat_eip1.*.id, count.index)
  subnet_id     = element(aws_subnet.pub_sub1.*.id, count.index)
  count = "1" 
  tags = {
    Name = "nat_gw1"
  }
}

resource "aws_nat_gateway" "nat_gw2" {
  allocation_id = element(aws_eip.nat_eip2.*.id, count.index)
  subnet_id     = element(aws_subnet.pub_sub2.*.id, count.index)
  count = "1"

  tags = {
    Name = "nat_gw2"
  }
}

resource "aws_route_table" "private_rt1" {
  vpc_id = aws_vpc.cisco_vpc.id
  count  = length(aws_nat_gateway.nat_gw1)

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw1.*.id, count.index)
  }

  tags = {
    Name = "private_rt_1"
  }
}


resource "aws_route_table" "private_rt2" {
  vpc_id = aws_vpc.cisco_vpc.id
  count  = length(aws_nat_gateway.nat_gw2)

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw2.*.id, count.index)
  }

  tags = {
    Name = "private_rt2"
  }
}


# private subnet route table associations
resource "aws_route_table_association" "private_sub1_natgw1" {
  subnet_id      = element(aws_subnet.prv_sub1.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt1.*.id, count.index)
  count = "1"
}

# private subnet route table associations
resource "aws_route_table_association" "private_sub2_natgw2" {
  subnet_id      = element(aws_subnet.prv_sub2.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt2.*.id, count.index)
  count = "1"
}


resource "aws_launch_configuration" "webserver-launch-config" {
  name_prefix   = "webserver-launch-config"
  image_id      =  "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  key_name = var.key_name
  security_groups = ["${aws_security_group.web_sg.id}"]
 
  lifecycle {
    create_before_destroy = true
  } 
  
  user_data = "${file("userdata.sh")}"
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "Demo-ASG-tf" {
  name       = "Demo-ASG-tf"
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  force_delete       = true
  depends_on         = [aws_lb.ALB-tf]
  target_group_arns  =  ["${aws_lb_target_group.TG-tf.arn}"]
  health_check_type  = "EC2"
  launch_configuration = aws_launch_configuration.webserver-launch-config.name
  vpc_zone_identifier = ["${aws_subnet.prv_sub1.id}","${aws_subnet.prv_sub2.id}"]
  
 tag {
       key                 = "Name"
       value               = "Demo-ASG-tf"
       propagate_at_launch = true
    }
}

# Create Target group
resource "aws_lb_target_group" "TG-tf" {
  name     = "Demo-TargetGroup-tf"
  depends_on = [aws_vpc.cisco_vpc]
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.cisco_vpc.id}"
  health_check {
    interval            = 70
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60 
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}

# Create ALB
resource "aws_lb" "ALB-tf" {
  name              = "Demo-ALG-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups  = [aws_security_group.elb.id]
  subnets          = [aws_subnet.pub_sub1.id,aws_subnet.pub_sub2.id]       
  tags = {
        name  = "Demo-AppLoadBalancer-tf"
        Project = "demo-assignment"
       }
}


# Create ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ALB-tf.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-tf.arn
  }
}
