#!/bin/bash

clear

echo -ne '
 ,ggg, ,ggg,_,ggg,     _,gggggg,_      ,ggg, ,ggggggg,             ,ggg,  ,ggggggggggg,        ,gggg,   ,ggg,        gg 
dP""Y8dP""Y88P""Y8b  ,d8P""d8P"Y8b,   dP""Y8,8P"""""Y8b           dP""8I dP"""88""""""Y8,    ,88"""Y8b,dP""Y8b       88 
Yb, `88`  `88`  `88 ,d8`   Y8   "8b,dPYb, `8dP`     `88          dP   88 Yb,  88      `8b   d8"     `Y8Yb, `88       88 
 `"  88    88    88 d8`    `Ybaaad88P` `"  88`       88         dP    88  `"  88      ,8P  d8`   8b  d8 `"  88       88 
     88    88    88 8P       `""""Y8       88        88        ,8`    88      88aaaad8P"  ,8I    "Y88P`     88aaaaaaa88 
     88    88    88 8b            d8       88        88        d88888888      88""""Yb,   I8`               88"""""""88 
     88    88    88 Y8,          ,8P       88        88  __   ,8"     88      88     "8b  d8                88       88 
     88    88    88 `Y8,        ,8P`       88        88 dP"  ,8P      Y8      88      `8i Y8,               88       88 
     88    88    Y8, `Y8b,,__,,d8P`        88        Y8,Yb,_,dP       `8b,    88       Yb,`Yba,,_____,      88       Y8,
     88    88    `Y8   `"Y8888P"`          88        `Y8 "Y8P"         `Y8    88        Y8  `"Y8888888      88       `Y8

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

                                                Arch Linux Install Script
                                    Creates Arch install with Xorg + Suckless suite

                                                Created By: Monstroe

'

sleep 2

echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Gathering Input
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"

disk_device=""
efi_size=""
swap_size=""

function partition_input() {
    echo 'These are the following disks in your device:'
    echo "-------------------------------------------------"
    lsblk -n -o NAME | grep -E 'sd[a-z]|nvme[0-9]' | awk '{print $1}'
    echo "-------------------------------------------------"
    read -p "Enter disk device to format (e.g. sda OR nvme0n1): " disk_device
    disk_device="/dev/$disk_device"
    echo "Chosen disk device: $disk_device"
    sleep 1

    echo
    if [ -d "/sys/firmware/efi" ]; then
        echo "UEFI system detected. Currently booted in " $(ls /sys/firmware/efi/fw_platform_size) " bit platform size."
        echo "Refer to the arch wiki for more information on UEFI systems and platform sizes."
        echo "Here is an example layout for partitioning (from the arch wiki):"
        echo "-------------------------------------------------"
        echo "1. EFI system partition  1 GiB"
        echo "2. Swap partition        At least 4 GiB"
        echo "3. Root partition        Remainder of the device"
        echo "-------------------------------------------------"
        read -p "Enter size for EFI system partition (specify GiB or MiB): " efi_size
        efi_size=$(echo $efi_size | sed 's/ //g')
    else
        echo "BIOS system detected."
        echo "Refer to the arch wiki for more information on BIOS systems."
        echo "Here is an example layout for partitioning (from the arch wiki):"
        echo "-------------------------------------------------"
        echo "1. Swap partition        At least 4 GiB"
        echo "2. Root partition        Remainder of the device"
        echo "-------------------------------------------------"
    fi
    read -p "Enter size for swap partition (specify GiB or MiB, leave blank for no swap partition): " swap_size
    if [ -n "$swap_size" ]; then
        swap_size=$(echo $swap_size | sed 's/ //g')
    fi

    sleep 1
    echo
    echo "Final partitioning scheme: "
    echo "Disk device: $disk_device"
    echo "-------------------------------------------------"
    if [ -d "/sys/firmware/efi" ]; then
        echo "1. EFI system partition  $efi_size"
    fi
    if [ -n "$swap_size" ]; then
        echo "2. Swap partition        $swap_size"
        echo "3. Root partition        Remainder of the device"
    else
        echo "2. Root partition        Remainder of the device"
    fi
    echo "-------------------------------------------------"
    read -p "Is this information correct? (y/n) " correct

    if [ "$correct" != "y" ]; then
        echo "Restarting the partition input process."
        sleep 1
        echo
        echo
        partition_input
    fi
}

partition_input
echo "Partitioning complete!"
sleep 1
echo
echo

function prompt_for_password() {
    local password
    local confirm_password

    while true; do
        # Prompt user to enter password
        echo -n "$1: "
        read -s password
        echo

        # Prompt user to confirm password
        echo -n "$2: "
        read -s confirm_password
        echo

        # Check if passwords match
        if [[ "$password" != "$confirm_password" ]]; then
            echo "Passwords do not match. Please try again."
        else
            eval "$3=$password"
            break
        fi
    done
}

hostname=""
user_name=""
user_passwd=""
root_passwd=""

function account_input() {
    echo "Please provide the following account information:"
    echo "-------------------------------------------------"
    read -p "Enter hostname for this device: " hostname
    read -p "Enter user name for the primary account: " user_name
    prompt_for_password "Enter password for the primary account" "Confirm password for the primary account" user_passwd
    prompt_for_password "Enter password for the root account (MAKE THIS STRONG)" "Confirm password for the root account" root_passwd
    echo "-------------------------------------------------"
}

account_input
echo "Account information complete!"
sleep 1
echo
echo

echo "Please provide the following timezone information:"
echo "-------------------------------------------------"
region=""
city=""

function region_input() {
    echo "These are the following regions available for timezone selection:"
    echo "--------------------------------------------------------------------------------------------------"
    ls /usr/share/zoneinfo/
    echo "--------------------------------------------------------------------------------------------------"
    read -p "Enter your region (this will be used to set the timezone): " region
    echo

    if [ ! -d "/usr/share/zoneinfo/$region" ] && [ ! -f "/usr/share/zoneinfo/$region" ]; then
        echo "Invalid region. Please try again."
        sleep 1
        echo
        echo
        region_input
    fi
}

function city_input() {
    echo "These are the following cities available in your region:"
    echo "--------------------------------------------------------------------------------------------------"
    ls /usr/share/zoneinfo/$region
    echo "--------------------------------------------------------------------------------------------------"
    read -p "Enter your city (this will be used to set the timezone): " city
    echo

    if [ ! -f "/usr/share/zoneinfo/$region/$city" ]; then
        echo "Invalid city. Please try again."
        sleep 1
        echo
        echo
        city_input
    fi
}

function timezone_input() {
    region_input
    if [ -d "/usr/share/zoneinfo/$region" ]; then
        city_input
    else
        echo "No cities available for this region. Using region as timezone."
        echo
    fi

    echo "Final timezone information:"
    echo "-------------------------------------------------"
    echo "Region: $region"
    if [ -f "/usr/share/zoneinfo/$region/$city" ]; then
        echo "City: $city"
    fi
    echo "-------------------------------------------------"
    read -p "Is this information correct? (y/n) " correct

    if [ "$correct" != "y" ]; then
        echo "Restarting the timezone input process."
        sleep 1
        echo
        echo
        timezone_input
    fi
}

timezone_input
echo "Timezone information complete!"
sleep 1
echo
echo
echo "All input has been gathered. The script will now begin the installation process..."

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

echo "Clearing disk..."
sgdisk --clear ${disk_device}

echo "Partitioning disk..."
counter=1
if [ -d "/sys/firmware/efi" ]; then
    sgdisk --new $counter::+$efi_size --typecode=1:ef00 --change-name=1:"EFI System Partition" $disk_device
    ((counter++))
fi
if [ -n "$swap_size" ]; then
    sgdisk --new $counter::+$swap_size --typecode=2:8200 --change-name=2:"Linux Swap" $disk_device
    ((counter++))
fi
sgdisk --new $counter::-0 --typecode=3:8300 --change-name=3:"Linux File System" $disk_device

echo "Formatting the partitions..."
if [ -d "/sys/firmware/efi" ]; then
    echo "Formatting EFI system partition..."
    mkfs.fat -F 32 $disk_part1
    if [ -n "$swap_size" ]; then
        mkswap $disk_part2
        mkfs.ext4 $disk_part3
    else
        mkfs.ext4 $disk_part2
    fi
else
    if [ -n "$swap_size" ]; then
        mkswap $disk_part1
        mkfs.ext4 $disk_part2
    else
        mkfs.ext4 $disk_part1
    fi
fi

echo "Mounting file systems..."
if [ -d "/sys/firmware/efi" ]; then
    echo "Mounting EFI system partition..."
    mount --mkdir $disk_part1 /mnt/boot
    if [ -n "$swap_size" ]; then
        swapon $disk_part2
        mount $disk_part3 /mnt
    else
        mount $disk_part2 /mnt
    fi
else
    if [ -n "$swap_size" ]; then
        swapon $disk_part1
        mount $disk_part2 /mnt
    else
        mount $disk_part1 /mnt
    fi
fi

echo "Partitioning complete!"
partprobe ${disk_device}

genfstab -U /mnt

# Unmounting partitions
umount -a
echo "Installation complete. Please reboot your computer."
