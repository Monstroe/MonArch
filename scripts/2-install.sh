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
