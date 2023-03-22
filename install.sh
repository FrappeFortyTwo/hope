#!/bin/bash
# This script installs a custom arch system.

verify_uefi () {

# check if system is booted in UEFI mode.
if [ ! -d "/sys/firmware/efi/efivars" ]
then
    # if not, display error & exit.
   echo "[Error!] Reboot in UEFI mode and try again."
   exit 1
fi

}

partition_disk () {

# [-] Add swap option based on available RAM.
# [-] Write a wrapper for easy disk partitioning.

# delete existing partition table.
wipefs -a -f /dev/nvme0n1

# create partitions :

# 1. /dev/nvme0n1p1 for efi  partition taking +512M.
# 2. /dev/nvme0n1p2 for root partition taking rest of the disk.

(
echo n      # create new partition (for EFI).
echo p      # set partition type to primary.
echo        # set default partition number.
echo        # set default first sector.
echo +512M  # set +512 as last sector.
echo n      # create new partition (for Root).
echo p      # set partition type to primary.
echo        # set default partition number.
echo        # set default first sector.
echo        # set default last sector (use rest of the disk).
echo w      # write changes.
) | fdisk /dev/nvme0n1 -w always -W always

# format the created paritions :

mkfs.fat -F32 /dev/nvme0n1p1 # efi partion.
mkfs.ext4     /dev/nvme0n1p2 # root partition.

# mount the filesystem.
mount /dev/nvme0n1p2 /mnt

}

install_packages () {

# update mirrorlist. 
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

apps=(

# Minimal package set to for a working arch system.

    l   'linux'                 # linux kernel ~ 
        'linux-firmware'        # Firmware files for Linux

        'base'                  # Minimal package set to define a basic Arch Linux installation
        'base-devel'            # Basic tools to build Arch Linux packages

        'grub'                  # GNU GRand Unified Bootloader 
        'efibootmgr'            # Linux user-space application to modify the EFI Boot Manager

        'networkmanager'        # Network connection manager
        'bluez'                 # Daemons for the bluetooth protocol stack
        'bluez-utils'           # Development and debugging utils for the bluetooth protocol stack

        'noto-fonts'            # Google Noto TTF fonts
        'xdg-user-dirs'         # Manage user dirs like ~/Desktop, ~/Music, etc

# Terminal : packages for a seamless shell experience.

        'fish'                  # smart and user-friendly command line shell
        'fisher'                # package manager for the fish shell

        'tldr'                  # collection of simplified and community-driven man pages.
        'man-db'                # utility for reading man pages

        'exa'                   # ls replacement
        'bat'                   # cat clone with syntax highlighting and git integration

# Personal Development Environment :

        'git'                   # distributed version control system
        'neovim'                # hyperextensible Vim-based text editor

        'fd'                    # fast and user-friendly alternative to find
        'ripgrep'               # search tool that combines the usability of ag with the raw speed of grep

        'nodejs'                # Evented I/O for V8 javascript
        'npm'                   # package manager for javascript

# Settings :

        'font-manager'          # install fonts.
        'blueman'               # connect to bluetooth devices.

# Connectivity :

        'ufw'                   # CLI tool for managing a netfilter firewall

# Audio :

        'pulseaudio'            # A featureful, general-purpose sound server
        'pulseaudio-alsa'       # ALSA Configuration for PulseAudio
        'pulseaudio-bluetooth'  # Bluetooth support for PulseAudio
        'pavucontrol'           # PulseAudio Volume Control

# Display Server :

    'xorg-server'               # xorg display server.
    'xorg-xinit'                # xinit ~ to start xorg server.
    'xorg-xclipboard'           # xclipboard ~ clipboard manager.

    'picom'                     # X compositor.
    'feh'                       # desktop wallpaper.
    'dunst'                     # notification daemon.
    'dmenu'                     # app menu.
    'lxappearance'              # theme switcher.
    'lxinput-gtk3'              # configure keyboard & mouse.
    'gnome-themes-extra'        # window themes.
    'papirus-icon-theme'        # icon themes.
    'pcmanfm-gtk3'              # file manager.
    'firefox'                   # browser.

# Tools :

        'btop'                  # monitor of system resources
        'gdu'                   # Fast disk usage analyzer
        'bandwhich'             # bandwidth utilization tool

# Apps :

        'cmus'                  # Feature-rich ncurses-based music player
        'calc'                  # Arbitrary precision console calculator
		
		
		'gnome-screenshot' # screenshot tool.
		'gcolor3'          # color picker.

		'nautilus'      # file manager.
		'unzip'         # extract/view .zip archives.
		'mtpfs'         # read/write to MTP devices.
		'libmtp'        # MTP support.
		'gvfs'          # gnome virtual file system for mounting.
		'gvfs-mtp'      # gnome virtual file system for MTP devices.
		'android-tools' # android platform tools.
		'android-udev'  # udev rules to connect to android.

# Grub

		
		
	'firefox'             # primary browser.
		'chromium'            # secondary browser.
		'torbrowser-launcher' # tertiary browser.

		# tag [3] : docs

		'gedit'     # text editor.
		'evince'    # doc viewer.
		'ristretto' # image viewer.

		# tag [4] : canvas

		'gimp'     # image editor.
		'inkscape' # vector art.
		'mypaint'  # raster art.

		'peek'       # GIF recorder.
		'obs-studio' # screen cast/record.
		'audacity'   # audio editor.
		'pitivi'     # video editor.

		# tag [5] : utils

		'torrential'         # torrent client.
		'gnome-multi-writer' # iso file writer.
		'gnome-disk-utility' # disk management.
		'font-manager'       # font manager.
		'seahorse'           # encryption keys.
		'lxinput-gtk3'       # configure keyboard & mouse.
		'piper'				 # logitech G suite.

		# tag [6] : content

		'vlc'            # media player.
		'gnome-podcasts' # podcasts app.


		

		

	)

	for app in "${apps[@]}"; do
        pacstrap -K /mnt "$app"
	done

# generate fstab file.
genfstab -U /mnt >> /mnt/etc/fstab

}

setup () {

# download setup script from repo into /mnt.
curl https://gitlab.com/workflow-setup/arch/-/raw/main/setup.sh -o /mnt/setup.sh

# run the setup script from /mnt with arch-chroot.
arch-chroot /mnt bash setup.sh

}

# Install arch linux :

check_uefi      # verify boot mode.
sync_packages   # update mirror list.
prepare_disk    # partion & format disk.
install         # install vanilla arch.
setup           # setup system.

# unmount paritions & reboot.

umount -R /mnt

