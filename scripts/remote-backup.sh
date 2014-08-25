#!/bin/bash

HOST_LIST=./machines.txt
LOCAL_BASEDIR=/local/virtual-machines-backup
REMOTE_DIR=/local/virtual-machines-backup
LOG_FILE=./backup.log


create_dir() {
	/bin/mkdir -p $LOCAL_BASEDIR
}

exec_remote() {
	/usr/bin/ssh suporte@$1 /usr/bin/sudo /opt/backup-scripts/exec-backup.sh execute
}

sync() {
	echo "synchronizing with local backup..."
	LAST_BACKUP=$LOCAL_BASEDIR/$(ls $LOCAL_BASEDIR | sort | tail -1)
	# --progress: show progress during transfer
	# --human-readable:  output numbers in a human-readable format
	# --delete: delete extraneous files from dest dirs
	# --recursive: recurse into directories
	# --hard-links: preserve hard links
	# --archive: archive mode; equals -rlptgoD (no -H,-A,-X)
	# --perms: preserve permissions
	# --owner: preserve owner (super-user only)
	# --group: preserve group
	# --times: preserve times
	# --links: copy symlinks as symlinks
	# --link-dest: hardlink to files in DIR when unchanged
	/usr/bin/rsync --progress --human-readable --delete --recursive --hard-links --archive --perms --owner --group --times --links --log-file=backup-vms.log --link-dest=$LAST_BACKUP suporte@$1:$REMOTE_DIR/* $LOCAL_BASEDIR
	echo "synchronized..."
}

run_backup() {
	for machine in `cat $HOST_LIST`; do
		exec_remote $machine;
		sync $machine;
	done
}

run() {
	/bin/date
	create_dir;
	run_backup;
	/bin/date
}

show_info() {
	echo "HOST_LIST=$HOST_LIST"
	echo "LOCAL_BASEDIR=$LOCAL_BASEDIR"
	echo "REMOTE_DIR=$REMOTE_DIR"
}

show_help() {
	echo "Usage: sudo /bin/bash $0 [run|info|list|help]"
}

list_backups() {
	if [ "$(id -u)" != "0" ]; then
		du -sh $LOCAL_BASEDIR/*
	else
		echo "Directory not found!"
		exit 1;
	fi
}


case $1 in
	run)
		run | tee $LOG_FILE
		exit 0;
		;;
	info)
		show_info;
		exit 0;
		;;
	list)
		list_backups;
		exit 0;
		;;
	*)
		show_help;
		exit 0;
		;;
esac
