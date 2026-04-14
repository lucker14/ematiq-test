#!/bin/bash
set -e

LOKI_ENDPOINT="${loki_endpoint}"

# Install Docker
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Run Grafana
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana:latest

# Wait for Grafana to start
sleep 30

# Configure Loki data source via API
cat > /tmp/grafana-datasource.json <<EOF
{
  "name": "Loki",
  "type": "loki",
  "url": "http://$LOKI_ENDPOINT:3100",
  "access": "proxy",
  "isDefault": true
}
EOF

curl -X POST \
  -H "Content-Type: application/json" \
  -d @/tmp/grafana-datasource.json \
  http://admin:admin123@localhost:3000/api/datasources