# ✅ API Server EC2
resource "aws_instance" "api_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = aws_key_pair.demo_key.key_name
  subnet_id               = aws_subnet.demo_subnet.id
  vpc_security_group_ids  = [aws_security_group.api_sg.id]
  associate_public_ip_address = true

  user_data = base64encode(<<EOT
#!/bin/bash
# Install Apache & PHP
apt-get update -y
apt-get install -y apache2 php php-mysql curl unzip

# Create API PHP file
cat <<'EOF' > /var/www/html/api.php
<?php
header('Content-Type: application/json');

$servername = "${aws_db_instance.demo_db.endpoint}";
$port       = "${aws_db_instance.demo_db.port}";
$username   = "${var.db_user}";
$password   = "${var.db_password}";
$dbname     = "${var.db_name}";

$conn = new mysqli($servername, $username, $password, $dbname, $port);

if ($conn->connect_error) {
    die(json_encode(["error" => "Connection failed: " . $conn->connect_error]));
}

if (isset($_GET['action']) && $_GET['action'] === 'get_all') {
    $result = $conn->query("SELECT * FROM users");
    $rows = [];
    while($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    echo json_encode($rows);
}

$conn->close();
?>
EOF

# Start Apache
systemctl enable apache2
systemctl start apache2
EOT
  )

  tags = {
    Name = "API-Server"
  }
}
