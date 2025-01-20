#!/bin/bash
# Ubuntu sc
umask 077

# Colours
RED="\033[0;31m"
YELLOW="\033[33m"
GREEN="\033[0;32m"
RESET="\033[0m"

# Ollama Base URL configuration
# o_url="http://192.168.1.1:11434"

echo "This script is intended to install or update an OpenWeb UI docker container so that it can operate"
echo "on port 8080, behind an nginx reverse proxy with TLS enabled."  

# Root or admin check
if ! id |grep -q uid=0; then
    echo -e "${RED}FAILURE: you need to be root${RESET}"
    exit 1
fi

# Ollama URL check
if [ -z "$hostname" ]; then
  # do something (x)
        echo ""
        echo -e "${YELLOW}The ollama base URL hasn't been specified. You can fix this issue by modifying o_url variable"
        echo -e "in this bash script with your ollama url. Otherwise, you can enter a url manually"
        echo -e "now (e.g. http://192.168.1.1:11434)${RESET}"
        read o_url
        echo ""
else
        echo ""
        echo "Ollama base URL "$o_url" has been pre-configured in the script"
        echo ""
fi

echo ""
echo "Pulling latest version."
echo "This may take a couple minutes."
echo ""

# Pull latest (stable) version
docker pull ghcr.io/open-webui/open-webui:main


# Stop and remove any previous containers (but not their data)# Stop and remove any previous containers (but not their data)
docker stop open-webui
docker remove open-webui

# Start up OpenWebUI container
docker run -d -p 8080:8080 -e OLLAMA_BASE_URL=$o_url -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
docker ps
