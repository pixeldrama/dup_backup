#!/bin/bash

export PASSPHRASE=<passphrase>
USER=<unix user>
BACKUP_PATH=<path>
LOG_FILE=<path to logging file>
LEVEL=4

function backup() {

    DATE=$(date)
    echo "NOTICE 1 started backup ${DATE}" >> $LOG_FILE

    # in fact do the backup
    duplicity \
        --log-file $LOG_FILE \
        --full-if-older-than 2W \
        --verbosity $LEVEL \
        # --exclude=/home/$USER/.gvfs \ 
    /home/$USER/ $BACKUP_PATH

    # remove very old backups
    duplicity remove-older-than 6M \
        --verbosity $LEVEL \
        --force \
        $BACKUP_PATH

    #clean up
    duplicity cleanup --force $BACKUP_PATH

    DATE=$(date)
    echo "NOTICE 1 finished backup ${DATE}" >> $LOG_FILE
}

# check if an instance of duplicity is running
PID_DUPLICITY=$(pgrep duplicity)
if [ "$PID_DUPLICITY" != "" ]
then
    notify-send "duplicity is already running under ${PID_DUPLICITY}"
    exit 1
fi

# check, if backup directory is mounted
MOUNT_DIR=$(mount | grep ${BACKUP_PATH##*///})
if [ "$MOUNT_DIR" = "" ]
then
    notify-send "try to mount $MOUNT_DIR"

    mount -av
    MOUNT_DIR=$(mount | grep ${BACKUP_PATH##*///})    

    if [ "$MOUNT_DIR" = "" ]
    then
        notify-send "mounting $MOUNT_DIR failed"
        exit 1
    fi
fi

# check if somebody is at home
IS_LOGGED=$(who | grep $USER)
if [ "$IS_LOGGED" != "" ]
then
    notify-send "start backup"
    backup
    notify-send "backup finished"
    exit 0
else
    echo "${user} is not logged in"
    exit 1
fi
