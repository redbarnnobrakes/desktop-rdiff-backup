#!/bin/bash

#Set required variables
DIST=$(cat /etc/lsb-release | grep -oP 'DISTRIB_ID\=\K\w+')
BACKUP_PUB_KEY="$HOME/.ssh/rdiff_rsa"
BACKUP_SOURCE="$HOME"
USER_LOCAL=`whoami`
USER_REMOTE="<remote username>"
BACKUP_SERVER="<backup server hostname or IP>"
BACKUP_DEST="/mnt/stash/rdiff-backups/`hostname`-home"
BACKUP_LOG_ERROR="$HOME/.backup.err.log"
BACKUP_LOG="$HOME/.backup.log"
IS_INSTALLED=$(which rdiff-backup)


#Check if rdiff-backup is installed
if [ ! -n "$IS_INSTALLED" ]; then
  echo "you need to install rdiff-backup";
  exit 1
fi

#Notification of backup. tested with Arch w/ Gnome & Ubuntu Unity
case $DIST in
   "Arch") sudo -u $USER_LOCAL DISPLAY=:0.0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USER_LOCAL)/bus" notify-send -i document-save "Backup started";;
   "Ubuntu") sudo -u $USER_LOCAL DISPLAY=:0.0 notify-send -i document-save "Backup started";;
   *) echo "***Distribution not detected for notify***" >> $BACKUP_LOG_ERROR;;
esac

#Magic
BACKUP_INFO=$(rdiff-backup --print-statistics --exclude ~/tmp --exclude ~/.cache --exclude ~/.local/share/Trash --remote-schema 'ssh -C -i '$BACKUP_PUB_KEY' %s rdiff-backup --server' $BACKUP_SOURCE $USER_REMOTE@$BACKUP_SERVER::$BACKUP_DEST 2>> $BACKUP_LOG_ERROR)

#Notify on error
if [ $? != 0 ]; then
{
    echo "BACKUP FAILED!"
    # notification
    MSG=$(tail -n 5 $BACKUP_LOG_ERROR)
    case $DIST in
       "Arch") sudo -u $USER_LOCAL DISPLAY=:0.0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USER_LOCAL)/bus" notify-send -u critical -i error "Backup Failed" "$MSG";;
       "Ubuntu") sudo -u $USER_LOCAL DISPLAY=:0.0 notify-send -u critical -i error "Backup Failed" "$MSG";;
       *) echo "***Distribution not detected for notify***" >> $BACKUP_LOG_ERROR;;
    esac
    # dialog
    MSG=$(tail -n 5 $BACKUP_LOG_ERROR)
    case $DIST in
       "Arch") sudo -u $USER_LOCAL DISPLAY=:0.0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USER_LOCAL)/bus" notify-send -u critical -t 0 -i error "Backup Failed" "$MSG";;
       "Ubuntu") sudo -u $USER_LOCAL DISPLAY=:0.0 notify-send -u critical -t 0 -i error "Backup Failed" "$MSG";;
       *) echo "***Distribution not detected for notify***" >> $BACKUP_LOG_ERROR;;
    esac
    exit 1
} fi

#Log backup results
echo "$BACKUP_INFO" >> $BACKUP_LOG

STATS=$(echo "$BACKUP_INFO"|grep '^Errors\|^ElapsedTime\|^TotalDestinationSizeChange')

case $DIST in
   "Arch") sudo -u $USER_LOCAL DISPLAY=:0.0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $USER_LOCAL)/bus" notify-send -t 1000 -i document-save "Backup Complete" "$STATS";;
   "Ubuntu") sudo -u $USER_LOCAL DISPLAY=:0.0 notify-send -t 1000 -i document-save "Backup Complete" "$STATS";;
   *) echo "***Distribution not detected for notify***" >> $BACKUP_LOG_ERROR;;
esac
