#!/bin/bash
# Test script for log ingestion

LOKI_ENDPOINT=$1

if [ -z "$LOKI_ENDPOINT" ]; then
    echo "Usage: $0 <loki-endpoint>"
    exit 1
fi

echo "Testing log ingestion to $LOKI_ENDPOINT..."

# Test log message
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [{
      "stream": {"job": "test", "env": "test"},
      "values": [["'$(date +%s%N)'", "Test log message from deployment script"]]
    }]
  }' \
  http://$LOKI_ENDPOINT:3100/loki/api/v1/push

if [ $? -eq 0 ]; then
    echo "Test log sent successfully!"
else
    echo "Failed to send test log."
    exit 1
fi