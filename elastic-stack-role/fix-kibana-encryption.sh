#!/bin/bash
# Script to fix "Cannot read existing Message Signing Key pair" error
# This clears Kibana indices and restarts the service

set -e

ELASTIC_PASSWORD="${1}"

if [ -z "$ELASTIC_PASSWORD" ]; then
    echo "Usage: $0 <elastic_password>"
    echo ""
    echo "This script fixes the 'Cannot read existing Message Signing Key pair' error"
    echo "by clearing Kibana indices and restarting the service with fresh encryption keys."
    exit 1
fi

echo "=== Kibana Encryption Key Repair Tool ==="
echo ""
echo "This will:"
echo "  1. Stop Kibana"
echo "  2. Delete Kibana indices from Elasticsearch"
echo "  3. Regenerate encryption keys"
echo "  4. Restart Kibana"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Stopping Kibana..."
sudo systemctl stop kibana

echo "Step 2: Deleting Kibana indices..."
curl -k -u "elastic:${ELASTIC_PASSWORD}" -X DELETE "https://localhost:9200/.kibana*" 2>/dev/null || true
curl -k -u "elastic:${ELASTIC_PASSWORD}" -X DELETE "https://localhost:9200/.reporting*" 2>/dev/null || true

echo ""
echo "Step 3: Generating new encryption keys..."
sudo rm -f /etc/kibana/.encryption_keys

# Generate new keys
sudo /usr/share/kibana/bin/kibana-encryption-keys generate --force > /tmp/kibana_keys.txt

# Extract keys
SAVED_OBJECTS_KEY=$(grep "encryptedSavedObjects" /tmp/kibana_keys.txt | awk '{print $NF}')
REPORTING_KEY=$(grep "reporting" /tmp/kibana_keys.txt | awk '{print $NF}')
SECURITY_KEY=$(grep "security" /tmp/kibana_keys.txt | awk '{print $NF}')

# Backup current config
sudo cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.backup.$(date +%s)

# Update kibana.yml with new keys
sudo sed -i "s/^xpack.encryptedSavedObjects.encryptionKey:.*/xpack.encryptedSavedObjects.encryptionKey: \"${SAVED_OBJECTS_KEY}\"/" /etc/kibana/kibana.yml
sudo sed -i "s/^xpack.reporting.encryptionKey:.*/xpack.reporting.encryptionKey: \"${REPORTING_KEY}\"/" /etc/kibana/kibana.yml
sudo sed -i "s/^xpack.security.encryptionKey:.*/xpack.security.encryptionKey: \"${SECURITY_KEY}\"/" /etc/kibana/kibana.yml

# Save keys for future reference
sudo bash -c "cat > /etc/kibana/.encryption_keys" <<EOF
saved_objects_key: ${SAVED_OBJECTS_KEY}
reporting_key: ${REPORTING_KEY}
security_key: ${SECURITY_KEY}
EOF
sudo chmod 600 /etc/kibana/.encryption_keys
sudo chown root:kibana /etc/kibana/.encryption_keys

rm -f /tmp/kibana_keys.txt

echo ""
echo "Step 4: Starting Kibana..."
sudo systemctl start kibana

echo ""
echo "=== Repair Complete ==="
echo ""
echo "Kibana is restarting with fresh encryption keys."
echo "Wait 1-2 minutes, then access: http://$(hostname -I | awk '{print $1}'):5601"
echo ""
echo "Check status with: sudo systemctl status kibana"
echo "View logs with: sudo journalctl -u kibana -f"
