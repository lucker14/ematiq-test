# Fluent Bit Quickstart

## What is Fluent Bit?

Fluent Bit is a lightweight log forwarder designed for high-performance log collection and shipping. It runs as a small agent on servers, containers, or Kubernetes nodes, reads log files or streams, and forwards data to destinations such as Loki.

## Why use Fluent Bit here?

- Low CPU/memory overhead
- Supports many inputs: tail files, syslog, journald, Docker logs, Kubernetes logs
- Supports many outputs: Loki, Elasticsearch, Splunk, Kafka
- Works well in ECS via AWS FireLens
- Can run on EC2 and remote hosts
- Good for 5TB/day if configured with batching and backpressure

## How it works in this project

### EC2 log collection

On EC2, a Fluent Bit agent is installed in user data. It reads log files such as:
- `/var/log/syslog`
- `/var/log/app/*.log`

It then sends those logs to Loki using the `loki` output plugin.

### AWS ECS collection with FireLens

FireLens is the AWS integration layer that lets ECS tasks send logs from container stdout/stderr through Fluent Bit. The application container uses `logDriver = awsfirelens`, and the log router container runs `amazon/aws-for-fluent-bit`.

### External servers and Kubernetes

For external servers, install Fluent Bit and point it to the Loki HTTP push endpoint.
For Kubernetes, use a Fluent Bit DaemonSet and configure the Loki output plugin.

## Basic Fluent Bit concepts

- `INPUT`: where logs come from (files, syslog, Docker, Kubernetes)
- `FILTER`: optional processing and enrichment
- `OUTPUT`: where logs are sent (Loki in this design)
- `PARSER`: how log lines are structured (JSON, regex, syslog)

## Example EC2 Fluent Bit configuration

```ini
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

[OUTPUT]
    Name   loki
    Match  *
    url    http://<loki-endpoint>:3100/loki/api/v1/push
    labels {"instance_id":"i-12345","env":"dev"}
```

## What is FireLens?

FireLens is a log routing feature for ECS tasks. It uses Fluent Bit or Fluentd behind the scenes. When you configure a container with `awsfirelens`, ECS forwards logs into a Fluent Bit router container.

### In practice

- Application container writes logs to stdout/stderr
- ECS forwards those logs to FireLens
- FireLens router container sends them to Loki

This means your app does not need to know anything about Loki; only the task definition is updated.
