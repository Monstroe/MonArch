# Check if UEFI is enabled
if [ -d "/sys/firmware/efi" ]; then
    echo "UEFI system detected, partitioning disk..."
    sgdisk --new 1::+$efi_size --typecode=1:ef00 --change-name=1:"EFI System Partition" $disk_device
    sgdisk --new 2::+$swap_size --typecode=2:8200 --change-name=2:"Linux Swap" $disk_device
    sgdisk --new 3::-0 --typecode=3:8300 --change-name=3:"Linux File System" $disk_device

    echo "Formatting the partitions..."
    mkfs.fat -F 32 $disk_part1
    mkswap $disk_part2
    mkfs.ext4 $disk_part3

    echo "Mounting file systems..."
    mount --mkdir $disk_part1 /mnt/boot
    swapon $disk_part2
    mount $disk_part3 /mnt
else
    echo "BIOS system detected, partitioning disk..."
    sgdisk --new 1::+${swap_size} --typecode=2:8200 --change-name=2:"Linux Swap" ${disk_device}
    sgdisk --new 2::-0 --typecode=3:8300 --change-name=3:"Linux File System" ${disk_device}

    echo "Formatting the partitions..."
    mkswap ${disk_part1}
    mkfs.ext4 ${disk_part2}

    echo "Mounting file systems..."
    swapon ${disk_part1}
    mount ${disk_part2} /mnt
fi
