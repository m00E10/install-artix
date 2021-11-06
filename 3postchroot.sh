#!/bin/bash -x

function connectivity_check {
  if [ "$INIT" == "1" ]; then
    ln -s /etc/runit/sv/NetworkManager /run/runit/service
    sv up NetworkManager
  elif [ "$INIT" == "2" ]; then
    s6-rc-bundle-update add default NetworkManager-srv
    s6-rc -u change NetworkManager-srv
  elif [ "$INIT" == "3" ]; then
    rc-update add NetworkManager default
    rc-service NetworkManager start
  fi

  while [ "$userans" != y ]; do
    sleep 2
    echo -e "\033[0;33mTesting connectivity, if google.com cannot be reached CTRL+C out of script, fix manually, then rerun\033[0m"
    curl google.com
    echo -e "\033[0;33mIs google.com reachable? y/n\033[0m"
    read userans
  done
}

function create_keyfile {
  echo -e "\033[0;33mCreating keyfile so we don't have to enter decryption password twice upon boot\033[0m"
  dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
  cryptsetup luksAddKey /dev/$DRIVE\1 /crypto_keyfile.bin
  mkinitcpio -p linux-hardened
  chmod 000 /crypto_keyfile.bin
  chmod -R g-rwx,o-rwx /boot
}

function repo_setup {
  echo "[universe]" >> /etc/pacman.conf
  echo "Server = https://universe.artixlinux.org/$arch" >> /etc/pacman.conf
  echo "Server = https://mirror1.artixlinux.org/universe/$arch" >> /etc/pacman.conf
  echo "Server = https://mirror.pascalpuffke.de/artix-universe/$arch" >> /etc/pacman.conf
  echo "Server = https://artixlinux.qontinuum.space:4443/universe/os/$arch" >> /etc/pacman.conf
  echo "Server = https://mirror.alphvino.com/artix-universe/$arch" >> /etc/pacman.conf
  echo "[omniverse]" >> /etc/pacman.conf
  echo "Server = http://omniverse.artixlinux.org/$arch" >> /etc/pacman.conf 
  echo "[lib32]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
  pacman -Sy

  pacman -S artix-archlinux-support archlinux-mirrorlist
  sleep 2
  echo "[extra]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
  echo "[community]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
  echo "[multilib]" >> /etc/pacman.conf
  echo "Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
  sleep 5 # Sometimes it throws errors if this runs too quickly after, waiting a bit ensures it doesn't get upset
  pacman-key --populate archlinux

  echo -e "\033[0;33mDo you want to install the Black Arch Repos?\033[0m"
  echo -e "\033[0;33mcurl https://blackarch.org/strap.sh | bash\033[0m"
  echo -e "\033[0;33m1. Yes\033[0m"
  echo -e "\033[0;33m2. No\033[0m"
  read BAR
  if [ "$BAR" == "1" ]; then
    curl https://blackarch.org/strap.sh | bash
  fi

  pacman -Sy
}

function install_packages {
  # ARTIXV3, install yay, pipewire, setup smithay, wayland-rs, yofi, fireplace with trizen (test and document in VM),
  pacman -S git base-devel man-pages man-db neofetch tmux tmuxp htop sway \
  xorg-xwayland glfw-wayland python-glfw wayland-docs glu i3status-rust \
  pipewire pipewire-pulse pavucontrol cmus wireguard-tools openntpd \
  wl-clipboard grim slurp swappy noto-fonts noto-fonts-emoji noto-fonts-extra \
  acpi unzip tor tree yay torsocks cronie flatpak bubblewrap-suid
  # Whats worse, to have bubble wrap be a possible PE by using the SUID variant,
  # or allowing any user to make namespaces? Current research leads me to
  # believe suid bubblewrap is better, but I am not 100% sure

  cp -r /usr/share/pipewire/ /etc/
  echo -e "\033[0;33mUncomment the following two lines\033[0m"
  echo -e "\033[0;33m{ path = \"/usr/bin/pipewire-media-session\"  args = \"\" }\033[0m"
  echo -e "\033[0;33m{ path = \"/usr/bin/pipewire\" args = \"-c pipewire-pulse.conf\" }\033[0m"
  echo -e "\033[0;33mBoth are near the end of the file\033[0m"
	sleep 5
  vim /etc/pipewire/pipewire.conf 

  if [ "$INIT" == "1" ]; then
    pacman -S wireguard-runit openntpd-runit cronie-runit
    ln -s /etc/runit/sv/wireguard /run/runit/service
    ln -s /etc/runit/sv/openntpd /run/runit/service
    ln -s /etc/runit/sv/cronie /run/runit/service
    sv up wireguard
    sv up openntpd
    sv up chronie
  elif [ "$INIT" == "2" ]; then
    pacman -S wireguard-s6 openntpd-s6 cronie-s6
    s6-rc-bundle-update add default wireguard
    s6-rc-bundle-update add default openntpd
    s6-rc-bundle-update add default cronie
    s6-rc -u change wireguard
    s6-rc -u change openntpd
    s6-rc -u change cronie
  elif [ "$INIT" == "3" ]; then
    pacman -S wireguard-openrc openntpd-openrc cronie-openrc
    rc-update add wireguard default
    rc-update add ntpd default
    rc-update add cronie default
    rc-service cronie start
    rc-service ntpd start
    rc-service wireguard start
  fi

  # Install video drivers
  echo -e "\033[0;33mWhat is your GPU?\033[0m"
  echo -e "\033[0;31m1. AMD\033[0m"
  echo -e "\033[0;32m2. Nvidia (Untested)\033[0m"
  echo -e "\033[0;34m3. Intel\033[0m"
  read GPU
  if [ "$GPU" == "1" ]; then
    pacman -S vulkan-radeon vulkan-mesa-layers
  elif [ "$GPU" == "2" ]; then # Untested if this works I don't have an Nvidia card lol
    echo -e "\033[0;33mI don't think this works with wayland but good luck heres the packages\033[0m"
    sleep 2
    pacman -S nvidia-utils vulkan-mesa-layers
  elif [ "$GPU" == "3" ]; then
    pacman -S vulkan-intel vulkan-mesa-layers
  fi

  wg showconf wg0 > /etc/wireguard/wg0.conf
}

function make_user {
  echo -e "\033[0;33mInput the name of your standard user now\033[0m"
  read USER2
  useradd -m $USER2
  passwd $USER2
  usermod -a -G video $USER2
  echo "permit nopass $USER2 cmd virsh args net-start default"
  echo "permit nopass $USER2 cmd poweroff args"
}

function vm_setup {
  echo -e "\033[0;33mDo you want to setup virtualization?\033[0m"
  echo -e "\033[0;32m1. Yes\033[0m"
  echo -e "\033[0;31m2. No\033[0m"
  read VIRTUAL
  if [ "$VIRTUAL" == "1" ]; then
    pacman -S virt-manager qemu bridge-utils dnsmasq ebtables qemu-guest-agent libvirt
    if [ "$INIT" == "1" ]; then 
      pacman -S libvirt-runit qemu-guest-agent-runit
      ln -s /etc/runit/sv/libvirtd /run/runit/service
      sv up libvirtd
      ln -s /etc/runit/sv/qemu-guest-agent /run/runit/service
      sv up qemu-guest-agent
      ln -s /etc/runit/sv/virtlockd /run/runit/service
      sv up virtlockd
      ln -s /etc/runit/sv/virtlogd /run/runit/service
      sv up virtlogd
      ln -s /etc/runit/sv/nftables /run/runit/service
      sv up nftables
    elif [ "$INIT" == "2" ]; then
      pacman -S libvirt-s6 qemu-guest-agent-s6
      s6-rc-bundle-update add default libvirtd
      s6-rc-bundle-update add default qemu-guest-agent
      s6-rc -u change libvirtd
      s6-rc -u change qemu-guest-agent
    elif [ "$INIT" == "3" ]; then
      pacman -S libvirt-openrc qemu-guest-agent-openrc
      rc-update add libvirtd default
      rc-update add libvirt-guests default
      rc-update add qemu-guest-agent default
      rc-update add virtlockd
      rc-update add virtlogd
      rc-service libvirtd start
      rc-service libvirt-guests start
      rc-service qemu-guest-agent start
      rc-service virtlockd start
      rc-service virtlogd start
    fi
  
    sleep 3
    usermod -a -G libvirt $USER2
  fi
}

function ssh_setup {
  echo -e "\033[0;33mDo you want to setup SSH Server?\033[0m"
  echo -e "\033[0;32m1. Yes\033[0m"
  echo -e "\033[0;31m2. No\033[0m"
  read SSHANS
  pacman -S --noconfirm openssh
  if [ "$SSHANS" == "1" ]; then
    if [ "$INIT" == "1" ]; then
      pacman -S openssh-runit
      ln -s /etc/runit/sv/sshd /run/runit/service
      sv up sshd
    elif [ "$INIT" == "2" ]; then
      pacman -S openssh-s6
      s6-rc-bundle-update add default sshd
      s6-rc -u change sshd
    elif [ "$INIT" == "3" ]; then
      pacman -S openssh-openrc
      rc-update add sshd default
      rc-service sshd start
     fi
  fi
}

function setup_next {
  # Remove yucky programs
  pacman -Rns --noconfirm sudo 
  pacman -Rns --noconfirm vi
  pacman -Rns --noconfirm nano
  ln -s /usr/bin/doas /usr/bin/sudo
  ln -s /usr/bin/vim /usr/bin/vi
  ln -s /usr/bin/vim /usr/bin/nano
  sleep 2

  mv 4finalconfig.sh /home/$USER2
  mv Mx437_Portfolio_6x8.ttf /home/$USER2
  rm /.bash*
  rm /*chroot*
  rm /crypto_keyfile.bin
  rm -rf /.git
  rm -rf /.gnupg

  echo -e "\033[0;33mRecommended: Change roots shell to nologin\033[0m"
  sleep 5
  vim /etc/passwd

  echo -e "\033[0;33mNow exit\033[0m"
  echo -e "\033[0;33mLogin as your standard user and then run\033[0m"
  echo -e "\033[1;36mbash 4finalconfig.sh\033[0m"
}

connectivity_check
create_keyfile
repo_setup
install_packages
make_user
vm_setup
ssh_setup
setup_next
