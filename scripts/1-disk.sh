echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Partitioning Disks
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"
sleep 1

source $CURR_DIR/settings.cfg

disk_part1=${DISK_DEVICE}1
disk_part2=${DISK_DEVICE}2
disk_part3=${DISK_DEVICE}3
if [[ "${DISK_DEVICE}" =~ "nvme" ]]; then
    disk_part1=${DISK_DEVICE}p1
    disk_part2=${DISK_DEVICE}p2
    disk_part3=${DISK_DEVICE}p3
fi

echo "Clearing disk..."
sgdisk --clear ${DISK_DEVICE}

echo "Partitioning disk..."
counter=1
if [ -d "/sys/firmware/efi" ]; then
    sgdisk --new $counter::+$EFI_SIZE --typecode=1:ef00 --change-name=1:"EFI System Partition" $DISK_DEVICE
    ((counter++))
fi
if [ -n "$SWAP_SIZE" ]; then
    sgdisk --new $counter::+$SWAP_SIZE --typecode=2:8200 --change-name=2:"Linux Swap" $DISK_DEVICE
    ((counter++))
fi
sgdisk --new $counter::-0 --typecode=3:8300 --change-name=3:"Linux File System" $DISK_DEVICE

echo "Formatting the partitions..."
if [ -d "/sys/firmware/efi" ]; then
    mkfs.fat -F 32 $disk_part1
    if [ -n "$SWAP_SIZE" ]; then
        mkswap $disk_part2
        mkfs.ext4 $disk_part3
    else
        mkfs.ext4 $disk_part2
    fi
else
    if [ -n "$SWAP_SIZE" ]; then
        mkswap $disk_part1
        mkfs.ext4 $disk_part2
    else
        mkfs.ext4 $disk_part1
    fi
fi

echo "Mounting file systems..."
if [ -d "/sys/firmware/efi" ]; then
    if [ -n "$SWAP_SIZE" ]; then
        swapon $disk_part2
        mount $disk_part3 /mnt
    else
        mount $disk_part2 /mnt
    fi
    mount --mkdir $disk_part1 /mnt/boot
else
    if [ -n "$SWAP_SIZE" ]; then
        swapon $disk_part1
        mount $disk_part2 /mnt
    else
        mount $disk_part1 /mnt
    fi
fi

echo "Partitioning complete!"
