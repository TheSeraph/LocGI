#!/bin/bash

# Script to set environment variables and generate new keys/passwords if requested.
# This script will output a .sh file containing the environment variables.

# Define the variables to be set
VARIABLES=(
  "API_KEY"
  "API_HOST"
  "DATABASE_HOST"
  "DATABASE_USER"
  "DATABASE_PASSWORD"
  "SOME_IP_ADDRESS"
)

# Function to generate a random API key
generate_api_key() {
  openssl rand -base64 32
}

# Function to generate a random password (more secure than just `date +%s`)
generate_password() {
  openssl rand -base64 20
}


# Function to get a variable value from the user, with optional key generation
get_variable_value() {
  local var_name=$1
  local prompt="$var_name: "
  local value=""

  if [[ "$var_name" == "API_KEY" || "$var_name" == "DATABASE_PASSWORD" ]]; then
    read -p "$prompt (generate new? y/n): " generate_option
    if [[ "$generate_option" == "y" || "$generate_option" == "Y" ]]; then
      if [[ "$var_name" == "API_KEY" ]]; then
        value=$(generate_api_key)
      else
        value=$(generate_password)
      fi
      echo "Generated new $var_name: $value"
    else
      read -s -p "$prompt" value # -s for silent input (no echo)
      echo # Add a newline after silent input
    fi
  else
    read -p "$prompt" value
  fi

  echo "$value"
}

# Create a .sh file to store the environment variables
output_file="env_vars.sh"
echo "#!/bin/bash" > "$output_file"
echo "# Environment variables set by script" >> "$output_file"

# Loop through the variables and get values from the user
for var in "${VARIABLES[@]}"; do
  value=$(get_variable_value "$var")
  echo "export $var=\"$value\"" >> "$output_file"
done

echo "Environment variables written to $output_file"
echo "Make sure to make the file executable: chmod +x $output_file"

exit 0