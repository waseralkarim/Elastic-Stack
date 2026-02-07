# Elastic Stack Ansible Role

This Ansible role installs and configures Elasticsearch and Kibana on a single server (single-node setup).

## Requirements

- Ubuntu/Debian-based system
- Ansible 2.9 or higher
- Root/sudo access on target server

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Elasticsearch configuration
elasticsearch_cluster_name: "elasticsearch-demo"
elasticsearch_network_host: "0.0.0.0"
elasticsearch_http_port: 9200
elasticsearch_transport_host: "0.0.0.0"

# Elastic user password
elastic_password: "ChangeMe123!"

# Kibana configuration
kibana_port: 5601
kibana_host: "0.0.0.0"
kibana_elasticsearch_username: "kibana_system"
kibana_elasticsearch_password: "ChangeMe123!"
```

## Usage

### 1. Update inventory file

Edit `inventory.ini` with your server details:

```ini
[elastic_servers]
192.168.1.100 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### 2. Update passwords

Edit `example-playbook.yml` and change the default passwords:

```yaml
vars:
  elastic_password: "YourSecurePassword123!"
  kibana_elasticsearch_password: "YourKibanaPassword123!"
```

### 3. Run the playbook

```bash
ansible-playbook -i inventory.ini example-playbook.yml
```

## Post-Installation

### Access the services

- **Elasticsearch**: `https://<server-ip>:9200`
  - Username: `elastic`
  - Password: (value of `elastic_password` variable)

- **Kibana**: `http://<server-ip>:5601`
  - Username: `elastic`
  - Password: (value of `elastic_password` variable)

Wait 1-2 minutes after the playbook completes for Kibana to fully start, then access the web interface.

### Test Elasticsearch

```bash
curl --cacert /etc/elasticsearch/certs/http_ca.crt \
  -u elastic:YourSecurePassword123! \
  https://localhost:9200
```

## Directory Structure

```
elastic-stack-role/
├── defaults/
│   └── main.yml          # Default variables
├── handlers/
│   └── main.yml          # Service restart handlers
├── tasks/
│   └── main.yml          # Main installation tasks
├── templates/
│   ├── elasticsearch.yml.j2  # Elasticsearch config template
│   └── kibana.yml.j2         # Kibana config template
├── example-playbook.yml  # Example playbook
├── inventory.ini         # Example inventory
└── README.md            # This file
```

## Security Notes

1. **Change default passwords** - Never use the default passwords in production
2. **Firewall** - Configure firewall rules to restrict access to ports 9200 and 5601
3. **SSL/TLS** - Elasticsearch uses self-signed certificates by default. Consider using proper certificates for production
4. **Network binding** - The default configuration binds to `0.0.0.0` (all interfaces). Restrict this in production environments

## Troubleshooting

### Check service status

```bash
sudo systemctl status elasticsearch
sudo systemctl status kibana
```

### View logs

```bash
# Elasticsearch logs
sudo journalctl -u elasticsearch -f

# Kibana logs
sudo journalctl -u kibana -f
```

### Common issues

1. **"Cannot read existing Message Signing Key pair" Error**
   
   **Symptom**: Kibana logs or Elasticsearch logs show errors about message signing keys
   
   **Cause**: Encryption keys in Kibana configuration don't match or are corrupted
   
   **Solution**: Use the automated repair script:
   ```bash
   cd elastic-stack-role
   ./fix-kibana-encryption.sh YourElasticPassword123!
   ```
   
   This script will:
   - Stop Kibana
   - Clear Kibana indices from Elasticsearch
   - Generate fresh encryption keys
   - Update Kibana configuration
   - Restart Kibana
   
   **Manual alternative**:
   ```bash
   # Stop Kibana
   sudo systemctl stop kibana
   
   # Delete Kibana indices
   curl -k -u "elastic:YourPassword" -X DELETE "https://localhost:9200/.kibana*"
   curl -k -u "elastic:YourPassword" -X DELETE "https://localhost:9200/.reporting*"
   
   # Generate new keys and update /etc/kibana/kibana.yml manually
   sudo /usr/share/kibana/bin/kibana-encryption-keys generate --force
   
   # Copy the three keys to kibana.yml
   sudo vim /etc/kibana/kibana.yml
   
   # Start Kibana
   sudo systemctl start kibana
   ```

2. **Kibana can't connect to Elasticsearch - Authentication Error**
2. **Kibana can't connect to Elasticsearch - Authentication Error**
   
   **Symptom**: Kibana logs show `security_exception: unable to authenticate user [kibana_system]`
   
   **Cause**: The `kibana_system` password wasn't set properly during installation (this can happen if the playbook was interrupted or if you're fixing an existing installation)
   
   **Solution**: Manually reset the `kibana_system` password:
   ```bash
   sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u kibana_system
   ```
   When prompted:
   - Confirm: `y`
   - Enter password: Use the same password as `kibana_elasticsearch_password` in your playbook
   - Re-enter password: Same password again
   
   Then restart Kibana:
   ```bash
   sudo systemctl restart kibana
   ```
   
   Wait 1-2 minutes and check the logs:
   ```bash
   sudo journalctl -u kibana -f
   ```

3. **Port already in use**: Check if another service is using ports 9200 or 5601
   ```bash
   sudo netstat -tulpn | grep -E '9200|5601'
   ```

4. **SSL certificate errors**: Verify the CA certificate was copied correctly to `/etc/kibana/http_ca.crt`
   ```bash
   ls -l /etc/kibana/http_ca.crt
   ```

5. **Elasticsearch won't start**: Check available memory and disk space
   ```bash
   free -h
   df -h
   ```
   Elasticsearch requires at least 2GB of RAM to run properly.

6. **Playbook fails at password reset step**: Ensure `python3-pexpect` is installed
   ```bash
   sudo apt-get install python3-pexpect
   ```

## License

MIT

## Author

Created based on Elasticsearch and Kibana official documentation.
