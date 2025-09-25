# ========================
# ALB Security Group (allow HTTP/HTTPS from internet)
# ========================
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP/HTTPS from internet to ALB"
  vpc_id      = aws_vpc.demo_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ALB-SG" }
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = var.http_port
  to_port           = var.http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  from_port         = var.https_port
  to_port           = var.https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# ========================
# SSH Security Group
# ========================
resource "aws_security_group" "port_22" {
  name        = "allow_port_22"
  description = "Allows SSH traffic"
  vpc_id      = aws_vpc.demo_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "AllowPort22SG" }
}

resource "aws_security_group_rule" "ssh_in" {
  type              = "ingress"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_cidr]
  security_group_id = aws_security_group.port_22.id
}

# ========================
# Web Security Group
# ========================
resource "aws_security_group" "web_sg" {
  name        = "allow_http_https"
  description = "Allows HTTP/HTTPS traffic from ALB"
  vpc_id      = aws_vpc.demo_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "AllowWebSG" }
}

resource "aws_security_group_rule" "web_http" {
  type                     = "ingress"
  from_port                = var.http_port
  to_port                  = var.http_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "web_https" {
  type                     = "ingress"
  from_port                = var.https_port
  to_port                  = var.https_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# ========================
# API Server Security Group
# ========================
resource "aws_security_group" "api_sg" {
  name        = "api-sg"
  description = "Allow HTTP from webservers"
  vpc_id      = aws_vpc.demo_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "API-SG" }
}

resource "aws_security_group_rule" "api_http_from_web" {
  type                     = "ingress"
  from_port                = var.http_port
  to_port                  = var.http_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_sg.id
  source_security_group_id = aws_security_group.web_sg.id
}

# Allow HTTP from home IP to API server
resource "aws_security_group_rule" "api_http_from_home" {
  type              = "ingress"
  from_port         = 80              # HTTP port
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.home_ip]   # your home IP in CIDR format, e.g., "77.251.14.120/32"
  security_group_id = aws_security_group.api_sg.id
}

# Allow HTTP from home IP to API server
resource "aws_security_group_rule" "api_ssh_from_home" {
  type              = "ingress"
  from_port         = 22              # HTTP port
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.home_ip]   # your home IP in CIDR format, e.g., "77.251.14.120/32"
  security_group_id = aws_security_group.api_sg.id
}


# ========================
# Database Security Group
# ========================
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL access from API server and home IP"
  vpc_id      = aws_vpc.demo_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "DB-SG" }
}

# DB ingress from API (use API subnet CIDR to avoid circular reference)
resource "aws_security_group_rule" "db_mysql_from_api" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.demo_subnet.cidr_block]
  security_group_id = aws_security_group.db_sg.id
}

# DB ingress from home IP
resource "aws_security_group_rule" "db_mysql_from_home" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.home_ip]
  security_group_id = aws_security_group.db_sg.id
}
