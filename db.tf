# ✅ Subnet Group for RDS (use your existing public/private subnets)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "demo-db-subnet-group"
  subnet_ids = [aws_subnet.demo_subnet.id, aws_subnet.demo_subnet_b.id]

  tags = {
    Name = "demo-db-subnet-group"
  }
}

# ✅ RDS MySQL Instance
resource "aws_db_instance" "demo_db" {
  identifier              = "dbname"
  allocated_storage       = 20                        # 20GB (minimum for free tier)
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"             # free tier eligible (or db.t4g.micro if ARM supported)
  username                = var.db_user                   # change this!
  password                = var.db_password              # change this, use var if needed
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true                      # ⚠️ don't keep snapshot on destroy
  multi_az                = false                     # keep costs low
  publicly_accessible     = true                     # DB only reachable inside VPC
  storage_type            = "gp2"
  deletion_protection     = false

  tags = {
    Name = "dbname"
  }
}

# ✅ Output DB endpoint
output "db_endpoint" {
  value = aws_db_instance.demo_db.endpoint
}
