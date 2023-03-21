#!/bin/bash
# This script installs the base arch system.

# VERIFY BOOT MODE

check_uefi () {

# check if system is booted in UEFI mode.
if [ ! -d "/sys/firmware/efi/efivars" ]
then
    # if not, display error & exit.
   echo "[Error!] Reboot in UEFI mode and try again."
   exit 1
fi

}

# CONNECT TO INTERNET

# Use iwctl to connect to a wifi, incase you're not on a wired connection.
# `iwctl --passphrase passphrase station device connect SSID`
# ex : iwctl --passphrase D@mnITTrudy station wlan0 connect ThePineappleIncident
# check internet connectio using 'ping google.com', response means internis working.

# PARTITION THE DISKS
# to identify the disks, use `lsblk`
# - [ ] Add Swap option based on RAM

prepare_disk () {

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

# UPDATE MIRROR LIST, THIS IS COPIED TO THE NEW SYSTEM

sync_packages () {

# update mirror list & refresh packages.
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syy

}

# INSTALL ESSENTIAL PACKAGES

install () {

apps=(

# Base System :

    l   'linux'                 # The Linux kernel and modules
        'linux-firmware'        # Firmware files for Linux

        'base'                  # Minimal package set to define a basic Arch Linux installation
        'base-devel'            # Basic tools to build Arch Linux packages

# Terminal :

        'fish'                  # smart and user-friendly command line shell
        'fisher'                # package manager for the fish shell

        'tldr'                  # collection of simplified and community-driven man pages.
        'man-db'                # utility for reading man pages

        'exa'                   # ls replacement
        'bat'                   # cat clone with syntax highlighting and git integration

# Personal Development Environment :

        'neovim'                # hyperextensible Vim-based text editor
        'git'                   # distributed version control system

        'fd'                    # fast and user-friendly alternative to find
        'ripgrep'               # search tool that combines the usability of ag with the raw speed of grep

        'nodejs'                # Evented I/O for V8 javascript
        'npm'                   # package manager for javascript

# Essentials :

        'noto-fonts'            # Google Noto TTF fonts
        'xdg-user-dirs'         # Manage user dirs like ~/Desktop, ~/Music, etc

# Settings :

        'font-manager'          # Font management for GTK+ DEs
        'ufw'                   # CLI tool for managing a netfilter firewall

# Hardware :

        'networkmanager'        # Network connection manager

        'blueman'               # GTK+ Bluetooth Manager
        'bluez'                 # Daemons for the bluetooth protocol stack
        'bluez-utils'           # Development and debugging utils for the bluetooth protocol stack

        'pulseaudio'            # A featureful, general-purpose sound server
        'pulseaudio-alsa'       # ALSA Configuration for PulseAudio
        'pulseaudio-bluetooth'  # Bluetooth support for PulseAudio
        'pavucontrol'           # PulseAudio Volume Control

        'xorg-server'           # xorg display server.
        'xorg-init'             # xorg initialisation program
        'xorg-xclipboard'       # x clipboard manager


        
# Tools :

        'btop'                  # monitor of system resources
        'gdu'                   # Fast disk usage analyzer
        'bandwhich'             # bandwidth utilization tool

# Settings :


# Apps :

        'cmus'                  # Feature-rich ncurses-based music player
        'calc'                  # Arbitrary precision console calculator
		
		
		
		
		

		

		

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

