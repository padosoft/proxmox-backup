
# proxmox-backup
Bash scripts to backup and restore proxmox server. 

[![Software License][ico-license]](LICENSE.md)

Table of Contents
=================

  * [proxmox-backup](#proxmox-backup)
  * [Table of Contents](#table-of-contents)
  * [Prerequisites](#prerequisites)
  * [Install](#install)
  * [Tutorial](#tutorial)
  * [Contributing](#contributing)
  * [Credits](#credits)
  * [About Padosoft](#about-padosoft)
  * [License](#license)

# Prerequisites

bash

# Install

This package can be installed easy.

``` bash
cd /root/
git clone https://github.com/padosoft/proxmox-backup.git
cd proxmox-backup
chmod +x *.sh
```

If you want to run programmatically, add it to cronjobs manually or execute install script:

``` bash
cd /root/proxmox-backup
chmod +x install.sh
bash install.sh
```


# Tutorial
# Procedure di Backup e Ripristino PROXMOX

## Condivisione di una cartella di rete permanente

Le copie di backup sono salvate in rete su cartelle condivise.
Una volta condivisa con samba una cartella esterna è possibile montarla sul sistema in uso per utilizzarla come una semplice directory in fase di backup.

Per prima cosa nel sistema da backuppare viene creata una cartella su cui montare la cartella esterna

``` bash
mkdir /mnt/sharedns323
```

la cartella viene poi permanentemente montata scrivendo aggiungendo nel file 

``` bash
/etc/fstab
```

la seguente riga

``` bash
//192.168.0.14/Volume_1/proxmox2 /mnt/sharedns323 cifs credentials=/root/.smbcredentials
```

dove //192.168.0.14/Volume_1/proxmox2 è la cartella condivisa in rete e nel file /root/.smbcredentials
ci sono le credenziali di accesso.

Il file /root/.smbcredentials è di questo tipo

username=root
password=xxxxxx
domain=PADOVANI

modificato il file fstab testarlo col comando

``` bash
mount -a
```

## Tools di backup, installazione e uso

Per il backup viene utilizzato fsarchiver, a differenza di altri tool crea l’immagine del solo filesystem e non di tutto il disco, anche a caldo

Installazione di fsarchiver

``` bash
apt-get update
apt-get install fsarchiver
```

Le partizioni di proxmox da backuppare sono la root e la parte data contenute in una partizione logica lvm2
Per individuare all’interno della partizione logica lvm2 di proxmox le partizioni di interesse usiamo

``` bash
fsarchiver probe 
```

le partizioni di interesse sono le dm-x e con

``` bash
dmsetup ls
```

è possibile capire quali siano quella di root e data ottenendo un qualcosa di simile:

``` bash
pve-swap        (253:1)
pve-root        (253:0)
pve-data        (253:2)
```

pve-root in questo caso è contenuta in dm-0, mentre la parte pve-data in dm-2

`di seguito lo script che effettua il backup:`

``` bash
/root/proxmox-backup/backupproxmox.sh
```

In sintesi le copie vengono prima salvate su una cartella temporanea "/var/tmp/backup" creata nel caso non esita, sono stoppati 4 servizi di proxmox

``` bash
/etc/init.d/pve-cluster stop
/etc/init.d/pvedaemon stop
/etc/init.d/vz stop
/etc/init.d/qemu-server stop
```

e lanciato fsarchiver

``` bash
fsarchiver savefs -aAdv "$_bdir/$_day.dm-0.fsa" "/dev/dm-0"
fsarchiver savefs -aAdv "$_tdir/$_day.dm-2.fsa" "/dev/dm-2"
```

il parametro savefs indica che si sta salvando il filesystem, i parametri “d” e “v” servono per far scrivere le informazioni di esecuzione, mentre i parametri “A” e “a” 

 -A: allow to save a filesystem which is mounted in read-write (live backup)
 -a: allow running savefs when partition mounted without the acl/xattr options

la partizione di sistema, più piccola di dimensioni viene creata direttamente nella cartella condivisa, quella di data invece viene prima creata in locale e poi spostata nella cartella condivisa con il comando

``` bash
rsync -avz --progress "$_tdir/$_day.dm-2.fsa" "$_bdir/$_day.dm-2.fsa"
```

terminata la copia sono riavviati i servizi

``` bash
echo restart services 
/etc/init.d/qemu-server start
/etc/init.d/vz start
/etc/init.d/pvedaemon start
/etc/init.d/pve-cluster start
```

utilizzando un altro script tutto il processo viene schedulato, e inviato per email utilizzando ssmtp (vedi questa guida per come configurarlo https://docs.google.com/document/d/1YLI4ToPftmowrmsRRhSxW8hzDBKW4LvhxSGAwigoQP8/  ), utilizzando il nome del giorno della settimana il tutto ha una rotazione di 7 giorni

``` bash
/root/proxmoxrestore/backup_week.sh
```

Per schedulare i servizi si utilizza il comando

``` bash
crontab -e
```

a cui si aggiunge la seguente linea

``` bash
# m h  dom mon dow   command

0 03 * * * /root/proxmoxrestore/sh backup_week.sh
```

Con questa sintassi si esegue uno script ogni giorno alle 3 di notte

## Sync su macchina Proxmox muletto

vedi anche:
http://www.cyberciti.biz/faq/how-to-wakeup-backup-nas-server-and-mirror-files-using-rsync-in-linux/

Sul muletto è installato proxmox e la partizione di root è la stessa del server.
Ogni sera il muletto si accende da bios, il server poco dopo con un processo schedulato stoppa i servizi proxmox del muletto, copia tutta la sua partizione data e spegne il muletto.
Per accedere al muletto senza digitare la password viene utilizzata una comunicazione ssh registrando la chiave pubblica del muletto sul server.

il file sh con le procedure di copia è

``` bash
/root/proxmoxrestore/vz_rsync.sh
```

schedulato e inviato per email con lo script

``` bash
/root/proxmoxrestore/vz_rsync_daily.sh
```

inserito in pianificazione con il solito

``` bash
crontab -e
```


## Generazione chiave pubblica e privata ssh sul muletto e installazione su server

Per connettersi da un pc all’altro utilizzando ssh senza autenticazione è possibile registrare la chiave pubblica sul server da cui si vuol accedere

Per prima cosa si creano le chiavi pubbliche e private sul muletto digitando
``` bash
ssh-keygen -t rsa
```

premere invio lasciando il nome di default della chiave e non aggiungendo password
Questo creerà nella cartella /root/.ssh un file id_rsa e id_rsa.pub

eseguire poi 

``` bash
ssh-copy-id root@192.168.0.33
```

dove 192.168.0.33 è l’indirizzo del server proxmox, e quando richiesto inserire la password di root

testare da server il comando

``` bash
ssh root@192.168.0.11 ls
```

la prima volta chiederà di salvare il pc 192.168.0.11 (o l’equivalente indirizzo ip del muletto) tra gli host conosciuti

dovrebbe mostrare il contenuto della cartella senza ulteriore autenticazione, di fatto il comando ssh-copy-id  copia il file id_rsa.pub del muletto e lo inserisce nel file /root/.ssh/authorized_keys del server


## RESTORE BACKUP AND DISASTER RECOVERY

Ripristino partizione di root in caso di disaster recovery su macchina non configurata.

Installare proxmox VE 3.4 da cd (https://www.proxmox.com/en/).
Lasciare i valori di default (ext3 ed eventuale indirizzo IP). Nel caso si conosca è possibile inserire l’indirizzo IP della macchina che si sostituisce, il nome host è invece pve.padosoft.local

Una volta installato proxmox

riavvio e utilizzo systemrescuecd  (http://www.sysresccd.org/)
da live cd utilizzando la shell
faccio il mount della cartella condivisa che contengono i backup
``` bash
mount -t cifs //192.168.0.14/Volume_1 /mnt/share
```

con 
``` bash
fsarchiver probe simple
```

vedo i device e cerco quello di root tra i dm (probabilmente il dm-0) con

``` bash
fsarchiver probe 
```

se ho dubbi basta montarli e navigarli

``` bash
mkdir /mnt/dm0
mount /dev/dm-0 /mnt/dm0
```

ripristino la partizione di root, nel caso devo prima fare l’umount

``` bash
umount /mnt/dm0
```

e poi uso fsarchiver

``` bash
fsarchiver restfs /mnt/share/dm0.aaaa.mm.dd.fsa id=0,dest=/dev/dm-0
```

alla fine reboot della macchina

Al riavvio si avrà un errore in fstab dovuto al cambio di UUID dell’hd. Eseguire:

``` bash
blkid   
```

per scoprire uuid nuovo hardware delle partizioni
cambio uuid in 

``` bash
/etc/fstab
```

``` bash
# <file system> <mount point> <type> <options> <dump> <pass>
/dev/pve/root / ext3 errors=remount-ro 0 1
/dev/pve/data /var/lib/vz ext3 defaults 0 1
UUID=CC11-46AB /boot/efi vfat defaults 0 1
/dev/pve/swap none swap sw 0 0
proc /proc proc defaults 0 0
//192.168.0.14/Volume_1/proxmox2 /mnt/sharedns323 cifs credentials=/root/.smbcredentials
```

salvato il file lo testo con 
``` bash
mount -a
```

controllo che l’interfaccia ethernet sia la stessa, 

``` bash
ip link show   
```

se prima avevo eth0 e ora eth1 la tiro su

``` bash
ifconfig eth1 up   
```

e poi cambio 

``` bash
/etc/network/interfaces il bridge
```

``` bash
auto lo
iface lo inet loopback

auto vmbr0
iface vmbr0 inet static
  address 192.168.0.11
  netmask 255.255.255.0
  gateway 192.168.0.1
  bridge_ports eth0
  bridge_stp off
  bridge_fd 0
```

salvo e reboot


## Ripristino partizione Data

Effettuo il ripristino della partizione data direttamente dalla macchina senza live cd.
Entro e stoppo i servizi proxmox

``` bash
/etc/init.d/pve-cluster stop
/etc/init.d/pvedaemon stop
/etc/init.d/vz stop
/etc/init.d/qemu-server stop
```

nel caso non sia installato installo fsarchiver

e ripristino la partizione data controllando prima quale sia con il comando

``` bash
dmsetup ls
```

ipotizzando sia la dm-2

``` bash
fsarchiver restfs /mnt/sharedns323/dm2.aaaa.mm.dd.fsa id=0,dest=/dev/dm-2
```

finito riavvio la macchina.


# Contributing

Please see [CONTRIBUTING](CONTRIBUTING.md) and [CONDUCT](CONDUCT.md) for details.


# Credits

- [Lorenzo Padovani](https://github.com/lopadova)
- [Alessandro Manneschi](https://github.com/alevento)
- [Padosoft](https://github.com/padosoft)
- [All Contributors](../../contributors)

# About Padosoft
Padosoft is a software house based in Florence, Italy. Specialized in E-commerce and web sites.

# License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.

[ico-license]: https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
