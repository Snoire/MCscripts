#! /bin/zsh

#Settings
SERVICE='bedrock_server'
SCREENNAME='mc'
MCUSER='mc'
MCPATH='/home/mc/minecraft'
INVOCATION="./bedrock_server"
#WORLDNAME='survival'
#LOGSPATH=$MCPATH/logs
#BACKUPPATH=$MCPATH/worlds.backup

as_user() {
    if [[ $USERNAME == $MCUSER ]] {
        zsh -c "$1"
    } else {
        su - "$MCUSER" -c "$1"
    }
}

mc_help() {
    local all_logs=($MCPATH/logs/*.log)
    print -X7 -P 'usage: mc start%F{green}|%fstop%F{green}|%frestart%F{green}|%fbackup%F{green}|%fsbackup%F{green}|%fcloudbak\n'\
                      "\tmc status%F{green}|%fshowlog [1-$#all_logs]%F{green}|%fcmd [-q] \"server command\"\n"\
                      "\tmc fire/grief [-q] on/off"
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

    cd $MCPATH/logs
    sed -i '/Running AutoCompaction/d' minecraft.log
    mv minecraft.log $(date "+%y%m%d_%H%M%S").log

    all_logs=(<->_<->.log(N))
    new_logs=(<->_<->.log(om[1,32]N))
    rm -vf ${all_logs:|new_logs}

    echo "$SERVICE is stopped."
}

mc_backup() {
    NOW=$(date "+%y%m%d_%H%M%S")
    BACKUP_FILE="$MCPATH/worlds.backup/survival_${NOW}.mcworld"

    echo "Backing up minecraft world..."
    cd $MCPATH/worlds/survival-1
    zip -rq $BACKUP_FILE *

    echo "Removing all backups except for the latest seven files..."
    cd $MCPATH/worlds.backup
    all_backups=((.|)survival_<->_<->.mcworld(N))
    new_backups=((.|)survival_<->_<->.mcworld(om[1,7]N))
    rm -vf ${all_backups:|new_backups}

    echo "Done."
}

mc_cloudbak() {
    cd $MCPATH/worlds.backup
    BACKUPFILE=(survival_<->_<->.mcworld(om[1]N))

    if (( $#BACKUPFILE == 1 )) {
        /usr/local/bin/dav $BACKUPFILE
        autoload -U zmv
        zmv '(survival_<->_<->.mcworld)' '.$1'
    }
}

mc_command() {
    local quiet=0
    if [[ $1 == "-q" ]] {
        shift
        quiet=1
    }
    command=$*
    lines1=${$(wc -l $MCPATH/logs/minecraft.log)[1]}
    as_user "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"$command\"\015'"

    if (( quiet == 0 )) {
        local count=1
        local lines2=$lines1
        echo "$command"
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
}


#Start-Stop here
case $1 {
((--|)help|-h)
    mc_help
    ;;
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
(showlog)
    if (( # < 3 )) {
        cd $MCPATH/logs
        local num=1
        (( # == 2 )) && num=$2

        local all_logs=(*.log)
        if (( num >= 1 && num <= $#all_logs )) {
            if [[ -s minecraft.log ]] {
                if (( num == 1 )) {
                    sed '/Running AutoCompaction/d' minecraft.log | less
                    exit 0
                } else {
                    logfile=(<->_<->.log(om[$((num-1))]))
                }
            } else {
                logfile=(<->_<->.log(om[$num]))
            }

            less $logfile
            exit 0
        }
    }
    ;|
(cmd)
    if { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        if (( # > 1 )) {
            shift
            mc_command $*
        } else {
            echo "Must specify server command (try 'help'?)"
        }
    } else {
        echo "$SERVICE is not running."
    }
    ;;
(fire|grief)
    if { pgrep -u $MCUSER -f $SERVICE > /dev/null } {
        local rule=$1
        shift
        local quiet=0
        if [[ $1 == "-q" ]] {
            shift
            quiet=1
        }
        if (( # == 1 )) && [[ $1 =~ 'on|off' ]] {
            local -A table=(on true off false fire doFireTick grief mobgriefing)
            mc_command gamerule $table[$rule] $table[$1]
            if (( quiet == 0 )) {
                mc_command -q "say Game rule $table[$rule] has been updated to $table[$1]"
            }
            exit 0
        }
    } else {
        echo "$SERVICE is not running."
        exit 0
    }
    ;|
(*)
    mc_help
    exit 1
    ;;
}

exit 0
