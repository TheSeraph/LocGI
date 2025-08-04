#Requires -RunAsAdministrator

# Fetching common installation variables from ollama-variables.ps1
. ./ollama-variables.ps1

Get-Service -Name $serviceName | Start-Service
VBoxManage startvm $VMname --type headless
