#!/bin/bash

DRIVE=sda
HOSTE=artix
ADMIN=admin
USER1=user

function locale_setup {
	ln -sf /usr/share/zoneinfo/UTC /etc/localtime
	echo "en_US.UTF-8 UTF-8"   >>  /etc/locale.gen
	locale-gen
	echo "LANG=en_US.utf8"     >   /etc/locale.conf
	echo "LANGUAGE=en_US"      >>  /etc/locale.conf
	echo "LC_ALL=C"            >>  /etc/locale.conf
}

function bootloader_setup {
	pacman -S grub os-prober doas dhclient wpa_supplicant networkmanager \
          	  networkmanager-openrc wget --noconfirm
	grub-install --recheck --target=i386-pc /dev/$DRIVE
	grub-mkconfig -o /boot/grub/grub.cfg
}

function host_setup {
	echo $HOSTE                             >  /etc/hostname
	echo "hostname=$HOSTE"                  >  /etc/conf.d/hostname
	echo "127.0.0.1 localhost"              >> /etc/hosts
	echo "::1       localhost"              >> /etc/hosts
	echo "127.0.0.1 $HOSTE.localnet $HOSTE" >> /etc/hosts
}

function user_setup {
	useradd -m $ADMIN
	useradd -m $USER1
	echo "Set password for root user:";   passwd
	echo "Set password for admin user:";  passwd $ADMIN
	echo "Set password for normal user:"; passwd $USER1
	usermod -a -G video $USER1
	echo "permit persist $ADMIN"                               >  /etc/doas.conf
	echo "permit nopass  $USER1 cmd poweroff args"             >> /etc/doas.conf
	echo "permit nopass  $USER1 cmd wg-quick args up bridge"   >> /etc/doas.conf
	echo "permit nopass  $USER1 cmd wg-quick args down bridge" >> /etc/doas.conf
}

function next_stage {
	wget https://raw.githubusercontent.com/m00E10/install-artix/main/3postchroot.sh
	mv 3postchroot.sh /root/
	echo "Now run the following:"
	echo " exit"
	echo " umount -R /mnt"
	echo " reboot"
	echo "Then login as root and run bash 3postchroot.sh"
}

locale_setup
bootloader_setup
host_setup
user_setup
next_stage
