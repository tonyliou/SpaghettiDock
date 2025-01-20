#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or use sudo."
  exit 1
fi

# Add the current user to the docker group
USER_NAME=$(whoami)
if [ ! $(getent group docker) ]; then
  echo "Docker group does not exist. Creating docker group."
  groupadd docker
fi

echo "Adding $USER_NAME to the docker group."
usermod -aG docker $USER_NAME

# Adjust permissions for the Docker socket
echo "Adjusting permissions for /var/run/docker.sock."
chmod 660 /var/run/docker.sock
chown root:docker /var/run/docker.sock

# Notify the user to log out and log back in
cat <<EOF

Permissions have been updated.
Please log out and log back in to apply the changes, or run the following command to apply the group change immediately:

  newgrp docker

After logging back in, test Docker with:

  docker ps

EOF

exit 0
