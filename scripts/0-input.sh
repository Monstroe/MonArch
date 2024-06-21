echo
echo -ne "
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
                    Gathering Input
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

"
sleep 1

set_var() {
    echo "${1}=${2}" >>settings.cfg
}

DISK_DEVICE=""
EFI_SIZE=""
SWAP_SIZE=""

function partition_input() {
    echo 'These are the following disks in your device:'
    echo "-------------------------------------------------"
    lsblk -n -o NAME | grep -E 'sd[a-z]|nvme[0-9]' | awk '{print $1}'
    echo "-------------------------------------------------"
    read -p "Enter disk device to format (e.g. sda OR nvme0n1): " DISK_DEVICE
    DISK_DEVICE="/dev/$DISK_DEVICE"
    echo "Chosen disk device: $DISK_DEVICE"
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
        read -p "Enter size for EFI system partition (specify GiB or MiB, CASE SENSITIVE): " EFI_SIZE
        EFI_SIZE=$(echo $EFI_SIZE | sed 's/ //g')
    else
        echo "BIOS system detected."
        echo "Refer to the arch wiki for more information on BIOS systems."
        echo "Here is an example layout for partitioning (from the arch wiki):"
        echo "-------------------------------------------------"
        echo "1. Swap partition        At least 4 GiB"
        echo "2. Root partition        Remainder of the device"
        echo "-------------------------------------------------"
    fi
    read -p "Enter size for swap partition (specify GiB or MiB, leave blank for no swap partition, CASE SENSITIVE): " SWAP_SIZE
    if [ -n "$SWAP_SIZE" ]; then
        SWAP_SIZE=$(echo $SWAP_SIZE | sed 's/ //g')
    fi

    efi_size_display="${EFI_SIZE//GiB/ GiB}" && efi_size_display="${efi_size_display//MiB/ MiB}"
    swap_size_display="${SWAP_SIZE//GiB/ GiB}" && swap_size_display="${swap_size_display//MiB/ MiB}"
    sleep 1
    echo
    echo "Final partitioning scheme: "
    echo "Disk device: $DISK_DEVICE"
    echo "-------------------------------------------------"
    if [ -d "/sys/firmware/efi" ]; then
        echo "1. EFI system partition  $efi_size_display"
    fi
    if [ -n "$SWAP_SIZE" ]; then
        echo "2. Swap partition        $swap_size_display"
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
set_var "DISK_DEVICE" "$DISK_DEVICE"
set_var "EFI_SIZE" "$EFI_SIZE"
set_var "SWAP_SIZE" "$SWAP_SIZE"
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

HOST_NAME=""
USER_NAME=""
USER_PASSWD=""
ROOT_PASSWD=""

function account_input() {
    echo "Please provide the following account information:"
    echo "-------------------------------------------------"
    read -p "Enter hostname for this device: " HOST_NAME
    read -p "Enter user name for the primary account: " USER_NAME
    prompt_for_password "Enter password for the primary account" "Confirm password for the primary account" USER_PASSWD
    prompt_for_password "Enter password for the root account (MAKE THIS STRONG)" "Confirm password for the root account" ROOT_PASSWD
    echo "-------------------------------------------------"
}

account_input
echo "Account information complete!"
set_var "HOST_NAME" "$HOST_NAME"
set_var "USER_NAME" "$USER_NAME"
set_var "USER_PASSWD" "$USER_PASSWD"
set_var "ROOT_PASSWD" "$ROOT_PASSWD"
sleep 1
echo
echo

echo "Please provide the following timezone information:"
echo "-------------------------------------------------"
REGION=""
CITY=""

function region_input() {
    echo "These are the following regions available for timezone selection:"
    echo "--------------------------------------------------------------------------------------------------"
    ls /usr/share/zoneinfo/
    echo "--------------------------------------------------------------------------------------------------"
    read -p "Enter your region (this will be used to set the timezone, CASE SENSITIVE): " REGION
    echo

    if [ ! -d "/usr/share/zoneinfo/$REGION" ] && [ ! -f "/usr/share/zoneinfo/$REGION" ]; then
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
    ls /usr/share/zoneinfo/$REGION
    echo "--------------------------------------------------------------------------------------------------"
    read -p "Enter your city (this will be used to set the timezone, CASE SENSITIVE): " CITY
    echo

    if [ ! -f "/usr/share/zoneinfo/$REGION/$CITY" ]; then
        echo "Invalid city. Please try again."
        sleep 1
        echo
        echo
        city_input
    fi
}

function timezone_input() {
    region_input
    if [ -d "/usr/share/zoneinfo/$REGION" ]; then
        city_input
    else
        echo "No cities available for this region. Using region as timezone."
        echo
    fi

    echo "Final timezone information:"
    echo "-------------------------------------------------"
    echo "Region: $REGION"
    if [ -f "/usr/share/zoneinfo/$REGION/$CITY" ]; then
        echo "City: $CITY"
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
set_var "REGION" "$REGION"
set_var "CITY" "$CITY"
sleep 1
echo
echo
echo "All input has been gathered. The script will now begin the installation process..."
sleep 3
