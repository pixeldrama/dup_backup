#!/bin/bash

# the hardcoded key for the encrypted backup.
export PASSPHRASE=""

# backup path, which determines also the protocol
BACKUP_PATH=""

# path for log file
LOG_FILE=""

# noise in the log value: 0-9
LEVEL=4

function backup() {

    DATE=$(date)
    # echo "NOTICE 1 started backup ${DATE}" >> $LOG_FILE

    # in fact do the backup
    duplicity \
	--full-if-older-than 2W \
	--verbosity $LEVEL \
	--log-file $LOG_FILE \
	/home/$USER/ $BACKUP_PATH

    # remove very old backups
    duplicity remove-older-than 6M \
	--verbosity $LEVEL \
	--force \
	--log-file $LOG_FILE \
	$BACKUP_PATH

    #clean up
    duplicity cleanup --force 	--log-file $LOG_FILE $BACKUP_PATH 

    DATE=$(date)
    # echo "NOTICE 1 finished backup ${DATE}" >> $LOG_FILE
}

case "$1" in
start)

	#create log path?
	if [ ! -e "$LOG_FILE" ]
	then
	    sudo mkdir -p "$LOG_FILE"
	fi

	# check if an instance of duplicity is running
	PID_DUPLICITY=$(pgrep duplicity)
	if [ "$PID_DUPLICITY" != "" ]
	then
	    echo "duplicity is already running under ${PID_DUPLICITY}"
	    exit 1
	fi


	# check if somebody is at home
	IS_LOGGED=$(who | grep $USER)
	if [ "$IS_LOGGED" != "" ]
	then
	    echo "start backup"
	    backup
	    echo "backup finished"
	    exit 0
	else
	    echo "${user} is not logged in"
	    exit 1
	fi
	;;
list)
	duplicity collection-status  --log-file $LOG_FILE $BACKUP_PATH	
	;;
    *)
	
	# print the message into the log file
	echo "usage: start|list" >> $LOG_FILE

	# print the messag to stdout
	echo "usage: start|list"
	;;
esac
