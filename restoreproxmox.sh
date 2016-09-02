#########################################
#										#
#    RESTORE PROXMOX CONFIGURATION      #
#										#
#########################################

#file name to restore
_tmpdir="/tmp/backup"
_fname="dm-4.2015-07-08.12.15.48.fsa"
_fsource="/mnt/sharedns323/backupProxmoxConfig/$_fname"
_fsourcetmp="$_tmpdir/$_fname"
_ftarget="/dev/dm-2"



if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. (if you are in ubuntu use sudo)"
		exit 1;
fi


echo "check if directory $_tmpdir exists or not"
if ! [ -d $_tmpdir ]; then
	echo "$_tmpdir not exist, create it..."
	mkdir $_tmpdir
else
	echo "$_tmpdir exists, delete all contents..."
	#rm -r "$_tmpdir/*"
fi



echo "copy the original backup in temp folder"
#cp "$_fsource" "$_tmpdir/"
#rsynch -avz --progress "$_fsource" "$_tmpdir/"
rsynch -avz --progress "/mnt/sharedns323/backupProxmoxConfig/proxmox_config.2015-07-07.18.11.29.tar.gz" "$_tmpdir/"

#stop host services
/etc/init.d/pve-cluster stop
/etc/init.d/pvedaemon stop
/etc/init.d/vz stop
/etc/init.d/qemu-server stop

echo "give them a moment (15s) to finish..."
sleep 15s

echo "extrach fsarchive partition to $_ftarget"
fsarchiver restfs -v $_fsourcetmp id=0,dest=$_ftarget


echo "restart services..."
/etc/init.d/qemu-server start
/etc/init.d/vz start
/etc/init.d/pvedaemon start
/etc/init.d/pve-cluster start

echo "remove $_tmpdir/*"
#rm -r "$_tmpdir/*"

