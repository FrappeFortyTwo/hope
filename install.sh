#!/bin/bash
# This script installs the base arch system.

check_uefi () {

# check if system is booted in UEFI mode.
if [ ! -d "/sys/firmware/efi/efivars" ]
then
    # if not, display error & exit.
   echo "[Error!] Reboot in UEFI mode and try again."
   exit 1
fi

}

sync_packages () {

# update mirror list & refresh packages.
reflector --country India --protocol https --save /etc/pacman.d/mirrorlist

pacman -Syy

}

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

install () {

# install essential packages.
pacstrap /mnt linux linux-firmware base base-devel

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

