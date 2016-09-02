####################################
#                                  #
#       DAILY /etc/ backup         #
#                                  #
# Copyright (c) 2015 PADOSOFT.COM  #
#                                  #
####################################

#permanent backup dir
_bdir="/mnt/sharedns323"

#check backup dir is mounted
if mountpoint -q /mnt/sharedns323 ; then
    echo "/mnt/sharedns323 is a mountpoint"
else
    #backup dir is not a mountpoint => try to mount it
    echo "/mnt/sharedns323 is not a mountpoint"
    mount -t cifs //192.168.0.14/Volume_1/proxmox2 /mnt/sharedns323 -o credentials=/root/.smbcredentials,nodfs
    ReturnCode_mount=$?
    if [ ${ReturnCode_mount} != 0 ]; then
        echo "Mount /mnt/sharedns323 error. Return Code = ${ReturnCode_mount}"
	exit 1;
    else
        echo "Mount /mnt/sharedns323 ok"
    fi
fi

#final check to backup dir
if ! [ -d $_bdir ]; then
	echo "Impossibile trovare $_bdir, controllare "
	exit 1;
fi

#root permission
if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. (if yuo are in ubuntu use sudo)"
	exit 1;
fi


#backup etc partition
#rsync -avze  ssh -P --delete  --stats /etc/ "$_bdir/etc"
rsync -avz -P --delete  --stats /etc/ "$_bdir/etc"
