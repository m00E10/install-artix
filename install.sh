DRIVE=sda
HOSTE=artix
ADMIN=admin
USER1=user

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +100M # 100 MB boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
  +16G # 16GB of SWAP
  n # new partition
  p # primary partition
    # start at first available sector
    # end at last available sector
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  t # change a partition type
  2 # change our second partition
  82 # change it to swap type
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

mkfs.ext4 -L BOOT /dev/$DRIVE\1
mkswap    -L SWAP /dev/$DRIVE\2
mkfs.ext4 -L ROOT /dev/$DRIVE\3

mkdir  /mnt/boot
mount  /dev/$DRIVE\1  /mnt/boot
swapon /dev/$DRIVE\2
mount  /dev/$DRIVE\3  /mnt


basestrap /mnt base base-devel openrc elogind-openrc linux-hardened \
               linux-hardened-headers linux-firmware
fstabgen -L /mnt           >>  /mnt/etc/fstab
# LABEL=BOOT /boot ext4  default,noatime  0 2               
nano /mnt/etc/fstab


artix-chroot /mnt
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "en_US.UTF-8 UTF-8"   >>  /etc/locale.gen
locale-gen
echo "LANG=en_US.utf8"     >>  /etc/locale.conf
echo "LANGUAGE=en_US"      >>  /etc/locale.conf
echo "LC_ALL=C"            >>  /etc/locale.conf


pacman -S grub os-prober doas dhclient wpa_supplicant networkmanager \
          networkmanager-openrc --noconfirm
grub-install --recheck --target=i386-pc /dev/$DRIVE
grub-mkconfig -o /boot/grub/grub.cfg

echo $HOSTE                             > /etc/hostname
echo "hostname=$HOSTE"                  > /etc/conf.d/hostname
echo "127.0.0.1 localhost"              > /etc/hosts
echo "::1       localhost"              > /etc/hosts
echo "127.0.0.1 $HOSTE.localnet $HOSTE" > /etc/hosts


pacman -Syu git base-devel man-pages man-db tmux htop sway xworg-xwayland   \
            i3status-rust wireguard-tools wl-clipboard tree cronie torsocks \
            firefox unzip wget weechat wireguard-openrc cronie-openrc       \
            noto-fonts noto-fonts-emoji noto-fonts-extra --noconfirm
pacman -Rns sudo vi nano --noconfirm

ln -s /usr/bin/doas /usr/bin/sudo
ln -s /usr/bin/vim  /usr/bin/vi
ln -s /usr/bin/vim  /usr/bin/nano

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

echo "permit persist $ADMIN"                               >> /etc/doas.conf
echo "permit nopass  $USER1 cmd poweroff args"             >> /etc/doas.conf
echo "permit nopass  $USER1 cmd wg-quick args up bridge"   >> /etc/doas.conf
echo "permit nopass  $USER1 cmd wg-quick args down bridge" >> /etc/doas.conf


mkdir -p /home/$USER1/.local/share/fonts
cd       /home/$USER1/.local/share/fonts
wget https://github.com/m00E10/install-artix/raw/main/iPortfolio.ttf
fc-cache -f -v

mkdir -p /home/$USER1/.config/gtk-3.0
echo "[Settings]"                               >> /home/$USER1/.config/gtk-3.0/settings.ini
echo "gtk-icon-theme-name = Adwaita"            >> /home/$USER1/gtk-3.0/settings.ini
echo "gtk-theme-name = Adwaita"                 >> /home/$USER1/gtk-3.0/settings.ini
echo "gtk-font-name = DejaVu Sans 11"           >> /home/$USER1/.config/gtk-3.0/settings.ini
echo "gtk-application-prefer-dark-theme = true" >> /home/$USER1/.config/gtk-3.0/settings.ini

cd /home/$USER1; git clone https://github.com/m00E10/dotfiles; cd dotfiles
mv .* ../; cd ..; rm -rf dotfiles
chown -hR $USER1 /home/$USER1

exit
umount -R /mnt
reboot
