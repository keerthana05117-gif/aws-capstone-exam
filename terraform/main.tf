########################################
# Use existing VPC
########################################
data "aws_vpc" "existing_vpc" {
  id = "vpc-020bd8b493cde00e0"
}

########################################
# Use existing Web Security Group
########################################
data "aws_security_group" "web_sg" {
  name   = "web-firewall"
  vpc_id = data.aws_vpc.existing_vpc.id
}

########################################
# Public Subnets
########################################
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "streamline-public-${count.index}"
  }
}

########################################
# Private Subnets
########################################
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = data.aws_vpc.existing_vpc.id
  cidr_block        = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)

  tags = {
    Name = "streamline-private-${count.index}"
  }
}

########################################
# Internet Gateway
########################################
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.existing_vpc.id
}

########################################
# Public Route Table
########################################
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.existing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

########################################
# DB Security Group (NEW – Private)
########################################
resource "aws_security_group" "db_sg" {
  name   = "streamline-db-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# EC2 Instances
########################################
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[count.index].id
  key_name      = "25nov-lenovouser-off"

  vpc_security_group_ids = [
    data.aws_security_group.web_sg.id
  ]

  tags = {
    Name = "streamline-web-${count.index}"
  }
}

########################################
# Application Load Balancer
########################################
resource "aws_lb" "alb" {
  name               = "streamline-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [data.aws_security_group.web_sg.id]
}

resource "aws_lb_target_group" "tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing_vpc.id
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

########################################
# RDS (Private Subnets)
########################################
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "streamline-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password123"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}
