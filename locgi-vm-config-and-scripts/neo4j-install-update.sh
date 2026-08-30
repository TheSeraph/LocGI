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

echo "This script is intended to install or update an neo4j docker container so that it can operate"
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
docker pull neo4j


# Stop and remove any previous containers (but not their data)# Stop and remove any previous containers (but not their data)
docker stop neo4j
docker remove neo4j

# Start up OpenWebUI container
docker run -d -it --name neo4j --publish=7474:7474 --publish=7687:7687  --volume=$HOME/neo4j/data:/data --env NEO4J_AUTH=neo4j/iajOyA6CNdC3iFCze4iP --restart always neo4j
docker ps
