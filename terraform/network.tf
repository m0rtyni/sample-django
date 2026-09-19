resource "aws_vpc" "application_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

#################
#    Subnets    #
#################

resource "aws_subnet" "application_public_subnet_a" {
  vpc_id                  = aws_vpc.application_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "application_public_subnet_b" {
  vpc_id                  = aws_vpc.application_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-public-subnet-b"
    Environment = var.environment
  }
}

resource "aws_subnet" "application_private_subnet_a" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "${var.environment}-private-subnet-a"
    Environment = var.environment
  }
}

resource "aws_subnet" "application_private_subnet_b" {
  vpc_id            = aws_vpc.application_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "${var.environment}-private-subnet-b"
    Environment = var.environment
  }
}

####################
# Internet Gateway #
####################

resource "aws_internet_gateway" "application_igw" {
  vpc_id = aws_vpc.application_vpc.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "application_public_route_table" {
  vpc_id = aws_vpc.application_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.application_igw.id
  }

  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = var.environment
  }
}

###################
#   NAT Gateway   #
###################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "application_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.application_public_subnet_a.id

  depends_on = [aws_internet_gateway.application_igw]

  tags = {
    Name        = "${var.environment}-nat-gateway"
    Environment = var.environment
  }
}

resource "aws_route_table" "application_private_route_table" {
  vpc_id = aws_vpc.application_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.application_nat.id
  }

  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_subnet_a" {
  subnet_id      = aws_subnet.application_private_subnet_a.id
  route_table_id = aws_route_table.application_private_route_table.id
}

resource "aws_route_table_association" "private_subnet_b" {
  subnet_id      = aws_subnet.application_private_subnet_b.id
  route_table_id = aws_route_table.application_private_route_table.id
}

resource "aws_route_table_association" "public_subnet_a" {
  subnet_id      = aws_subnet.application_public_subnet_a.id
  route_table_id = aws_route_table.application_public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b" {
  subnet_id      = aws_subnet.application_public_subnet_b.id
  route_table_id = aws_route_table.application_public_route_table.id
}

####################
#  Security group  #
####################

resource "aws_security_group" "load_balancer_sg" {
  name        = "${var.environment}-load-balancer-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.application_vpc.id

  ingress {
    description = "Allow HTTP from the Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-load-balancer-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "application_sg" {
  name        = "${var.environment}-application-sg"
  description = "Security group for application EC2 instances"
  vpc_id      = aws_vpc.application_vpc.id

  ingress {
    description     = "Allow HTTP traffic from Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-application-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "database_sg" {
  name        = "${var.environment}-database-sg"
  description = "Security group for PostgreSQL EC2 instance"
  vpc_id      = aws_vpc.application_vpc.id

  ingress {
    description     = "Allow PostgreSQL traffic from application instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-database-sg"
    Environment = var.environment
  }
}

###################
#  Load Balancer  #
###################

resource "aws_lb" "application_load_balancer" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.load_balancer_sg.id]

  subnets = [aws_subnet.application_public_subnet_a.id, aws_subnet.application_public_subnet_b.id]

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "application_target_group" {
  name     = "${var.environment}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.application_vpc.id

  health_check {
    path                = "/accounts/login/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name        = "${var.environment}-target-group"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "application_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application_target_group.arn
  }
}
