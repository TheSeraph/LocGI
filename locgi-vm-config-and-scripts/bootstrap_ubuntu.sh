#!/bin/bash

# Colors
RED="\033[0;31m"
YELLOW="\033[33m"
GREEN="\033[0;32m"
RESET="\033[0m"

echo -e "${GREEN}Starting Bootstrap Script for Ubuntu Server${RESET}"

# Root check
if ! id | grep -q uid=0; then
    echo -e "${RED}FAILURE: you need to be root${RESET}"
    exit 1
fi

# 1. Update and Upgrade
echo -e "${YELLOW}Updating and upgrading system packages...${RESET}"
apt update && apt upgrade -y

# 2. Install Docker
echo -e "${YELLOW}Installing Docker...${RESET}"
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Install Nginx and Certbot
echo -e "${YELLOW}Installing Nginx and Certbot...${RESET}"
apt install -y nginx certbot python3-certbot-nginx

# 4. Configure User Inputs
read -p "Enter your domain name (e.g., example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domain name is required.${RESET}"
    exit 1
fi
read -p "Enter your email address for Let's Encrypt: " EMAIL

# 5. Setup Docker Containers
echo -e "${YELLOW}Setting up Docker containers...${RESET}"

# Qdrant
read -p "Enter Qdrant API Key: " QDRANT_API_KEY
if [ -z "$QDRANT_API_KEY" ]; then
    echo -e "${YELLOW}No API Key provided, continuing with empty key...${RESET}"
fi
docker pull qdrant/qdrant
docker run -d --name qdrant -p 6333:6333 -p 6334:6334 --restart=always \
  -e QDRANT__SERVICE__API_KEY=$QDRANT_API_KEY \
  -v qdrant_storage:/data \
  qdrant/qdrant

# n8n
# Use /n8n/ as the path so it works nicely with the reverse proxy
read -p "Enter desired hostname for n8n (default: $DOMAIN): " N8N_HOSTNAME
N8N_HOSTNAME=${N8N_HOSTNAME:-$DOMAIN}

docker pull docker.n8n.io/n8nio/n8n
docker run -d --name n8n -p 5678:5678 --restart=always \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_PROTOCOL=https \
  -e N8N_PATH=/n8n/ \
  -e N8N_HOST=$N8N_HOSTNAME \
  -e N8N_ENDPOINT_REST=rest \
  -e WEBHOOK_URL=https://$N8N_HOSTNAME/n8n/ \
  -v n8n_data:/home/node/.n8n \
  -v n8n_shellplay:/home/node/shell \
  docker.n8n.io/n8nio/n8n

# Searxng
echo -e "${YELLOW}Pulling and starting SearXNG...${RESET}"
docker pull searxng/searxng
docker run -d --name searxng -p 4000:8080 --restart always searxng/searxng

# OpenWebUI (on port 8080)
read -p "Enter Ollama Base URL (default: http://127.0.0.1:11434): " OLLAMA_URL
OLLAMA_URL=${OLLAMA_URL:-http://127.0.0.1:11434}
docker pull ghcr.io/open-webui/open-webui:main
docker run -d -p 8080:8080 -e OLLAMA_BASE_URL=$OLLAMA_URL -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

# 6. Obtain SSL Certificates
echo -e "${YELLOW}Obtaining SSL certificates via Certbot...${RESET}"
# We run certbot in certonly mode to get the certs without it taking over the config immediately.
certbot certonly --nginx --non-interactive --agree-tos -m $EMAIL -d $DOMAIN

if [ $? -ne 0 ]; then
    echo -e "${RED}Certbot failed. Please check your DNS and firewall settings.${RESET}"
    exit 1
fi

# 7. Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${RESET}"

cat <<EOF > /etc/nginx/sites-available/locgi_config
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN;

    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers   on;
    
    ssl_dhparam /etc/ssl/dhparam.pem;
    
    add_header X-Frame-Options DENY;
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    proxy_connect_timeout   600;
    proxy_send_timeout      600;
    proxy_read_timeout      600;
    proxy_set_header Host \$http_host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header Upgrade \$http_upgrade;
    send_timeout            600;
    client_max_body_size    2G;
    proxy_buffering off;
    client_header_buffer_size 8k;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # OpenWebUI (on port 8080)
    location / {
        proxy_pass http://127.0.0.1:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
    }

    # n8n (on port 5678)
    location /n8n/ {
        proxy_pass http://127.0.0.1:5678/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
    }

    # Qdrant (on port 6333)
    location /qdrant/ {
        proxy_pass http://127.0.0.1:6333/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
    }

    # Searxng (on port 4000)
    location /searx/ {
        proxy_pass http://127.0.0.1:4000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
    }
}
EOF

# Create symlink if it doesn't exist
ln -sf /etc/nginx/sites-available/locgi_config /etc/nginx/sites-enabled/
# Remove default nginx site if it exists
rm -f /etc/nginx/sites-enabled/default

# Generate DH params if they don't exist
if [ ! -f /etc/ssl/dhparam.pem ]; then
    echo -e "${YELLOW}Generating DH parameters (this may take a while)...${RESET}"
    openssl dhparam -out /etc/ssl/dhparam.pem 2048
fi

# Test and restart Nginx
nginx -t && systemctl restart nginx

echo -e "${GREEN}Bootstrap completed successfully!${RESET}"
echo -e "Your services should be available at: https://$DOMAIN"
echo -e " - OpenWebUI: https://$DOMAIN/"
echo -e " - n8n: https://$DOMAIN/n8n/"
echo -e " - Qdrant: https://$DOMAIN/qdrant/"
echo -e " - Searxng: https://$DOMAIN/searx/"
