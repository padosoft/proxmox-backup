dayOfWeek=$(date +%A)
/bin/sh /root/proxmox-backup/vz_rsync.sh > /root/proxmox-backup/${dayOfWeek}.email_vz_rsync.log
mail -s "rsync ${dayOfWeek}" helpdesk@padosoft.com < /root/proxmox-backup/${dayOfWeek}.email_vz_rsync.log
