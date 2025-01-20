#!/bin/bash
# Ubuntu sc
umask 077

# Colours
RED="\033[0;31m"
YELLOW="\033[33m"
GREEN="\033[0;32m"
RESET="\033[0m"

# Hostname configuration
# hostname="myhost.mydomain.com"

echo "This script is intended to install or update an n8n docker container so that it can operate"
echo "behind an nginx reverse proxy with TLS enabled, in a domain with other applications and" 
echo "specifically in the /n8n path. For example at https://myhost.mydomain.com/n8n/."

# Root or admin check
if ! id |grep -q uid=0; then
    echo -e "${RED}FAILURE: you need to be root${RESET}"
    exit 1
fi

# Check if hostname is configured
if [ -z "$hostname" ]; then
  # do something (x)
	echo ""
	echo -e "${YELLOW}A hostname hasn't been set for n8n. You can fix this issue by modifying $hostname"
	echo -e "in this bash script with your hostname. Otherwise, you can enter a hostname manually"
	echo -e "now (e.g. myhost.mydomain.com)${RESET}"
	read hostname
	echo ""
else
	echo ""
	echo "Hostname "$hostname" has been pre-configured in the script"
	echo ""
fi

echo ""
echo "Pulling latest version."
echo "This may take a couple minutes."
echo ""

# Pull latest (stable) version
docker pull docker.n8n.io/n8nio/n8n


# Stop and remove any previous containers (but not their data)
docker stop n8n
docker remove n8n
docker run -d -it --name n8n -p 5678:5678 --restart=always \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_PROTOCOL=https \
  -e N8N_PATH=/n8n/ \
  -e N8N_HOST=$hostname \
  -e N8N_ENDPOINT_REST=rest \
  -e WEBHOOK_URL=https://$hostname/n8n/ \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n

docker ps


