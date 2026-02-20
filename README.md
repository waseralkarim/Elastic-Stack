<img width="1920" height="1080" alt="1" src="https://github.com/user-attachments/assets/6b9c954a-e16f-4b70-b64e-4ccdca807f24" />

# Elastic Stack

The **Elastic Stack** is the open source platform that powers search, observability, security, and more. Build with Elasticsearch.

## Overview

The Elastic Stack (formerly ELK Stack) is a powerful collection of open-source products designed for search, logging, security analytics, and business intelligence. This repository provides comprehensive setup guides and deployment strategies for all Elastic Stack components.

## Setup Instructions

- First choose which deployment method you want to use (Kubernetes/Docker/Bare-Metal)
- All methods require proper configuration of Elasticsearch, Kibana, and optionally Logstash and Beats
- You can start with a single-node setup and scale to multi-node clusters as needed

## Table of Contents

1. [Elasticsearch Setup](01-elasticsearch-installation.md)
2. [Kibana Deployment](02-kibana-installation.md)
3. [FileBeat Installation](03-filebeat-installation.md)
4. [Kibana SSL/HTTPS Setup](04-kibana-ssl-https.md)
5. [ElasticSearch SSL/HTTPS Setup](05-elasticsearch-ssl-tls.md) 

## Quick Start

### Prerequisites

- Java 11+ (bundled with Elasticsearch 7.0+)
- 4GB+ RAM (8GB+ recommended)
- 2GB+ free disk space

### Docker Compose (Recommended for Testing)

```bash
# Clone the repository
git clone https://github.com/waseralkarim/Elastic-Stack.git
cd Elastic-Stack

# Start the stack
docker-compose up -d

# Access Kibana
# Open http://localhost:5601 in your browser
```
