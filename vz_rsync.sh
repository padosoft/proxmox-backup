ssh root@192.168.0.11 "/etc/init.d/pve-cluster stop"
ssh root@192.168.0.11 "/etc/init.d/pvedaemon stop"
ssh root@192.168.0.11 "/etc/init.d/vz stop"
ssh root@192.168.0.11 "/etc/init.d/qemu-server stop"
rsync -avze  ssh -P --delete  --stats /var/lib/vz/ root@192.168.0.11:/var/lib/vz
#ssh root@192.168.0.11 "/etc/init.d/pve-cluster start"
#ssh root@192.168.0.11 "/etc/init.d/pvedaemon start"
#ssh root@192.168.0.11 "/etc/init.d/vz start"
#ssh root@192.168.0.11 "/etc/init.d/qemu-server start"
ssh root@192.168.0.11 "poweroff"

