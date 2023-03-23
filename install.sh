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

# [-] add swap option based on available RAM.
# [-] write a wrapper for easy disk partitioning.

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

# minimal package set for a working arch system.

        # base :

        l       'linux'                 # linux kernel and modules.
                'linux-firmware'        # firmware files for linux.

                'base'                  # defines a basic arch installation.
                'base-devel'            # tools to build arch linux packages.

                'grub'                  # choses os kernel to boot.
                'efibootmgr'            # manages the boot process.

                'noto-fonts'            # typeface to write/read any language.
                'xdg-user-dirs'         # manages default directories for users.
                'seahorse'              # encryption keys.


        # connectivity :

                'networkmanager'        # manages network connections.
                'bluez'                 # manages bluetooth connections.

        # audio :

                'pulseaudio'            # A featureful, general-purpose sound server.
                'pulseaudio-alsa'       # ALSA Configuration for PulseAudio.
                'pulseaudio-bluetooth'  # Bluetooth support for PulseAudio.

        # display :

                'xorg-server'           # xorg display server.
                'xorg-xinit'            # xinit ~ to start xorg server.
                'xorg-xclipboard'       # xclipboard ~ clipboard manager.

                'picom'                 # X compositor.
                'dunst'                 # notification daemon.

        # theme :

                'feh'                   # desktop wallpaper.
                'gnome-themes-extra'    # window themes.
                'papirus-icon-theme'    # icon themes.
        
        # shell :

                'fish'                  # shell with syntax highlighting and tab completion.
                'fisher'                # package manager for the fish shell.
                'tldr'                  # simplified man pages.

                'exa'                   # ls replacement.
                'bat'                   # cat replacement.

        # editor :

                'git'                   # distributed version control system
                'neovim'                # hyperextensible Vim-based text editor

                'fd'                    # fast and user-friendly alternative to find
                'ripgrep'               # search tool that combines the usability of ag with the raw speed of grep

                'nodejs'                # Evented I/O for V8 javascript
                'npm'                   # package manager for javascript

# Below apps have specified tags/workspace assigned only where, they can spawn :

# tag [0] ~ floating/current tag

        'gnome-screenshot'      # screenshot tool.
	'gcolor3'               # color picker.

	'nautilus'              # file manager.
	'unzip'                 # extract/view .zip archives.
	'mtpfs'                 # read/write to MTP devices.
	'libmtp'                # MTP support.
	'gvfs'                  # gnome virtual file system for mounting.
	'gvfs-mtp'              # gnome virtual file system for MTP devices.
	'android-tools'         # android platform tools.
	'android-udev'          # udev rules to connect to android.

# tag [1] ~ terminal

        'btop'                  # monitor of system resources
        'gdu'                   # Fast disk usage analyzer
        'bandwhich'             # bandwidth utilization tool
        'calc'                  # Arbitrary precision console calculator
        'cmus'                  # Feature-rich ncurses-based music player
        'ufw'                   # CLI tool for managing a netfilter firewall.

# tag [2] ~ browser

	'firefox'               # primary browser.
	'chromium'              # secondary browser.
	'torbrowser-launcher'   # tertiary browser.

# tag [3] ~ Docs

	'gedit'                 # text editor.
	'evince'                # doc viewer.
	'ristretto'             # image viewer.

# tag [4] ~ canvas

	'gimp'                  # image editor.
	'inkscape'              # vector art.
	'mypaint'               # raster art.

# tag [5] ~ utils

        'pavucontrol'           # control device volume.
        'blueman'               # connect to bluetooth devices.
        'font-manager'          # install fonts.
        'lxappearance'          # theme switcher.
        'lxinput-gtk3'          # configure keyboard & mouse.

	'torrential'            # torrent client.
	'gnome-multi-writer'    # iso file writer.
	'gnome-disk-utility'    # disk management.

# tag [6] ~ content

	'vlc'                   # media player.
	'gnome-podcasts'        # podcasts app.

	)

	for app in "${apps[@]}"; do
        pacstrap -K /mnt "$app"
	done

# generate fstab file.
genfstab -U /mnt >> /mnt/etc/fstab

}

setup () {

# write script to /mnt
cat > /mnt/setup.sh <<- EOM
#!/bin/bash
# This script sets up the installed arch system.

multilib() {
        echo "" >> /etc/pacman.conf
        echo "[multilib]" >> /etc/pacman.conf
        echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
}

date-time () {
        ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
        timedatectl set-ntp true
        hwclock --systohc
}
    
locale () {
        sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
        locale-gen
        localectl set-locale LANG=en_US.UTF-8
}
                        
users () {
        # set the root password.
        echo "Specify root password. This will be used to authorize root commands."
        passwd

        # add regular user.
        echo "Specify username. This will be used to identify your account on this machine."
        read -r userName;
        useradd -m -G wheel -s /bin/bash "$userName"

        # set password for new user.
        echo "Specify password for regular user : $userName."
        passwd "$userName"

        # enable sudo for wheel group.
        sed -i 's/# %wheel ALL=(ALL:ALL) ALL/ %wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

        # create directories for user.
        xdg-user-dirs-update
}

network () {
        systemctl enable NetworkManager
        systemctl enable ufw

        # create the hostname file.
        echo "Specify hostname. This will be used to identify your machine on a network."
        read -r hostName; echo "$hostName" > /etc/hostname

        # add matching entries to '/etc/hosts'.
        # ( if the system has a permanent IP address, it should be used instead of 127.0.1.1 )
        echo -e 127.0.0.1'\t'localhost'\n'::1'\t\t'localhost'\n'127.0.1.1'\t'$hostName >> /etc/hosts

        ufw default allow outgoing
        ufw default deny incoming
}

bluetooth () {
        lsmod | grep btusb
        rfkill unblock bluetooth
        systemctl enable bluetooth.service
}

# clone suckless fork. (this command also creates .config dir as root)
git clone https://gitlab.com/workflow-setup/suckless.git  /home/"$userName"/.config/suckless

# install suckless terminal
cd /home/"$userName"/.config/suckless/st
make clean install; cd "$current_dir"

# set theme for fish shell.
fish -c "fisher install jomik/fish-gruvbox"    

# set defaults.
chsh --shell /bin/fish "$userName"
echo "export VISUAL=nvim" | tee -a /etc/profile
echo "export EDITOR=$VISUAL" | tee -a /etc/profile
echo "export TERMINAL=st" | tee -a /etc/profile

# install dynamic window manager.
cd /home/"$userName"/.config/suckless/dwm
make clean install; cd "$current_dir"

}

grub () {

# install required packages.
pacman -S grub efibootmgr --noconfirm

# create directory to mount EFI partition.
mkdir /boot/efi

# mount the EFI partition.
mount /dev/nvme0n1p1 /boot/efi

# install grub.
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi

# enable logs.
sed -i 's/loglevel=3 quiet/loglevel=3/' /etc/default/grub

# generate grub config.
grub-mkconfig -o /boot/grub/grub.cfg

}

config () {

    # download dot files into their desired paths.
    repo="https://gitlab.com/workflow-setup/arch/-/raw/main"

    # 'xinitrc'
    curl "$repo"/.config/.xinitrc -o  /home/"$userName"/.xinitrc
    
    # 'picom'
    mkdir -p /home/"$userName"/.config/picom
    curl "$repo"/.config/picom/picom.conf -o /home/"$userName"/.config/picom/picom.conf 

    # 'fish'
    mkdir -p /home/"$userName"/.config/fish/functions
    curl "$repo"/.config/fish/config.fish -o /home/"$userName"/.config/fish/config.fish 
    curl "$repo"/.config/fish/functions/fish_greeting.fish -o /home/"$userName"/.config/fish/functions/fish_greeting.fish 

    # wallpaper for 'feh'
    mkdir -p /home/"$userName"/Pictures
    curl "$repo"/assets/wallpaper.jpg -o /home/"$userName"/Pictures/wallpaper.jpg 

    # reset permissions.
    chown -R  "$userName" /home/"$userName"/.config
    chown -R :"$userName" /home/"$userName"/.config
    
    chown -R  "$userName" /home/"$userName"/Pictures
    chown -R :"$userName" /home/"$userName"/Pictures

}

misc() {

# enable TRIM for SSDs.
systemctl enable fstrim.timer

# bug fix ~ reinstall pambase.
pacman -S pambase --noconfirm

}

# Mark pwd
current_dir=$PWD

# Setup ...

multilib

timezone
locale
users

network
bluetooth
audio
chipset

tui
gui
grub

config
misc

# Clean dir & exit.

rm setup.sh
exit

EOM

# run script from /mnt with arch-chroot.
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

