# Official Kibana SSL/HTTPS Configuration on Port 443

## Based on Elastic Official Documentation

This guide follows the official Elasticsearch/Kibana documentation for configuring HTTPS directly on Kibana using your custom domain certificates.

## Step 1: Prepare Your Certificates

You need:

- **Certificate file**: `your-domain.crt` (or `.pem`)
- **Private key file**: `your-domain.key`
- **CA certificate** (optional but recommended)

Copy them to Kibana's certs directory:

```jsx
# Create certs directory
sudo mkdir -p /etc/kibana/certs

# Copy your certificates (adjust paths as needed)
sudo cp /path/to/your-domain.crt /etc/kibana/certs/server.crt
sudo cp /path/to/your-domain.key /etc/kibana/certs/server.key

# If you have a CA bundle
sudo cp /path/to/ca-bundle.crt /etc/kibana/certs/ca.crt

# Set permissions
sudo chown -R root:kibana /etc/kibana/certs
sudo chmod 640 /etc/kibana/certs/server.key
sudo chmod 644 /etc/kibana/certs/server.crt
```

## Step 2: Configure Kibana for HTTPS

Edit `/etc/kibana/kibana.yml`:

```jsx
sudo vim /etc/kibana/kibana.yml
```

Add or modify these settings:

```jsx
# Server configuration
server.port: 443
server.host: "0.0.0.0"
server.name: "kibana.your-domain.com"

# Enable HTTPS
server.ssl.enabled: true
server.ssl.certificate: /etc/kibana/certs/server.crt
server.ssl.key: /etc/kibana/certs/server.key

# Optional: If you have a CA certificate
# server.ssl.certificateAuthorities: [ "/etc/kibana/certs/ca.crt" ]

# Optional: Supported TLS protocols (recommended for security)
# server.ssl.supportedProtocols: [ "TLSv1.2", "TLSv1.3" ]

# Optional: Cipher suites (for enhanced security)
# server.ssl.cipherSuites: [ "TLS_AES_256_GCM_SHA384", "TLS_AES_128_GCM_SHA256" ]

# Elasticsearch connection (keep existing)
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "YOUR_KIBANA_SYSTEM_PASSWORD"
elasticsearch.ssl.certificateAuthorities: [ "/etc/kibana/http_ca.crt" ]
elasticsearch.ssl.verificationMode: certificate

# Encryption keys (keep your existing keys)
xpack.encryptedSavedObjects.encryptionKey: "YOUR_ENCRYPTION_KEY"
xpack.reporting.encryptionKey: "YOUR_REPORTING_KEY"
xpack.security.encryptionKey: "YOUR_SECURITY_KEY"

# Public URL (important for proper URL generation)
server.publicBaseUrl: "https://kibana.your-domain.com"
```

## Step 3: Allow Kibana to Bind to Port 443

Since Kibana runs as a non-root user and port 443 is privileged, you need to grant permission:

```jsx
sudo setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/bin/node
```

**Verify the capability was set:**

```jsx
getcap /usr/share/kibana/node/bin/node
# Should output: /usr/share/kibana/node/bin/node = cap_net_bind_service+ep
```

**Note**: This capability may be reset when Kibana is upgraded. You'll need to reapply it after upgrades.

The Node.js binary path has changed in newer Kibana versions. Here's how to find it:

```jsx
find /usr/share/kibana -name "node" -type f -executable
```

This will show you the exact path. For Kibana 9.x, it's likely:
```
/usr/share/kibana/node/glibc-217/bin/node
```

Then set the capability:

```jsx
sudo setcap 'cap_net_bind_service=+ep' /usr/share/kibana/node/glibc-217/bin/node
```

## Better Solution - Use systemd (Recommended)

This method is more reliable and persists across upgrades:

```jsx
# Create override directory
sudo mkdir -p /etc/systemd/system/kibana.service.d/

# Create override configuration
sudo tee /etc/systemd/system/kibana.service.d/override.conf << 'EOF'
[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
EOF

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart kibana
```

## Step 4: Configure Firewall

Allow HTTPS traffic on port 443:

```jsx
# UFW
sudo ufw allow 443/tcp
sudo ufw allow 443

# iptables
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

## Step 5: Restart Kibana

```jsx
sudo systemctl restart kibana
```

**Check status:**

```jsx
sudo systemctl status kibana
```

**Monitor logs:**

```jsx
sudo journalctl -u kibana -f
```

Look for:

- `http server running at https://0.0.0.0:443`
- No SSL/certificate errors

## Step 6: Verify HTTPS Access

Wait 1-2 minutes for Kibana to fully start, then test:

```jsx
# From the server
curl -k https://localhost:443

# Check certificate
openssl s_client -connect localhost:443 -servername kibana.your-domain.com
```

Access from browser:
```
https://kibana.your-domain.com
```
