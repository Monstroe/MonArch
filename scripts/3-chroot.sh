echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Arch Configuration
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"
sleep 1

DISK_DEVICE=$1
HOST_NAME=$2
USER_NAME=$3
USER_PASSWD=$4
ROOT_PASSWD=$5
REGION=$6
CITY=$7

arch_configuration() {
    # Setting up Timezone
    echo "Setting up timezone..."
    if [ -d "/usr/share/zoneinfo/$REGION" ]; then
        ln -sf /usr/share/zoneinfo/$REGION/$CITY /etc/localtime
    else
        ln -sf /usr/share/zoneinfo/$REGION /etc/localtime
    fi
    hwclock --systohc

    # Setting up Locale
    echo "Setting up locale..."
    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >/etc/locale.conf
    echo "KEYMAP=us" >/etc/vconsole.conf

    # Setting Hostname
    echo "Setting hostname..."
    echo "${HOST_NAME}" >/etc/hostname

    # Setting Root Password
    echo "Setting root password..."
    echo "root:${ROOT_PASSWD}" | chpasswd

    # Creating Default User
    echo "Creating user..."
    useradd -m -G wheel -s /bin/bash ${USER_NAME}
    echo "${USER_NAME}:${USER_PASSWD}" | chpasswd
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL$/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    # Setting up GRUB Bootloader
    echo "Setting up GRUB Bootloader..."
    if [ -d "/sys/firmware/efi" ]; then
        echo "EFI Bootloader"
        pacman -S efibootmgr --noconfirm --needed
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    else
        echo "BIOS Bootloader"
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
    ufw enable

    # Set up AUR
    echo "Setting up AUR with yay"
    #cd /home/$USER_NAME
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
        echo "Installing NVIDIA drivers"
        pacman -S --noconfirm --needed nvidia
        nvidia-xconfig
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        echo "Installing AMD drivers"
        pacman -S --noconfirm --needed xf86-video-amdgpu
    elif grep -E "Integrated Graphics Controller" <<<${gpu_type}; then
        echo "Installing Intel drivers"
        pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    elif grep -E "Intel Corporation UHD" <<<${gpu_type}; then
        echo "Installing Intel drivers"
        pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    fi
}

extra_software_install() {
    # Installing more sofware
    echo "Installing more software..."
    pacman -S --noconfirm --needed cups ntp bluez bluez-utils avahi

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

arch_configuration
microcode_install
graphics_drivers_install
extra_software_install

# The most important step
echo "Installing neoFetch..."
pacman -S --noconfirm --needed neofetch
