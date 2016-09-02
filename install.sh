#!/bin/bash
#
# Author: Lorenzo Padovani
# @padosoft
# https://github.com/lopadova
# https://github.com/padosoft
#

#
# Add a cron job
# ref.: http://stackoverflow.com/questions/878600/how-to-create-cronjob-using-bash
#
#write out current crontab into temp file
crontab -l > mycron

#echo new cron into cron file
echo "0 0 * * * /root/proxmox-backup/backup_week.sh" >> mycron
echo "0 2 * * * find /var/log/ -name "fsarchiver*.log" -type f -mtime +3 -exec rm {} \;" >> mycron
echo "58 9 * * * /root/proxmox-backup/vz_rsync_daily.sh" >> mycron
echo "0 6 * * * /root/proxmox-backup/etc_rsync_daily.sh" >> mycron

#install new cron file
crontab mycron

#print result
echo "cronjobs added successfull!"

#remove tmp file
rm mycron
