#!/bin/bash

MAX_REVISIONS=3
DST_BASE_DIR=/local/virtual-machines-backup
DST_DIR=$DST_BASE_DIR/$(date +%Y-%m-%d_%H-%M-%S)

create_basedir() {
	/bin/mkdir -p $DST_DIR
	/bin/chmod 755 -R $DST_BASE_DIR
}

rotate_copies() {
	local backup_dirs=`ls -r $DST_BASE_DIR`
	local num_copies=`echo $backup_dirs | wc -w`
	local num_to_remove=`expr $num_copies - $MAX_REVISIONS`

	if [ $num_to_remove -gt 0 ]; then
		for i in `ls -r $DST_BASE_DIR | tail -$num_to_remove`; do
			/bin/rm -r $DST_BASE_DIR/$i
		done
	fi
}

run_backup() {
	for machine in `/usr/bin/virsh list --all --name`; do
		echo "===================== executing on: $machine ===================="
		shutdown_machine $machine
		copy_machine $machine
		echo "===================== finished on : $machine ===================="
	done
}

copy_machine() {
	if [ ! -z $1 ]; then
		machine_disks=`/usr/bin/virsh domblklist --domain=$1 | grep -i ^vd | awk '{ print $2}'`
		for disk in $machine_disks; do
			copy_disk $1 $disk;
			dump_machine_conf $1;
		done
	else
		echo "$1: is a invalid machine"
	fi
}

dump_machine_conf() {
	local bkp_basedir=$DST_DIR/$1
	/usr/bin/virsh dumpxml $1 > $bkp_basedir/$1.xml
}

copy_disk() {
	if [ -s $2 ]; then
		local bkp_basedir=$DST_DIR/$1
		/bin/mkdir $bkp_basedir
		/usr/bin/qemu-img convert -c -p -O qcow2 $2 $bkp_basedir/$1.qcow2
	else
		echo "$2: is not a valid file"
	fi
}

shutdown_machine() {
	/usr/bin/virsh list --name | grep $1 > /dev/null
	if [ $? -eq 0 ]; then
		echo "the machine is on. shutting down $1..."
		/usr/bin/virsh destroy --graceful $1
		if [ $? -eq 0 ]; then
			echo "shutted down with success!"
		else
			echo "failed to shutted down!"
		fi
	else
		echo "the machine is off"
	fi
}

list_backups() {
	if [ -d "$DIR" ]; then
		/usr/bin/du -sh $DST_BASE_DIR/*
	else
		echo "Directory not found!"
	fi
}

show_help() {
	echo "Usage: sudo /bin/bash $0 [ execute | info | list | help ]"
}

show_conf() {
	echo "MAX_REVISIONS=$MAX_REVISIONS"
	echo "DST_BASE_DIR=$DST_BASE_DIR"
}

check_root() {
	if [ "$(id -u)" != "0" ]; then
		echo "you must run it using sudo."
		exit 1;
	fi
}

case $1 in
    execute)
		check_root;
		create_basedir;
		rotate_copies;
		run_backup;
        exit 0;
        ;;
    list)
        list_backups;
        exit 0;
        ;;
	info)
		show_conf;
		exit 0;
		;;
    *)
        show_help;
        exit 0;
		;;
esac
