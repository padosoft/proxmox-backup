####################################
#                                  #
#  BACKUP PROXMOX CONFIGURATION    #
#                                  #
####################################

#set vars
_now=$(date +%Y-%m-%d.%H.%M.%S)
_day=$(date +%A)

#temp storage dir
_tdir="/var/tmp/backup"

#permanent backup dir
_bdir="/mnt/sharedns323/backupProxmoxConfig"

if mountpoint -q /mnt/sharedns323 ; then
    echo "/mnt/sharedns323 is a mountpoint"
else
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


if ! [ -d $_bdir ]; then
	echo "Impossibile trovare $_bdir, controllare "
	exit 1;
fi

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. (if you are in ubuntu use sudo)"
		exit 1;
fi

echo "check if directory $_tdir exists or not"
if ! [ -d $_tdir ]; then
	echo "$_tmpdir not exist, create it..."
	mkdir $_tdir
else
	echo "$_tdir exists, delete all contents..."
	#TODO: finito le prove riabilitare qui l'rm
	rm -rf "$_tdir/"
	ReturnCode_rm=$?
	if [ ${ReturnCode_rm} != 0 ]; then
	  echo "Rm "$_tdir/*" error. Return Code = ${ReturnCode_rm}"
	fi
	if ! [ -d $_tdir ]; then
		echo "$_tmpdir not exist, create it..."
		mkdir $_tdir
	fi
fi


echo stop host services
/etc/init.d/pve-cluster stop
/etc/init.d/pvedaemon stop
/etc/init.d/vz stop
/etc/init.d/qemu-server stop

#give them a moment to finish
sleep 15s

echo copy system files

if [ -e "$_bdir/$_day.dm-0.fsa" ]; then
    rm -f "$_bdir/$_day.dm-0.fsa"
	ReturnCode_rmf=$?
	if [ ${ReturnCode_rmf} != 0 ]; then
	  echo "Rm '$_bdir/$_day.dm-0.fsa' error. Return Code = ${ReturnCode_rmf}"
	fi
fi

if [ -e "$_tdir/$_day.dm-0.fsa" ]; then
    rm -f "$_tdir/$_day.dm-0.fsa"
	ReturnCode_rmf1=$?
	if [ ${ReturnCode_rmf1} != 0 ]; then
	  echo "Rm '$_tdir/$_day.dm-0.fsa' error. Return Code = ${ReturnCode_rmf1}"
	fi
fi

fsarchiver savefs -aoAdv "$_bdir/$_day.dm-0.fsa" "/dev/dm-0"
ReturnCode_dm_0=$?

if [ ${ReturnCode_dm_0} != 0 ]; then
  echo "fsarchiver dm-0 error. Return Code = ${ReturnCode_dm_0}"
else
  echo "fsarchiver dm-0 ok. Return Code = ${ReturnCode_dm_0}"
fi

if [ -e "$_tdir/$_day.dm-2.fsa" ]; then
    rm -f "$_tdir/$_day.dm-2.fsa"
	ReturnCode_rmf2=$?
	if [ ${ReturnCode_rmf2} != 0 ]; then
	  echo "Rm '$_tdir/$_day.dm-2.fsa' error. Return Code = ${ReturnCode_rmf2}"
	fi
fi

fsarchiver savefs -aoAdv "$_tdir/$_day.dm-2.fsa" "/dev/dm-2"

ReturnCode_dm_2=$?

if [ ${ReturnCode_dm_2} != 0 ]; then
  echo "fsarchiver dm-2 error. Return Code = ${ReturnCode_dm_2}"
  rm -f "$_tdir/$_day.dm-2.fsa"
  ReturnCode_rm_1=$?

  if [ ${ReturnCode_rm_1} != 0 ]; then
	echo "error removing file $_tdir/$_day.dm-2.fsa. Return code = ${ReturnCode_rm_1}"
  else
	echo file "$_tdir/$_day.dm-2.fsa" successfully removed
  fi
else
  #mv -fv "$_tdir/dm-2.$_now.fsa" "$_bdir/dm-2.$_now.fsa"

  if [ -e "$_bdir/$_day.dm-2.fsa" ]; then
    rm -f "$_bdir/$_day.dm-2.fsa"
	ReturnCode_rmf3=$?
	if [ ${ReturnCode_rmf3} != 0 ]; then
	  echo "Rm '$_bdir/$_day.dm-2.fsa' error. Return Code = ${ReturnCode_rmf3}"
	fi
fi


  rsync -rltDvz --progress --omit-dir-times --inplace "$_tdir/$_day.dm-2.fsa" "$_bdir/$_day.dm-2.fsa"
  ReturnCode_rsync=$?

  if [ ${ReturnCode_rsync} != 0 ]; then
	echo "rsync error. Return code = ${ReturnCode_rsync}"
  else
	echo "rsync ok. Return code = ${ReturnCode_rsync}"
  fi
  echo "fsarchive dm-2 ok. Return Code = ${ReturnCode_dm_2}"

fi
#tar -cvf "$_f1" /etc/*
#tar -cvf "$_f2" /var/lib/pve-cluster/*

echo restart services
/etc/init.d/qemu-server start
/etc/init.d/vz start
/etc/init.d/pvedaemon start
/etc/init.d/pve-cluster start

echo "remove $_tdir/*"
#TODO: finito le prove riabilitare qui l'rm
rm -rf "$_tdir/"
ReturnCode_rm=$?
if [ ${ReturnCode_rm} != 0 ]; then
  echo "Rm "$_tdir/*" error. Return Code = ${ReturnCode_rm}"
fi

find /var/log/fsarchiver* -mtime +7 -exec rm {} \;

echo Finish!!

