#!/bin/bash

DRIVE=sda
HOSTE=artix
ADMIN=admin
USER1=user

function repo_setup {
	pacman -Sy
	pacman -S parted artix-archlinux-support
	pacman-key --populate archlinux
	
	echo "[extra]"                                         >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf
	echo "[community]" 				       >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf
	echo "[multilib]"                                      >> /etc/pacman.conf
	echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf
	
  	pacman -Syu git base-devel man-pages man-db tmux htop sway xorg-xwayland \
              i3status-rust wireguard-tools wl-clipboard tree cronie torsocks 	 \
              firefox unzip wget weechat wireguard-openrc cronie-openrc          \
              noto-fonts noto-fonts-emoji noto-fonts-extra wget alsa-utils
	      
	pacman -Rns sudo
  	ln -s /usr/bin/doas /usr/bin/sudo
}

function daemon_setup {
  	rc-update add wireguard default
  	rc-update add cronie    default
  	wg showconf wg0 > /etc/wireguard/wg0.conf
  	cd /bin
  	wget https://gitlab.com/madaidan/secure-time-sync/-/raw/master/secure-time-sync.sh
  	chmod +x secure-time-sync.sh
  	crontab -l > cron_bkp
  	echo \"0 * * * * /bin/secure-time-sync.sh\" >> cron_bkp
  	crontab cron_bkp
  	rm cron_bkp
}

function theming {
  	mkdir -p /home/$USER1/.local/share/fonts
  	cd       /home/$USER1/.local/share/fonts
  	wget https://github.com/m00E10/fonts/raw/main/iPortfolio.ttf
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
}

function next_stage {
	wget https://raw.githubusercontent.com/m00E10/install-artix/main/4finalconfig.sh
	mv 4finalconfig.sh /home/$ADMIN
	echo "Now login as your admin user and run bash 4finalconfig.sh"
}

repo_setup
daemon_setup
theming
next_stage
