#!/bin/bash

# the hardcoded key for the encrypted backup.
export PASSPHRASE=""

# backup path, which determines also the protocol
BACKUP_PATH=""

# path of log file
LOG_PATH=/home/$USER/.local/log/

# name of log file
LOG_FILE=duplicity.log

LOG=$LOG_PATH/$LOG_FILE

# noise in the log value: 0-9
LEVEL=4

function backup() {

    DATE=$(date)
    # echo "NOTICE 1 started backup ${DATE}" >> $LOG_FILE

    # in fact do the backup
    duplicity \
	--no-encryption \
	--full-if-older-than 2W \
	--verbosity $LEVEL \
	--log-file $LOG \
	/home/$USER/ $BACKUP_PATH

    # remove very old backups
    duplicity remove-older-than 6M \
	--verbosity $LEVEL \
	--force \
	--log-file $LOG \
	$BACKUP_PATH

    #clean up
    duplicity cleanup --force --log-file $LOG $BACKUP_PATH

    DATE=$(date)
    # echo "NOTICE 1 finished backup ${DATE}" >> $LOG_FILE
}

function log() {
   echo $1
   echo $1 >> $LOG
}

#create log path?
if [ ! -e "$LOG_FILE" ]
then
    mkdir -p $LOG_PATH
    cd $LOG_PATH
    touch $LOG_FILE
    cd $HOME
    log "created log path $LOG_FILE"
fi

case "$1" in
start)

	# check if an instance of duplicity is running
	PID_DUPLICITY=$(pgrep duplicity)
	if [ "$PID_DUPLICITY" != "" ]
	then
	    log "duplicity is already running under ${PID_DUPLICITY}"
	    exit 1
	fi


	# delete logfile
	LOCK_FILE=$(find "/home/$USER/.cache/duplicity/" -type f -name "lockfile.lock")

	if [ "$LOCK_FILE" != "" ]
	then
	    log "delete $LOCK_FILE"
	    rm $LOCK_FILE
	fi

	# check if somebody is at home
	IS_LOGGED=$(who | grep $USER)
	if [ "$IS_LOGGED" != "" ]
	then
	    log "start backup"
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
	
	log "usage: start|list"
	;;
esac
