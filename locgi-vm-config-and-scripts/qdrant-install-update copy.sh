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
# QDRANT__SERVICE__API_KEY=""

echo "This script is intended to install or update an qdrant docker container so that it can operate"
echo "behind an nginx reverse proxy with TLS enabled, in a domain with other applications and"
echo "specifically in the /qdrant path. For example at https://myhost.mydomain.com/qdrant/."

# Root or admin check
if ! id |grep -q uid=0; then
    echo -e "${RED}FAILURE: you need to be root${RESET}"
    exit 1
fi

# Check if hostname is configured
if [ -z "$QDRANT__SERVICE__API_KEY" ]; then
  # do something (x)
        echo ""
        echo -e "${YELLOW}An API key  hasn't been set for qdrant. You can fix this issue by modifying $QDRANT__SERVICE__API_KEY"
        echo -e "in this bash script with your hostname. Otherwise, you can enter one manually now"
        read QDRANT__SERVICE__API_KEY
        echo ""
else
        echo ""
        echo "API Key "$QDRANT__SERVICE__API_KEY" has been pre-configured in the script"
        echo ""
fi

echo ""
echo "Pulling latest version."
echo "This may take a couple minutes."
echo ""

# Pull latest (stable) version
docker pull qdrant/qdrant


# Stop and remove any previous containers (but not their data)
docker stop qdrant
docker remove qdrant
docker run -d -it --name qdrant -p 6333:6333 -p 6334:6334 --restart=always \
  -e QDRANT__SERVICE__API_KEY=$QDRANT__SERVICE__API_KEY \
  -v ./qdrant_storage:/data \
  qdrant/qdrant

docker ps