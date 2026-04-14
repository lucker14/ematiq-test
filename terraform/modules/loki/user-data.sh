#!/bin/bash
set -e

COMPONENT="${component}"
AWS_REGION="${aws_region}"
AWS_ACCOUNT_ID="${aws_account_id}"
ENVIRONMENT="${environment}"
RETENTION_DAYS="${retention_days}"
RETENTION_HOURS="$((RETENTION_DAYS * 24))"

# Install Docker
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Create directories
mkdir -p /etc/loki
mkdir -p /var/lib/loki

# Write Loki config
cat > /etc/loki/config.yml << EOF
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: memberlist
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 3m
  max_chunk_age: 1h
  chunk_retain_period: 15m
  max_streams_per_user: 10000
  chunk_target_size: 1048576
  chunk_encoding: snappy

distributor:
  ring:
    kvstore:
      store: memberlist

memberlist:
  join_members:
    - loki-distributor.internal:7946
    - loki-ingester.internal:7946
    - loki-querier.internal:7946

schema_config:
  configs:
  - from: 2020-10-24
    store: boltdb-shipper
    object_store: s3
    schema: v11
    index:
      prefix: loki_index_
      period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /var/lib/loki/index
    cache_location: /var/lib/loki/cache
    cache_ttl: 24h
    shared_store: s3
  aws:
    s3: s3://loki-logs-$AWS_ACCOUNT_ID-$ENVIRONMENT
    region: $AWS_REGION
  index_queries_cache_config:
    memcached:
      batch_size: 100
      parallelism: 10

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: $${RETENTION_HOURS}h

limits_config:
  retention_period: $${RETENTION_HOURS}h
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  max_cache_freshness_per_query: 10m
  split_queries_by_interval: 15m

query_scheduler:
  max_outstanding_requests_per_tenant: 100

frontend:
  max_outstanding_per_tenant: 100

ruler:
  storage:
    type: local
    local:
      directory: /etc/loki/rules
  rule_path: /etc/loki/rules-temp
  alertmanager_url: ""
  external_url: ""
EOF

# Set component-specific config
if [ "$COMPONENT" = "distributor" ]; then
  sed -i 's/target: all/target: distributor/' /etc/loki/config.yml
elif [ "$COMPONENT" = "ingester" ]; then
  sed -i 's/target: all/target: ingester/' /etc/loki/config.yml
elif [ "$COMPONENT" = "querier" ]; then
  sed -i 's/target: all/target: querier/' /etc/loki/config.yml
fi

# Install Loki
wget https://github.com/grafana/loki/releases/download/v2.9.1/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki
chmod +x /usr/local/bin/loki

# Create systemd service
cat > /etc/systemd/system/loki.service << EOF
[Unit]
Description=Loki
Wants=network-online.target
After=network-online.target

[Service]
User=root
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start loki
systemctl enable loki