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

                                                  Created By: Monstroe

'

CURR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CFG_FILE=$CURR_DIR/settings.cfg
if [ ! -f $CFG_FILE ]; then
    touch -f $CFG_FILE
    echo "PATH=$CURR_DIR"
fi

bash $CURR_DIR/scripts/0-input.sh
source $CFG_FILE
bash $CURR_DIR/scripts/1-disk.sh
bash $CURR_DIR/scripts/2-install.sh
arch-chroot /mnt git clone https://github.com/Monstroe/MonArch.git
arch-chroot /mnt bash /MonArch/scripts/3-chroot.sh $DISK_DEVICE $HOST_NAME $USER_NAME $USER_PASSWD $ROOT_PASSWD $REGION $CITY
arch-chroot /mnt rm -rf /MonArch

# Unmounting partitions
umount -a
echo "----------------------------------------------------"
echo " Installation complete. Please reboot your machine."
echo "----------------------------------------------------"
