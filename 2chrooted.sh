#!/bin/bash

function copy_dot_files {
  mv dotfiles/.tmux.conf /etc/skel
  mv dotfiles/.vimrc /etc/skel
  mv dotfiles/.bashrc /etc/skel
}

function user_setup {
  userans=t
  while [ "$userans" != y ]; do
    echo -e "\033[0;33mSet the password for your root user\033[0m"
    passwd
    echo -e "\033[0;33mWas password set successfully? y/n\033[0m"
    read userans
  done

  # Make admin user
  echo -e "\033[0;33mSet the name of your admin user (Standard users will be added later)\033[0m"
	read USER
	echo "USER=$USER" >> vars
	useradd -m -G wheel $USER
	echo "permit persist $USER" >> /etc/doas.conf

	userans=t
	while [ "$userans" != y ]; do
	  echo -e "\033[0;33mSet the password for your admin user\033[0m"
	  passwd $USER
	  echo -e "\033[0;33mWas password set successfully? y/n\033[0m"
	  read userans
	done
}

function timezone_setup {
	userans=t
	while [ "$userans" != y ]; do
	  ls /usr/share/zoneinfo
	  echo -e "\033[0;33mWhats your timezone?\033[0m"
	  read ZONE1
  	ls /usr/share/zoneinfo/$ZONE1
	  echo -e "\033[0;33mWhats your timezone?\033[0m"
	  read ZONE2
	  ln -s /usr/share/zoneinfo/$ZONE1/$ZONE2 /etc/localtime
	  hwclock --systohc
	  echo -e "\033[0;33mWas timezone set correctly? y/n\033[0m"
	  read userans
	done
}

function host_locale_setup {
	echo -e "\033[0;33mWhat do you want your hostname to be?\033[0m"
	read HOSTNAME
	echo "$HOSTNAME" > /etc/hostname

	userans=t
	while [ "$userans" != y ]; do
	  echo -e "\033[0;33mIn 10 seconds uncomment your locale (usually en_US.UTF-8) then save and quit\033[0;37m"
	  sleep 10
	  vim /etc/locale.gen # uncomment en_US.UTF-8
	  echo -e "\033[0;33mWas locale set correctly? y/n\033[0m"
	  read userans  
	done

	locale-gen
	echo LANG=en_US.utf8 >> /etc/locale.conf
	echo LANGUAGE=en_US >> /etc/locale.conf
	echo LC_ALL=C >> /etc/locale.conf
}

function make_init {
	rm /etc/mkinitcpio.conf
	mv mkinitcpio.conf /etc/mkinitcpio.conf
	mkinitcpio -p linux-hardened
}

function make_grub {
	echo GRUB_CMDLINE_LINUX=\"cryptdevice=/dev/$DRIVE\1:artix:allow-discards\" >> grub-top
	cat grub-bottom >> grub-top
	cat grub-top > /etc/default/grub
	rm grub-*

	#Install grub and create configurations
	grub-install --target=i386-pc /dev/$DRIVE # MBR only baby
	grub-mkconfig -o /boot/grub/grub.cfg
}

function setup_next {
	cp vars tmpvars
	mv 4finalconfig.sh /root
	mv vars /root
	cat 3postchroot.sh >> tmpvars
	mv tmpvars /root/3postchroot.sh
	mv *.ttf /root

	echo -e "\033[0;33mYou must now manually enter the following commands\033[0m"
	echo -e "\033[1;36mexit\033[0m"
	echo -e "\033[1;36mumount -R /mnt\033[0m"
	echo -e "\033[1;36mreboot\033[0m"
	echo -e "\033[0;33mAfter the reboot, login as root and then run bash 3postchroot.sh\033[0m"
}

copy_dot_files
user_setup
timezone_setup
host_locale_setup
make_init
make_grub
setup_next
