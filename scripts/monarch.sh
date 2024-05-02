#!/bin/bash

echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
						                                Arch Linux Install Script
					                        Creates Arch install with Xorg + Suckless suite

						                                  Created By: Monstroe
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"

echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Gathering Input
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"
prompt_for_password() {
    local password
    local confirm_password

    # Prompt user to enter password
    read -s -p "$1: " password
    read -s -p "$2: " confirm_password
    echo

    # Check if passwords match
    if [[ "$password" != "$confirm_password" ]]; then
        echo "Passwords do not match. Please try again."
        prompt_for_password
    else
        echo "$password"
    fi
}

echo 'These are the following disks in your device:'
echo "-------------------------------------------------"
lsblk -n -o NAME | grep -E 'sd[a-z]|nvme[0-9]' | awk '{print $1}'
echo "-------------------------------------------------"
read -p "Enter disk device to format (e.g., /dev/sda): " disk_device
if [ -d "/sys/firmware/efi" ]; then
    read -p "Enter size for EFI system partition in MiB: " efi_size
fi
read -p "Enter size for swap partition in MiB: " swap_size
echo

read -p "Enter hostname for this device: " hostname
read -p "Enter user name for the primary account: " user_name
user_passwd=$(prompt_for_password "Enter password for the primary account" "Confirm password for the primary account")
root_passwd=$(prompt_for_password "Enter password for the root account (MAKE THIS STRONG)" "Confirm password for the root account")
echo

echo "These are the following regions available for timezone selection:"
echo "-------------------------------------------------"
ls /usr/share/zoneinfo/
echo "-------------------------------------------------"
read -p "Enter your region (this will be used to set the timezone): " region
echo

echo "These are the following cities available in your region:"
echo "-------------------------------------------------"
ls /usr/share/zoneinfo/$(region)
echo "-------------------------------------------------"
read -p "Enter your city (this will be used to set the timezone): " city

echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Partitioning Disks
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"
disk_part1=${disk_device}1
disk_part2=${disk_device}2
disk_part3=${disk_device}3
if [[ "${disk_device}" =~ "nvme" ]]; then
    disk_part1=${disk_device}p1
    disk_part2=${disk_device}p2
    disk_part3=${disk_device}p3
fi

sgdisk --clear ${disk_device}
# Check if UEFI is enabled
if [ -d "/sys/firmware/efi" ]; then
    echo "UEFI system detected, partitioning disk..."
    sgdisk --new 1::+${efi_size}MiB --typecode=1:ef00 --change-name=1:"EFI System Partition" ${disk_device}
    sgdisk --new 2::+${swap_size}MiB --typecode=2:8200 --change-name=2:"Linux Swap" ${disk_device}
    sgdisk --new 3::-0 --typecode=3:8300 --change-name=3:"Linux File System" ${disk_device}

    echo "Formatting the partitions..."
    mkfs.fat -F 32 ${disk_part1}
    mkswap ${disk_part2}
    mkfs.ext4 ${disk_part3}

    echo "Mounting file systems..."
    mount --mkdir ${disk_part1} /mnt/boot
    swapon ${disk_part2}
    mount ${disk_part3} /mnt
else
    echo "BIOS system detected, partitioning disk..."
    sgdisk --new 1::+${swap_size}MiB --typecode=2:8200 --change-name=2:"Linux Swap" ${disk_device}
    sgdisk --new 2::-0 --typecode=3:8300 --change-name=3:"Linux File System" ${disk_device}

    echo "Formatting the partitions..."
    mkswap ${disk_part1}
    mkfs.ext4 ${disk_part2}

    echo "Mounting file systems..."
    swapon ${disk_part1}
    mount ${disk_part2} /mnt
fi

echo "Partitioning complete!"
partprobe ${disk_device} # reread partition table to ensure it is correct

echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                        Arch Install
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"
echo "Installing kernel and other important software..."
pacstrap -K /mnt base linux linux-firmware sof-firmware base-devel grub nano vim git networkmanager reflector ufw wget curl sudo --noconfirm --needed
echo "Kernel and software installed!"
genfstab -U /mnt >>/mnt/etc/fstab
echo "Generated /etc/fstab:"
echo "-------------------------------------------------"
cat /mnt/etc/fstab
echo "-------------------------------------------------"

echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Arch Configuration
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"

arch_configuration() {
    # Setting up Timezone
    echo "Setting up timezone..."
    ln -sf /usr/share/zoneinfo/${region}/${city} /etc/localtime
    hwclock --systohc

    # Setting up Locale
    echo "Setting up locale..."
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >/etc/locale.conf
    echo "KEYMAP=us" >/etc/vconsole.conf

    # Setting Hostname
    echo "Setting hostname..."
    echo "${hostname}" >/etc/hostname

    # Setting Root Password
    echo "Setting root password..."
    echo "root:${root_passwd}" | chpasswd

    # Creating Default User
    echo "Creating user..."
    useradd -m -G wheel -s /bin/bash ${user_name}
    echo "${user_name}:${user_passwd}" | chpasswd
    sed -i 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers

    # Setting up GRUB Bootloader
    echo "Setting up GRUB Bootloader..."
    if [ -d "/sys/firmware/efi" ]; then
        pacman -S efibootmgr --noconfirm --needed
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    else
        grub-install --target=i386-pc ${DISK_DEVICE}
    fi
    grub-mkconfig -o /boot/grub/grub.cfg

    # Editing pacman
    echo "Editing pacman config..."
    # Add color
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    # Add parallel downloading
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    # Add ILoveCandy Modifier
    sed -i '/ParallelDownloads/a ILoveCandy' /etc/pacman.conf

    # Set up Reflector
    echo "Setting up mirrors with reflector..."
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    sed -i 's/--latest 5/--latest 20/' /etc/xdg/reflector/reflector.conf
    sed -i 's/--sort age/--sort rate/' /etc/xdg/reflector/reflector.conf

    # Set up firewall
    echo "Setting up firewall with ufw..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw limit ssh
    ufw enable

    # Set up AUR
    echo "Setting up AUR with yay"
    cd /home/$(user_name)
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
}

# NOTE: The following code is from Chris Titus Tech's "ArchTitus" repository
microcode_install() {
    # Install microcode
    echo "Installing microcode..."
    proc_type=$(lscpu)
    if grep -E "GenuineIntel" <<<${proc_type}; then
        echo "Installing Intel microcode"
        pacman -S --noconfirm --needed intel-ucode
        proc_ucode=intel-ucode.img
    elif grep -E "AuthenticAMD" <<<${proc_type}; then
        echo "Installing AMD microcode"
        pacman -S --noconfirm --needed amd-ucode
        proc_ucode=amd-ucode.img
    fi
}

# NOTE: The following code is from Chris Titus Tech's "ArchTitus" repository
graphics_drivers_install() {
    # Install graphics drivers
    echo "Installing graphics drivers..."
    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<<${gpu_type}; then
        pacman -S --noconfirm --needed nvidia
        nvidia-xconfig
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        pacman -S --noconfirm --needed xf86-video-amdgpu
    elif grep -E "Integrated Graphics Controller" <<<${gpu_type}; then
        pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    elif grep -E "Intel Corporation UHD" <<<${gpu_type}; then
        pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    fi
}

extra_software_install() {
    # Installing more sofware
    echo "Installing more software..."
    pacman -S --noconfirm --needed cups ntp bluez bluez-utils avahi gcc python python-pip

    # Enabling important daemons
    echo "Enabling important daemons..."
    systemctl enable cups.service
    echo "Cups enabled"
    systemctl enable ntpd.service
    echo "NTP enabled"
    systemctl enable NetworkManager.service
    echo "NetworkManager enabled"
    systemctl enable bluetooth
    echo "Bluetooth enabled"
    sudo systemctl enable reflector.timer
    echo "Reflector enabled"
    sudo systemctl enable ufw
    echo "UFW enabled"
    sudo systemctl enable avahi-daemon.service
    echo "Avahi enabled"
}

# More software to install down the line
# libreoffice firefox gufw system-config-printer

arch-chroot /mnt /bin/bash <<EOF
arch_configuration
microcode_install
graphics_drivers_install
extra_software_install
EOF

# Unmounting partitions
umount -a
echo "Installation complete. Please reboot your computer."
