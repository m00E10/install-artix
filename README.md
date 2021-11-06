# install-artix
# install-artix
This installs artix from a base runit ISO in non-UEFI mode with BTRFS, full
LUKS encryption, hardened kernel, and sway.

Not completely automated. Manual work needs to be done when jumping from
pre-chroot to post-chroot.

Run the install scripts in their order.

After booting into the live base artix environment


1. Login as root, root:artix
2. pacman -Sy git
3. git clone https://github.com/m00E10/install-artix
4. cp -r install-artix/{,.}* .
5. rm -rf install-artix
6. bash 1prechroot.sh

TODO:
Make base hardening script
   setup of firewall
   kernel hardening
   auto start VPN
Include the making of swap space
Make a version thats just one big script so install is easy as curl https://github.com/m00E10/install-artix/1.sh | bash
