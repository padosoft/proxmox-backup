####################################
#                                  #
#       DAILY /etc/ backup         #
#                                  #
# Copyright (c) 2015 PADOSOFT.COM  #
#                                  #
####################################

#grab day of week
dayOfWeek=$(date +%A)

#do backup and save log
/bin/sh /root/proxmox-backup/etc_rsync.sh > "/root/proxmox-backup/${dayOfWeek}_email_etc_rsync.log"

#send backup log to mail
mail -s "etc rsync ${dayOfWeek}" helpdesk@padosoft.com < "/root/proxmox-backup/${dayOfWeek}_email_etc_rsync.log"
