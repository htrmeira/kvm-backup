#!/bin/bash

######################### BEGIN OF CONFIG #########################

# Config file with the list of machine DNS (Or IP) names, one per line.
HOST_LIST=../config/machines.txt

# The local directory to store the backups.
LOCAL_BASEDIR=/local/virtual-machines-backup

# The remote directory storing the backups.
REMOTE_DIR=/local/virtual-machines-backup

# Local directory storing logs.
LOG_DIR=../log

########################## END OF CONFIG ##########################

#Log file name.
LOG_FILE=$LOG_DIR/backup-$(date +%Y-%m-%d_%H-%M-%S).log

# Creates the necessary directories.
# (the directory that will store the backups and the one to store the logs).
create_dir() {
	/bin/mkdir -p $LOCAL_BASEDIR
	/bin/mkdir -p $LOG_DIR
}

# Executes the backup script remotely on the machine given as argument as sudo.
# Arg1: DNS machine name or IP.
exec_remote() {
	/usr/bin/ssh suporte@$1 /usr/bin/sudo /opt/backup-scripts/exec-backup.sh execute
}

# Synchronize the backup directory on the remote machine with the local one using rsync.
# The arguments are described below.
# Arg1: DNS machine name or IP.
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
	/usr/bin/rsync --progress --human-readable --delete --recursive --hard-links \
		--archive --perms --owner --group --times --links --log-file=backup-vms.log \
		--link-dest=$LAST_BACKUP suporte@$1:$REMOTE_DIR/* $LOCAL_BASEDIR
	echo "synchronized..."
}

# Exec the copy and compression on the remote machine and sync the remote
# directory with the local one for each machine on machines files.
run_backup() {
	for machine in `cat $HOST_LIST`; do
		exec_remote $machine;
		sync $machine;
	done
}

run_sync() {
	if [ -z $1 ]; then
		for machine in `cat $HOST_LIST`; do
			sync $machine;
		done
	else
		sync $1;
	fi
}

# Create necessary directories and run the backup.
run() {
	/bin/date
	create_dir;
	run_backup;
	/bin/date
}

# Shows configurations info
show_info() {
	echo "HOST_LIST=$HOST_LIST"
	echo "LOCAL_BASEDIR=$LOCAL_BASEDIR"
	echo "REMOTE_DIR=$REMOTE_DIR"
	echo "LOG_DIR=$LOG_DIR"
}

# Shows how to call this script.
show_help() {
	echo "Usage: sudo /bin/bash $0 run | info | list | help | sync [machine_name]"
}

# List existing backups or shows 'Directory not found!' if the directory is not found.
list_backups() {
	if [ -d $LOCAL_BASEDIR ]; then
		du -sh $LOCAL_BASEDIR/*
	else
		echo "Directory not found!"
		exit 1;
	fi
}


case $1 in
	run)
		run | tee $LOG_FILE # Run showing the output on stdout and also storing on a log file.
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
	sync)
		run_sync $2;
		exit;
		;;
	*)
		show_help;
		exit 0;
		;;
esac
