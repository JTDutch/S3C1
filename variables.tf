

variable "region" {
  description = "Region"
  type        = string
  default     = "eu-central-1" 
}

// SSH key
variable "ssh_key" {
  description = "ssh_key"
  type        = string
}

// EC2
variable "EC2_image" {
  description = "EC2_image"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu*22.04*" 
}

// Security
variable "ssh_port" {
  description = "SSH Port"
  type        = number
  default     = 22
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to connect over SSH"
  type        = string
  default     = "0.0.0.0/0" # (for testing; in production restrict to your IP)
}

variable "http_port" {
  description = "Port for HTTP traffic"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Port for HTTPS traffic"
  type        = number
  default     = 443
}

// VPC
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  default     = "demo-vpc"
  type        = string
  description = "Name tag for the VPC"
}

// Subnet
variable "subnet_cidr" {
  default     = "10.0.1.0/24"
  type        = string
  description = "CIDR block for the subnet"
}

variable "subnet_cidr2" {
  default     = "10.0.2.0/24"
  type        = string
  description = "CIDR block for the subnet"
}

variable "az" {
  default     = "eu-central-1a"
  type        = string
  description = "Availability zone to deploy into"
}

variable "az2" {
  default     = "eu-central-1b"
  type        = string
  description = "Availability zone to deploy into"
}

variable "subnet_name" {
  default     = "demo-subnet"
  type        = string
  description = "Name tag for the subnet"
}

// Gateway 
variable "igw_name" {
  default     = "demo-igw"
  type        = string
  description = "Name tag for the Internet Gateway"
}

// Route table
variable "rt_name" {
  default     = "demo-rt"
  type        = string
  description = "Name tag for the Route Table"
}

// Instance
variable "instance_type" {
  default     = "t3.micro"
  type        = string
  description = "EC2 instance type"
}

variable "instance_name" {
  default     = "terraform-demo-server"
  type        = string
  description = "Tag name for the EC2 instance"
}

variable "web_message" {
  default     = "Hello from TEST12312312312"
  type        = string
  description = "Message to display on the webserver homepage"
}

// Database

variable "home_ip" {
  default     = "0.0.0.0/24"
  type        = string
  description = "Home IP address to connect to the database"
}

variable "db_user" {
  type        = string
  description = "Database username"
}

variable "db_password" {
  type        = string
  description = "Database username"
}

variable "db_name" {
  default     = "dbname"
  description = "Name of the database"
  type        = string
}
