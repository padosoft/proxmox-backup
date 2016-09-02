dayOfWeek=$(date +%A)
sh /root/proxmox-backup/backupproxmox.sh > /root/proxmox-backup/${dayOfWeek}.email.log
mail -s "backup ${dayOfWeek}" helpdesk@padosoft.com < /root/proxmox-backup/${dayOfWeek}.email.log