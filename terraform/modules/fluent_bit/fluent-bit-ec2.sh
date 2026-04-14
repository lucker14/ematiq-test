#!/bin/bash
set -e

LOKI_ENDPOINT="${loki_endpoint}"
ENVIRONMENT="${environment}"
INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Install Fluent Bit
curl https://packages.fluentbit.io/fluentbit.key | gpg --import -
rpm -Uvh https://packages.fluentbit.io/amazon/linux/2/fluent-bit-2.1.0-1.amzn2.x86_64.rpm

# Create Fluent Bit configuration
cat > /etc/fluent-bit/fluent-bit.conf << EOF
[SERVICE]
    Flush         5
    Daemon        on
    Log_Level     info
    Parsers_File  parsers.conf

[INPUT]
    Name          tail
    Path          /var/log/syslog
    Parser        syslog
    Tag           syslog.system
    Refresh_Interval 5

[INPUT]
    Name          tail
    Path          /var/log/app/*.log
    Parser        json
    Tag           app.all
    Refresh_Interval 5

[OUTPUT]
    Name   loki
    Match  *
    url    http://$LOKI_ENDPOINT:3100/loki/api/v1/push
    labels {"instance_id":"$INSTANCE_ID","env":"$ENVIRONMENT","hostname":"%H"}
    remove_keys docker_id,source
    buffer_size 32k
    retry_limit 5
EOF

# Create parsers file
cat > /etc/fluent-bit/parsers.conf << 'EOF'
[PARSER]
    Name        json
    Format      json
    Time_Key    timestamp
    Time_Format %Y-%m-%dT%H:%M:%S.%LZ

[PARSER]
    Name        syslog
    Format      regex
    Regex       ^(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$
    Time_Key    time
    Time_Format %b %d %H:%M:%S
EOF

# Start Fluent Bit
systemctl start fluent-bit
systemctl enable fluent-bit