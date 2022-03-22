DRIVE=sda
HOSTE=artix
ADMIN=admin
USER1=user

function repo_setup {
	pacman -Sy
	pacman -S parted artix-archlinux-support
	pacman-key --populate archlinux
	echo "[omniverse]" >> /etc/pacman.conf
	echo "Server = http://omniverse.artixlinux.org/\$arch" >> /etc/pacman.conf
	echo "[extra]"     >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf
	echo "[community]" >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf
	echo "[multilib]"  >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf
}

function disk_setup {
(
echo o # Create new DOS partition layout
echo n # Create 100MB BOOT partition
echo p
echo 1
echo  
echo +100M
echo n # Create 16GB SWAP partition
echo p
echo 2
echo  
echo +16G
echo n # Create ROOT partition out of remaining space
echo p
echo 3
echo  
echo  
echo a # Set first partition as bootable
echo 1
echo t # Set second partition as type 82 (swap)
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
	                 linux-hardened-headers linux-firmware
	fstabgen -L /mnt                                             >> /mnt/etc/fstab
	echo "LABEL=BOOT    /boot    ext4    default,noatime    0 2" >> /mnt/etc/fstab

	echo "DRIVE=$DRIVE" >> /mnt/install.sh
	echo "HOSTE=$HOSTE" >> /mnt/install.sh
	echo "ADMIN=$ADMIN" >> /mnt/install.sh
	echo "USER1=$USER1" >> /mnt/install.sh
	echo '
	ln -sf /usr/share/zoneinfo/UTC /etc/localtime
	echo "en_US.UTF-8 UTF-8"   >>  /etc/locale.gen
	locale-gen
	echo "LANG=en_US.utf8"     >   /etc/locale.conf
	echo "LANGUAGE=en_US"      >>  /etc/locale.conf
	echo "LC_ALL=C"            >>  /etc/locale.conf


	pacman -S grub os-prober doas dhclient wpa_supplicant networkmanager \
	          networkmanager-openrc --noconfirm
	grub-install --recheck --target=i386-pc /dev/$DRIVE
	grub-mkconfig -o /boot/grub/grub.cfg

	echo $HOSTE                             >  /etc/hostname
	echo "hostname=$HOSTE"                  >  /etc/conf.d/hostname
	echo "127.0.0.1 localhost"              >> /etc/hosts
	echo "::1       localhost"              >> /etc/hosts
	echo "127.0.0.1 $HOSTE.localnet $HOSTE" >> /etc/hosts


	pacman -Syu git base-devel man-pages man-db tmux htop sway xorg-xwayland    \
	            i3status-rust wireguard-tools wl-clipboard tree cronie torsocks \
	            firefox unzip wget weechat wireguard-openrc cronie-openrc       \
	            noto-fonts noto-fonts-emoji noto-fonts-extra wget
	pacman -Rns sudo

	ln -s /usr/bin/doas /usr/bin/sudo

	rc-update add wireguard default
	rc-update add cronie    default
	wg showconf wg0 > /etc/wireguard/wg0.conf

	cd /bin
	wget https://gitlab.com/madaidan/secure-time-sync/-/raw/master/secure-time-sync.sh
	chmod +x secure-time-sync.sh
	crontab -l > cron_bkp
	echo "0 * * * * /bin/secure-time-sync.sh" >> cron_bkp
	crontab cron_bkp
	rm cron_bkp


	useradd -m $ADMIN
	useradd -m $USER1
	passwd $ADMIN
	passwd $USER1
	usermod -a -G video $USER1

	echo "Set password for root user"
	passwd
	echo "Set password for admin user"
	passwd $ADMIN
	echo "Set password for standard user"
	passwd $USER1

	echo "permit persist $ADMIN"                               >  /etc/doas.conf
	echo "permit nopass  $USER1 cmd poweroff args"             >> /etc/doas.conf
	echo "permit nopass  $USER1 cmd wg-quick args up bridge"   >> /etc/doas.conf
	echo "permit nopass  $USER1 cmd wg-quick args down bridge" >> /etc/doas.conf


	mkdir -p /home/$USER1/.local/share/fonts
	cd       /home/$USER1/.local/share/fonts
	wget https://github.com/m00E10/install-artix/raw/main/iPortfolio.ttf
	fc-cache -f -v

	mkdir -p /home/$USER1/.config/gtk-3.0
	echo "[Settings]"                               >  /home/$USER1/.config/gtk-3.0/settings.ini
	echo "gtk-icon-theme-name = Adwaita"            >> /home/$USER1/gtk-3.0/settings.ini
	echo "gtk-theme-name = Adwaita"                 >> /home/$USER1/gtk-3.0/settings.ini
	echo "gtk-font-name = DejaVu Sans 11"           >> /home/$USER1/.config/gtk-3.0/settings.ini
	echo "gtk-application-prefer-dark-theme = true" >> /home/$USER1/.config/gtk-3.0/settings.ini

	cd /home/$USER1; git clone https://github.com/m00E10/dotfiles; cd dotfiles
	mv .* ../; cd ..; rm -rf dotfiles
	chown -hR $USER1 /home/$USER1

	echo "Now run the following:"
	echo "exit"
	echo "umount -R /mnt"
	echo "reboot"
	' >> /mnt/install.sh

	echo "Run bash install.sh"
	artix-chroot /mnt
}

repo_setup
disk_setup
base_strap
