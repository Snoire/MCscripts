#! /bin/zsh

#Settings
SERVICE='bedrock_server'
SCREENNAME='mc'
MCUSER='mc'
#WORLD='survival'
MCPATH='/home/mc/minecraft'
#BACKUPPATH=$MCPATH/worlds.backup
INVOCATION="./bedrock_server"

as_user() {
    if [[ $USERNAME == $MCUSER ]] {
        zsh -c "$1"
    } else {
        su - "$MCUSER" -c "$1"
    }
}

mc_start() {
    if { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        echo "$SERVICE is already running!"
    } else {
        echo "Starting $SERVICE..."
        cd $MCPATH
        as_user "screen -L -Logfile logs/minecraft.log -dmS ${SCREENNAME} $INVOCATION"

        local count=1
        while ! { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
            if (( count > 6 )) {
                echo "Error! Could not start $SERVICE!"
                return
            }
            (( count++ ))
            sleep 1
        }
        echo "$SERVICE is now running."
    }
}

mc_stop() {
    if { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        echo "Stopping $SERVICE..."
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS...\"\015'"
        sleep 5
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 5 SECONDS...\"\015'"
        sleep 2
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 3 SECONDS...\"\015'"
        sleep 1
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 2 SECONDS...\"\015'"
        sleep 1
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 1 SECONDS...\"\015'"
        sleep 1
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say stop...\"\015'"
        as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"stop\"\015'"
    } else {
        echo "$SERVICE was not running."
        return
    }

    local count=1
    while { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        if (( count > 6 )) {
            as_user "screen -S ${SCREENNAME} -X quit"
            echo "Error! $SERVICE could not be stopped. Close screen manually."
            break
        }
        (( count++ ))
        sleep 1
    }
    mc_log
    echo "$SERVICE is stopped."
}

mc_log() {
    cd $MCPATH/logs
    sed -i '/Running AutoCompaction/d' minecraft.log
    mv minecraft.log $(date "+%y%m%d_%H%M%S").log

    all_logs=(<->_<->.log(N))
    new_logs=(<->_<->.log(om[1,32]N))
    rm -vf ${all_logs:|new_logs}
}

mc_backup() {
    NOW=$(date "+%y%m%d_%H%M%S")
    BACKUP_FILE="$MCPATH/worlds.backup/survival_${NOW}.mcworld"

    echo "Backing up minecraft world..."
    cd $MCPATH/worlds/survival-1
    zip -rq $BACKUP_FILE *

    echo "Removing all backups except for the latest three files..."
    cd $MCPATH/worlds.backup
    all_backups=(survival_<->_<->.mcworld(N))
    new_backups=(survival_<->_<->.mcworld(om[1,3]N))
    rm -vf ${all_backups:|new_backups}

    echo "Done."
}

mc_cloudbak() {
    cd $MCPATH/worlds.backup
    BACKUPFILE=(survival_<->_<->.mcworld(m-9om[1]N))

    if (( $#BACKUPFILE == 1 )) {
        dav $BACKUPFILE
    }
}

mc_command() {
    command="$1";
    lines1=${$(wc -l $MCPATH/logs/minecraft.log)[1]}
    echo "$command"
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"$command\"\015'"

    local count=1
    local lines2=$lines1
    while [[ $lines2 == $lines1 ]] {
        if (( count > 20 )) {
            return
        }
        (( count++ ))
        sleep 0.5
        lines2=${$(wc -l $MCPATH/logs/minecraft.log)[1]}
    }
    tail -n +$(($lines1 + 2)) $MCPATH/logs/minecraft.log
}


#Start-Stop here
case $1 {
    (start)
    mc_start
    ;;

    (stop)
    mc_stop
    ;;

    (restart)
    mc_stop
    mc_start
    ;;

    (backup)
    mc_backup
    ;;

    (sbackup)
    mc_stop
    cd $MCPATH
    if { grep Player logs/<->_<->.log(om[1]) > /dev/null } {
        mc_backup
    }
    mc_start
    ;;

    (cloudbak)
    mc_cloudbak
    ;;

    (status)
    if { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        echo "$SERVICE is running."
    } else {
        echo "$SERVICE is not running."
    }
    ;;

    (cmd)
    if { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        if (( # > 1 )) {
            shift
            mc_command "$*"
        } else {
            echo "Must specify server command (try 'help'?)"
        }
    } else {
        echo "$SERVICE is not running."
    }
    ;;

    (*)
    echo "Usage: $0 {start|stop|backup|sbackup|cloudbak|status|restart|cmd \"server command\"}"
    exit 1
    ;;
}

exit 0
