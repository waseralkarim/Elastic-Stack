# Elasticsearch SSL/TLS Custom Certificate Configuration

## Overview

This guide covers updating Elasticsearch HTTP SSL from the default auto-generated PKCS12 keystore (`http.p12`) to a custom wildcard certificate issued by a trusted CA.

**Note:** Only the HTTP SSL layer is changed. The transport SSL (node-to-node) remains on `transport.p12`.

## Prerequisites

- Elasticsearch 9.x installed and running
- Certificate files already available at `/etc/kibana/certs/` (`server.crt` with full CA chain + `server.key`)
- Certificate issuer: your trusted CA (e.g. Sectigo, Let's Encrypt, etc.)
- DNS resolution for `kibana.your-domain.com` pointing to the server

## Current Configuration (Before Change)

```jsx
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12
```

## Step 1: Copy Certificates to Elasticsearch

```jsx
sudo cp /etc/kibana/certs/server.crt /etc/elasticsearch/certs/server.crt
sudo cp /etc/kibana/certs/server.key /etc/elasticsearch/certs/server.key
```

Set proper ownership and permissions:

```jsx
sudo chown root:elasticsearch /etc/elasticsearch/certs/server.crt
sudo chown root:elasticsearch /etc/elasticsearch/certs/server.key
sudo chmod 640 /etc/elasticsearch/certs/server.key
sudo chmod 644 /etc/elasticsearch/certs/server.crt
```

## Step 2: Update elasticsearch.yml

```jsx
sudo vim /etc/elasticsearch/elasticsearch.yml
```

Replace the HTTP SSL block from:

```jsx
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12
```

To:

```jsx
xpack.security.http.ssl:
  enabled: true
  certificate: /etc/elasticsearch/certs/server.crt
  key: /etc/elasticsearch/certs/server.key
```

**Important:** Do NOT modify the `xpack.security.transport.ssl` section.

Full `elasticsearch.yml` after change:

```jsx
cluster.name: YOUR_CLUSTER_NAME
node.name: YOUR_NODE_NAME
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
transport.host: 0.0.0.0
discovery.type: single-node

xpack.security.enabled: true
xpack.security.enrollment.enabled: true

xpack.security.http.ssl:
  enabled: true
  certificate: /etc/elasticsearch/certs/server.crt
  key: /etc/elasticsearch/certs/server.key

xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
```

## Step 3: Restart & Verify

```jsx
sudo systemctl restart elasticsearch.service
sudo systemctl status elasticsearch.service
```

Check logs:

```jsx
sudo journalctl -u elasticsearch -f
```

Verify with domain name:

```jsx
curl -u elastic:$ELASTIC_PASSWORD https://kibana.your-domain.com:9200
```

For local testing (localhost won't match the cert SAN):

```jsx
curl -k -u elastic:$ELASTIC_PASSWORD https://localhost:9200
```

Expected response:

```jsx
{
  "name": "YOUR_NODE_NAME",
  "cluster_name": "YOUR_CLUSTER_NAME",
  "cluster_uuid": "YOUR_CLUSTER_UUID",
  "version": {
    "number": "9.x.x"
  },
  "tagline": "You Know, for Search"
}
```

## Troubleshooting

**"no alternative certificate subject name matches target host name 'localhost'"** — Expected. A wildcard cert for your domain won't cover `localhost`. Use the domain name or `curl -k` for local tests.

**Elasticsearch fails to start** — Check file permissions (`server.key` must be `640`, owned by `root:elasticsearch`) and verify YAML indentation.

**Reverting to original** — Restore the HTTP SSL block to `keystore.path: certs/http.p12` and restart.

```jsx
sudo journalctl -u elasticsearch --no-pager -n 100
```
