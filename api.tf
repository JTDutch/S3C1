# ✅ API Server EC2
resource "aws_instance" "api_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.demo_key.key_name
  subnet_id                   = aws_subnet.demo_subnet.id
  vpc_security_group_ids      = [aws_security_group.api_sg.id]
  associate_public_ip_address = true

  user_data = base64encode(<<EOT
#!/bin/bash
set -e

# Update & install Apache, PHP, Docker
apt-get update -y
apt-get install -y apache2 php php-mysql curl unzip docker.io docker-compose

# ✅ Create API PHP file
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

# ✅ Enable & start Apache
systemctl enable apache2
systemctl start apache2

# ✅ Enable Docker
systemctl enable docker
systemctl start docker

# ✅ Setup Prometheus + Grafana stack
mkdir -p /opt/monitoring/grafana/provisioning/{datasources,dashboards}

cat > /opt/monitoring/docker-compose.yml <<'COMPOSE'
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    restart: always

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards
    restart: always

  node_exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    restart: always

volumes:
  grafana-storage:
COMPOSE

# ✅ Prometheus config
cat > /opt/monitoring/prometheus.yml <<'PROM'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
PROM

# ✅ Grafana datasource provisioning
cat > /opt/monitoring/grafana/provisioning/datasources/datasource.yml <<'DATASOURCE'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
DATASOURCE

# ✅ Grafana dashboard provisioning
cat > /opt/monitoring/grafana/provisioning/dashboards/dashboard.yml <<'DASH'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
DASH

# ✅ Example Node Exporter dashboard (minimal JSON)
cat > /opt/monitoring/grafana/provisioning/dashboards/node_exporter.json <<'DASHJSON'
{
  "id": null,
  "title": "Node Exporter Metrics",
  "tags": ["system"],
  "timezone": "browser",
  "schemaVersion": 16,
  "version": 1,
  "panels": [
    {
      "type": "graph",
      "title": "CPU Usage",
      "targets": [
        {
          "expr": "100 - (avg by (instance)(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
          "legendFormat": "CPU Usage"
        }
      ]
    },
    {
      "type": "graph",
      "title": "Memory Usage",
      "targets": [
        {
          "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
          "legendFormat": "Memory Usage"
        }
      ]
    }
  ]
}
DASHJSON

# ✅ Start monitoring stack
cd /opt/monitoring
docker-compose up -d
EOT
  )

  tags = {
    Name = "API-Server"
  }
}
