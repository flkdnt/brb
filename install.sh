#!/bin/bash

#########################
#     Functions
#########################
function check_dependencies() {
  if ! command -v rsync &> /dev/null
  then
      echo "rsync is not installed"
      exit 1
  fi
  
  if ! command -v rclone &> /dev/null
  then
      echo "rclone is not installed"
      exit 1
  fi
  
  if ! command -v yq &> /dev/null
  then
      echo "yq is not installed"
      exit 1
  fi
}

function install_services() {
  # Create Service files and service link
  services=("brb${user_id}.service" "brb${user_id}.timer")
  for item in"${services[@]}"; do
    # Create File
    if [ ! -d "${svc_folder}/${item}" ]; then
      cp "Source/$item" "${svc_folder}/${item}"
      chmod 754 "${svc_folder}/${item}"
    fi
    # Create Services Link
    if [ ! -d "/etc/systemd/user/${item}" ]; then
      sudo ln -s "${svc_folder}/${item}" "/etc/systemd/user/${item}"
      sudo chown $USERNAME:$USERNAME "${svc_folder}/${item}"
      chmod 754 "${svc_folder}/${item}"
    fi
  done

  # Edit Service File with user home directory
  sed "s|USER_HOME_DIRECTORY|$HOME|g" "${svc_folder}/brb${user_id}.service"

  # Enable brb services
  systemctl enable --user "brb${user_id}.service"
  systemctl start --user "brb${user_id}.service"
  systemctl enable --user "brb${user_id}.timer"

  # Print brb service info
  echo "brb service successfully created"
  systemctl list-unit-files --user | grep brb
}

#########################
#    Installer Start
#########################

user_id=$(id -u $(whoami))
config_folder="${HOME}/.brb"
svc_folder="${HOME}/.config/systemd/user/"
configfile="${config_folder}/backups.yaml"

check_dependencies

# Create Program folder if it doesn't exist
if [ ! -d "$config_folder" ]; then
  mkdir $config_folder
fi

# Create Config file if it doesn't exist
if [ ! -d "$configfile" ]; then
  touch $configfile
fi

# Copy Program files
installers=(scheduler.sh timekeeper.sh)
for item in"${installers[@]}"; do
  if [ ! -d "${config_folder}/${item}" ]; then
    cp "Source/$item" "${config_folder}/${item}"
  fi
done

# Change file permissions for config folder
chmod -R 754 $config_folder

install_services
