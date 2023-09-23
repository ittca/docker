#!/bin/bash

echo "This will create a new docker container with mariadb latest and a user as root"
read -p "want to continue press any key, to leave CTRL + C" RUN_SCRIPT

CONTAINER='mariadb'
# checking if the container name exists 
if [ "$(sudo docker ps -a -q -f name=$CONTAINER)" ]; then
  read -p "Container '$container' already exists. Do you want to (R)ename, (D)elete, or (Q)uit the script? [R/D/Q]: " choice
  case "$choice" in
    R|r)
      read -p "Enter a new container name: " new_name
      echo "Renaming the 'mariadb' container to '$new_name'..."
      $CONTAINER = "$new_name"
      ;;
    D|d)
      echo "Removing the '$CONTAINER' container..."
      sudo docker stop $CONTAINER
      sudo docker rm $CONTAINER
      ;;
    Q|q)
      echo "Exiting the script."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting the script."
      exit 1
      ;;
  esac
fi

# getting credentials
read -p "Database root user: " MDB_ROOT_USR
read -p "Database root password: " MDB_ROOT_PASS

# Pull the MariaDB image
sudo docker pull mariadb:latest

# Run the MariaDB container with secrets and environment variables
sudo docker run -d --name $CONTAINER \
  --network none \
  -e MARIADB_ROOT_PASSWORD=$MDB_ROOT_PASS \
  mariadb
for i in {1..6}; do
  if [ "$(sudo docker inspect -f '{{.State.Running}}' $CONTAINER)" = "true" ]; then
        echo "Container its running"
    break
  fi
  sleep 5
done

# Check if the container is running, and if not, print a message
if [ "$(sudo docker inspect -f '{{.State.Running}}' $CONTAINER)" != "true" ]; then
  echo "Container is not running."
else
  # Container is running, execute SQL commands
  sudo docker exec -it $CONTAINER apt update -y
  sudo docker exec -it $CONTAINER apt upgrade -y
  sudo docker exec -it $CONTAINER apt autoremove -y --purge
  sudo docker exec -it $CONTAINER apt install mariadb-client -y
  sudo docker exec -i $CONTAINER mariadb -u root -p"$MDB_ROOT_PASS" <<EOF
  RENAME USER 'root'@'localhost' TO '$MDB_ROOT_USR'@'localhost';
  exit
EOF
sudo docker exec -i $CONTAINER mariadb -u $MDB_ROOT_USR -p"$MDB_ROOT_PASS" <<EOF
  DROP USER 'root'@'%';
  exit
EOF
fi
