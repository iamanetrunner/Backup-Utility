#!/bin/bash -x

# Note: Public Key of key pair must be copied into the remote machine in order to run scripted connections with SSH which is the case with this backup script

# Required env variables: REMOTE_WEB_SERVER_USER, REMOTE_WEB_SERVER_IP, DESTINATION_OWNER

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]
then
  echo "Error: All arguments are mandatory. Follow the syntax: backup-utility [REMOTE_WEB_SERVER_USER] [REMOTE_WEB_SERVER_IP] [DESTINATION_OWNER] [PRIVATE_KEY_FILE]"
  exit
fi

REMOTE_WEB_SERVER_USER="$1"
REMOTE_WEB_SERVER_IP="$2"
DESTINATION_OWNER="$3"
PRIVATE_KEY_FILE="$4"

REMOTE_SOURCE="$REMOTE_WEB_SERVER_USER@$REMOTE_WEB_SERVER_IP:/home/$REMOTE_WEB_SERVER_USER/web_server/*"
DESTINATION="/home/$DESTINATION_OWNER/web_server_backup"

TAR_FILE_TEMPLATE="$DESTINATION/backup_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz"

# Using rsync to transfer files. The same command can be used to delete files at source by adding --remove-source-files
TRANSFERED_FILES=$(rsync -e "ssh -i $HOME/.ssh/$PRIVATE_KEY_FILE" -avz "$REMOTE_SOURCE" "$DESTINATION" | head -n -2 | tail -n +2 | xargs)

tar cvzf "$TAR_FILE_TEMPLATE" -C "$DESTINATION" $TRANSFERED_FILES --remove-files

# Error checking
if [ $? -eq 0 ]; then
  echo "Security backup succesfully completed at $DESTINATION directory"
else
  echo "Error present during backup."
  FILES_TO_REMOVE=$(echo $TRANSFERED_FILES | xargs printf -- "$DESTINATION/%s ")

  echo "attempting to remove brought files"
  rm $FILES_TO_REMOVE
fi
