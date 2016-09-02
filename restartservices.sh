echo restart services
/etc/init.d/qemu-server start
/etc/init.d/vz start
/etc/init.d/pvedaemon start
/etc/init.d/pve-cluster start