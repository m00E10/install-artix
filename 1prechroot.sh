#!/bin/bash
# Dual boot, btrfs, linux hardened, sway with i3status-rust

function repo_setup {
  pacman -Sy
  pacman -S parted artix-archlinux-support
  pacman-key --populate archlinux
  echo "[omniverse]" >> /etc/pacman.conf
  echo "Server = http://omniverse.artixlinux.org/\$arch" >> /etc/pacman.conf
  echo "[extra]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
  echo "[community]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
  echo "[multilib]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
  pacman -Sy

  disk_setup
}

function disk_setup {
  fdisk -l | grep /dev
  echo -e "\033[0;33mInput the drive you wish to install Artix to.\033[0m"
  echo -e "\033[0;33mExample: sda\033[0m"
  read DRIVE
  echo "DRIVE=$DRIVE" >> vars

  echo -e "\033[0;33mDo you want to setup LUKS encryption?\033[0m"
  echo -e "\033[0;33m1. Yes\033[0m"
  echo -e "\033[0;33m2. No\033[0m"
  
  while [ "$luks_answer" != "1" ]; do
    read luks_answer
  	if [ "$luks_answer" == "1" ]; then
  		encryption_setup
  	elif [ "$luks_answer" == "2" ]; then
		regular_setup
    fi
  done
}

function encryption_setup {
  MPATH=/dev/mapper/artix
  # Set up LUKS encryption
  parted -s /dev/$DRIVE mklabel msdos
  echo -e "\033[0;31mBe aware: Any currently installed Operating Systems will DIE after this step\033[0m"
  echo -e "\033[0;33mWill you be dual booting?\033[0m"
  echo -e "\033[0;33m1. Yes (Uses first 50% of drive)\033[0m"
  echo -e "\033[0;33m2. No  (Uses 100% of drive)\033[0m"

  while [[ "$userans" != "1" && "$userans" != "2" ]]; do
    read userans
    if [ "$userans" == "1" ]; then
      parted -s /dev/$DRIVE mkpart primary 2048s 50%
      cryptsetup --verbose --type luks1 --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --iter-time 10000 --use-random --verify-passphrase luksFormat /dev/$DRIVE\1
      cryptsetup open /dev/$DRIVE\1 artix
      # Does grub support luks2 yet?
    elif [ "$userans" == "2" ]; then
      parted -s /dev/$DRIVE mkpart primary 2048s 100%
      cryptsetup --verbose --type luks1 --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --iter-time 10000 --use-random --verify-passphrase luksFormat /dev/$DRIVE\1
      cryptsetup open /dev/$DRIVE\1 artix
    fi
  done

  btrfs_setup
}

function regular_setup {
  MPATH=/dev/$DRIVE
  parted -s $MPATH mklabel msdos
  echo -e "\033[0;31mBe aware: Any currently installed Operating Systems will DIE after this step\033[0m"
  echo -e "\033[0;33mWill you be dual booting?\033[0m"
  echo -e "\033[0;33m1. Yes (Uses first 50% of drive)\033[0m"
  echo -e "\033[0;33m2. No  (Uses 100% of drive)\033[0m"

  while [[ "$userans" != "1" && "$userans" != "2" ]]; do
    read userans
    if [ "$userans" == "1" ]; then
      parted -s $MPATH mkpart primary 2048s 50%
    elif [ "$userans" == "2" ]; then
      parted -s $MPATH mkpart primary 2048s 100%
    fi
  done

  btrfs_setup
}

function btrfs_setup {
  # Create filesystems and subvolumes
  mkfs -t btrfs --force -L artix $MPATH
  mount -t btrfs -o compress=lzo $MPATH /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@snapshots
  btrfs subvolume create /mnt/@swap
  
  umount /mnt
  mkdir /swap
  # Set mount options
  o=defaults,x-mount.mkdir,compress=lzo,ssd,noatime

  # Remount partitions
  mount -o compress=lzo,subvol=@,$o $MPATH /mnt
  mount -o compress=lzo,subvol=@home,$o $MPATH /mnt/home
  mount -o compress=lzo,subvol=@snapshots,$o $MPATH /mnt/.snapshots
  mount -o subvol=@swap $MPATH /swap
  # mount -o subvol=@swap /dev/mapper/artix /swap
  
  # Make swap file
  touch /swap/swapfile
  chmod 600 /swap/swapfile
  chattr +C /swap/swapfile
  echo "Making 8GB swap file"
  dd if=/dev/zero of=/swap/swapfile bs=1M count=8192 status=progress
  mkswap /swap/swapfile
  swapon /swap/swapfile
  # UUID=$(blkid $MPATH | grep -o '\<UUID=[^[:blank:]]*' | cut -c 7- | rev | cut -c 2- | rev)
  # echo "UUID=$UUID /swap btrfs subvol=@swap 0 0" >> /etc/fstab
  # echo "/swap/swapfile none swap sw 0 0" >> /etc/fstab

  basestrap_setup
}

function basestrap_setup {

	while [[ "$CPU" != "1" && "$CPU" != "2" ]]; do 
	  echo -e "\033[0;33mWhat brand is your CPU?\033[0m"
	  echo -e "\033[0;31m1. AMD\033[0m"
	  echo -e "\033[0;34m2. Intel\033[0m"
		read CPU
	  if [ "$CPU" == "1" ]; then
	    cpu_package=amd-ucode
		elif [ " $CPU" == "2" ]; then
			cpu_package=intel-ucode
		fi
	done
	echo "CPU=$CPU" >> vars

	while [[ "$INIT" != "1" && "$INIT" != "2" && "$INIT" != "3" ]]; do
	  echo -e "\033[0;33mWhat init system do you want to use?\033[0m"
	  echo -e "\033[0;34m1. Runit\033[0m"
	  echo -e "\033[0;37m2. S6\033[0m"
	  echo -e "\033[0;31m3. OpenRC\033[0m"
	  read INIT
	  if [ "$INIT" == "1" ]; then
			init_system=runit
	  elif [ "$INIT" == "2" ]; then
			init_system=s6
	  elif [ "$INIT" == "3" ]; then
			init_system=openrc
	  fi 
	done
	echo "INIT=$INIT" >> vars
	
        base_packages="base base-devel linux-hardened linux-hardened-headers usbctl linux-firmware wget vim btrfs-progs grub mlocate dosfstools cryptsetup doas networkmanager network-manager-applet networkmanager-$init_system elogind-$init_system"
	basestrap /mnt $base_packages $cpu_package

	fstabgen -U /mnt >> /mnt/etc/fstab

	setup_next
}

function setup_next {
  # Merge previous variables and place 2nd script in chroot environment
  cp vars tmpvars
  cat 2chrooted.sh >> tmpvars
  mv tmpvars 2chrooted.sh
  mv *.ttf /mnt
  mv *.sh /mnt
  mv sysfiles/* /mnt
  rm -rf sysfiles
  rm *.md
  rm -rf .git
  mv .* /mnt
  mv vars /mnt
  echo -e "\033[0;33mNow run the following commands manually\033[0m"
  echo -e "\033[1;36martix-chroot /mnt\033[0m"
  echo -e "\033[1;36mbash 2chrooted.sh\033[0m"
}

repo_setup
