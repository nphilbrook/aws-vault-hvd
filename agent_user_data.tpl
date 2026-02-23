#!/bin/bash

dnf install -y git awscli docker

cat <<'EOF' > /usr/local/bin/tfc-agent-wrapper
#!/bin/bash

set -e

SECRET_DATA=$(aws secretsmanager get-secret-value --secret-id vault-lab-tfc-agent-tokne)

export TFC_AGENT_TOKEN=$(echo $SECRET_DATA | jq -r .SecretString)
export TFC_AGENT_NAME=$(hostname)-$1
export TFC_AGENT_AUTO_UPDATE=disabled
# Current as of 2026-02-21
export VERSION=1.28.3
docker run -e TFC_AGENT_TOKEN -e TFC_AGENT_NAME -e TFC_AGENT_AUTO_UPDATE docker.io/hashicorp/tfc-agent:$VERSION
EOF

chmod 775 /usr/local/bin/tfc-agent-wrapper

cat <<EOF > /etc/systemd/system/tfc-agent@.service
[Unit]
Description=HCP Terraform Agent
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/tfc-agent-wrapper %I
Restart=always
RestartSec=10

# The systemd journal by default collects all the STDOUT logs from the container started in the script,
# hence omitting the script's standard output here. Maintaining STDERR for debugging
StandardOutput=null
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

for i in $(seq 0 ${num_agents - 1})
do
    sudo systemctl enable tfc-agent@$i.service
    sudo systemctl start tfc-agent@$i.service
done
