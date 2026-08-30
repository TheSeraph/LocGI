#!/bin/bash
# Ubuntu script

umask 077

# Colours
RED="\033[0;31m"
YELLOW="\033[33m"
GREEN="\033[0;32m"
RESET="\033[0m"

# Configuration
h_port="4001" # Default port to use (avoiding 4000 if in use)
skills_dir="$(pwd)/hermes-skills" # Local directory for skills, located in a subdirectory of the repo

# Ensure permissions and directories exist
if [ ! -d "$skills_dir" ]; then
    echo -e "${YELLOW}Creating skills directory: $skills/skills_dir${RESET}"
    mkdir -p "$skills_dir"
fi

echo "This script is intended to install or update a Hermes docker container."
echo "It maps port $h_port to the container's default port and mounts '$skills_dir' for skills."

# Root or admin check
if ! id |grep -q uid=0; then
    echo -e "${RED}FAILURE: you need to be root${RESET}"
    exit 1
fi

echo ""
echo "Pulling latest version of Hermes container..."
echo "This may take a couple minutes."
echo ""

# NOTE: Replace 'hermes-agent:latest' with the actual image name if it is known.
IMAGE_NAME="hermes-agent:latest" 

# Pull latest version
docker pull $IMAGE_NAME

# Stop and remove any previous containers (but not their data)
docker stop hermes 2>/dev/null
docker remove hermes 2>/dev/null

# Start up Hermes container
# We assume the container listens on port 4000 internally.
# We map it to $h_port.
docker run -d \
  -p ${h_port}:4000 \
  -v "${skills_dir}:/app/backend/skills" \
  --name hermes \
  --restart always \
  $IMAGE_NAME

echo ""
echo -e "${GREEN}Hermes container is running on port $h_port${RESET}"
echo "Skills are being loaded from: $skills_dir"
echo ""
docker ps | grep hermes
