DRIVE=sda
HOSTE=artix
ADMIN=admin
USER1=user

function disk_setup {
(
echo o     # Create new DOS partition layout
echo n     # Create 100MB BOOT partition
echo p
echo 1
echo  
echo +100M
echo n     # Create 16GB SWAP partition
echo p
echo 2
echo  
echo +16G
echo n     # Create ROOT partition out of remaining space
echo p
echo 3
echo  
echo  
echo a     # Set first partition as bootable
echo 1
echo t     # Set second partition as type 82 (swap)
echo 2
echo 82
echo p
echo w
) | fdisk /dev/$DRIVE

	mkfs.ext4 -L BOOT /dev/$DRIVE\1
	mkswap    -L SWAP /dev/$DRIVE\2
	mkfs.ext4 -L ROOT /dev/$DRIVE\3

	mkdir  /mnt/boot
	mount  /dev/$DRIVE\1  /mnt/boot
	swapon /dev/$DRIVE\2
	mount  /dev/$DRIVE\3  /mnt
}

function base_strap {
	basestrap   /mnt base base-devel openrc elogind-openrc linux-hardened \
	                 linux-hardened-headers linux-firmware wget
	fstabgen -L /mnt                                             >> /mnt/etc/fstab
	echo "LABEL=BOOT    /boot    ext4    default,noatime    0 2" >> /mnt/etc/fstab
	
	wget https://raw.githubusercontent.com/m00E10/install-artix/main/2chrooted.sh
	mv 2chrooted.sh /mnt/2chrooted.sh
	echo "Now run bash 2chrooted.sh"
	artix-chroot /mnt
}

disk_setup
base_strap	
