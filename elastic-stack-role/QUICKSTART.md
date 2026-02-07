# Quick Start Guide

## Prerequisites

1. Ubuntu/Debian server with sudo access
2. Ansible installed on your control machine
3. SSH access to the target server

## Installation Steps

### Step 1: Clone or copy this role

```bash
# Copy the elastic-stack-role directory to your Ansible roles path
cp -r elastic-stack-role /path/to/your/ansible/roles/
```

### Step 2: Configure inventory

Edit `inventory.ini`:

```ini
[elastic_servers]
YOUR_SERVER_IP ansible_user=YOUR_USERNAME ansible_ssh_private_key_file=/path/to/key
```

### Step 3: Set passwords

Edit `example-playbook.yml` and set secure passwords:

```yaml
vars:
  elastic_password: "YourStrongPassword123!"
  kibana_elasticsearch_password: "YourStrongPassword123!"
```

### Step 4: Run the playbook

```bash
ansible-playbook -i inventory.ini example-playbook.yml
```

This will:
- Install Elasticsearch and Kibana
- Configure both services
- Set passwords for elastic and kibana_system users
- Start the services automatically

### Step 5: Access Kibana

Wait about 1-2 minutes for Kibana to fully start, then open:

```
http://YOUR_SERVER_IP:5601
```

Login with:
- Username: `elastic`
- Password: (the value of `elastic_password` from your playbook)

## Verification

Test Elasticsearch:

```bash
curl --cacert /etc/elasticsearch/certs/http_ca.crt \
  -u elastic:YourStrongPassword123! \
  https://localhost:9200
```

You should see JSON output with cluster information.

## Troubleshooting

### "Cannot read existing Message Signing Key pair" Error

If you see this error in Kibana or Elasticsearch logs, it means the encryption keys are corrupted or mismatched.

**Quick Fix:**
```bash
cd elastic-stack-role
./fix-kibana-encryption.sh YourElasticPassword123!
```

This automated script will fix the issue by regenerating fresh encryption keys.

### Kibana Authentication Error

If Kibana logs show authentication errors like:
```
security_exception: unable to authenticate user [kibana_system]
```

**Fix it manually:**

1. SSH to your server
2. Reset the kibana_system password:
   ```bash
   sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u kibana_system
   ```
3. When prompted:
   - Confirm: `y`
   - Enter password: Same as `kibana_elasticsearch_password` in your playbook
   - Re-enter: Same password again

4. Restart Kibana:
   ```bash
   sudo systemctl restart kibana
   ```

5. Wait 1-2 minutes and check if it's working:
   ```bash
   sudo journalctl -u kibana -f
   ```

### Other Common Issues

**Kibana shows "Kibana server is not ready yet":**
- Wait 2-3 minutes for Kibana to start
- Check logs: `sudo journalctl -u kibana -f`
- Verify kibana_system password was set correctly (see above)

**Can't access the web interface:**
- Check firewall: `sudo ufw status`
- Allow ports if needed: `sudo ufw allow 5601`
- Verify service is running: `sudo systemctl status kibana`

**Elasticsearch not starting:**
- Check memory: `free -h` (needs at least 2GB RAM)
- Check disk space: `df -h`
- View logs: `sudo journalctl -u elasticsearch -f`

## What's Next?

- Configure Fleet in Kibana for agent management
- Set up index patterns and dashboards
- Configure data ingestion
- Review security settings
- Set up proper SSL certificates for production use

## Security Reminders

- Change all default passwords
- Restrict network access with firewall rules
- Use proper SSL/TLS certificates in production
- Regularly update Elasticsearch and Kibana
- Enable audit logging for compliance
