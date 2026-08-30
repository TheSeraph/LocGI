#!/bin/bash

docker stop owui-mcpo-n8n
docker remove owui-mcpo-n8n
sudo docker run -d -it --name owui-mcpo-n8n -p 8000:8000 --restart=always \
 -e MCP_MODE=stdio \
 -e LOG_LEVEL=error \
 -e DISABLE_CONSOLE_OUTPUT=false \
 -e N8N_API_URL=172.17.0.1:5678 \
 -e N8N_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyOTdiNTI5Yi1mMDUwLTQ2MjgtODQ4Mi1mNDlkZGU4YzZmMGMiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzUzMDkzNjczLCJleHAiOjE3NTU2NjI0MDB9.kg2nNHR8RElMcBCRIxrpgAea1M6QFkOqDjFva2yrzms \
 ghcr.io/open-webui/mcpo:main -- npx n8n-mcp

