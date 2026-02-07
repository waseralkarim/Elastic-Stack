#!/bin/bash
# Post-installation script to set kibana_system password
# Run this on the Elasticsearch server after the Ansible playbook completes

set -e

KIBANA_PASSWORD="${1}"

if [ -z "$KIBANA_PASSWORD" ]; then
    echo "Usage: $0 <kibana_system_password>"
    echo "Example: $0 YourKibanaPassword123!"
    exit 1
fi

echo "Setting kibana_system password..."
echo "$KIBANA_PASSWORD" | sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u kibana_system -b

echo ""
echo "Password set successfully!"
echo "Now restart Kibana:"
echo "  sudo systemctl restart kibana"
echo ""
echo "Wait a minute, then access Kibana at: http://$(hostname -I | awk '{print $1}'):5601"
