#!/usr/bin/env bash

export MEMORY=32GiB
export DEVICE=/dev/nvme0n1
export USERNAME=erahhal
export NEW_HOSTNAME=upaya

read -p "THIS WILL WIPE YOUR SYSTEM - ARE YOU SURE? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

sudo wipefs -a $DEVICE
sudo sfdisk --delete $DEVICE

sudo parted $DEVICE -- mklabel gpt
sudo parted $DEVICE -- mkpart primary 512MiB -${MEMORY}
sudo parted $DEVICE -- mkpart primary linux-swap -${MEMORY} 100%
sudo parted $DEVICE -- mkpart ESP fat32 1MiB 512MiB
sudo parted $DEVICE -- set 3 esp on

sudo mkswap -L swap "${DEVICE}p2"
sudo mkfs.fat -F 32 -n EFI "${DEVICE}p3"

sudo mount -t tmpfs none /mnt

sudo zpool create -f \
  -o ashift=12 \
  -o autotrim=on \
  -R /mnt \
  -O canmount=off \
  -O mountpoint=none \
  -O acltype=posixacl \
  -O compression=zstd \
  -O dnodesize=auto \
  -O normalization=formD \
  -O relatime=on \
  -O xattr=sa \
  -O encryption=aes-256-gcm \
  -O keylocation=prompt \
  -O keyformat=passphrase \
  rpool \
  "${DEVICE}p1"

sudo zfs create -o refreservation=1G -o mountpoint=none rpool/reserved
sudo zfs create -o canmount=off -o mountpoint=/ rpool/nixos
sudo zfs create -o canmount=on rpool/nixos/nix
sudo zfs create -o canmount=on rpool/nixos/etc
sudo zfs create -o canmount=on rpool/nixos/var
sudo zfs create -o canmount=on rpool/nixos/var/lib
sudo zfs create -o canmount=on rpool/nixos/var/log
sudo zfs create -o canmount=on rpool/nixos/var/spool
sudo zfs create -o canmount=off -o mountpoint=/ rpool/userdata
sudo zfs create -o canmount=on rpool/userdata/home
sudo zfs create -o canmount=on -o mountpoint=/root rpool/userdata/home/root
sudo zfs create -o canmount=on rpool/userdata/home/$USERNAME

sudo mkdir /mnt/boot
sudo mount "${DEVICE}p3" /mnt/boot

sudo nixos-generate-config --root /mnt

sudo cp ./configuration.nix /mnt/etc/nixos/

sudo sed -i "s/users.users.jane/users.users.${USERNAME}/g" /mnt/etc/nixos/configuration.nix
sudo sed -i '/.*fsType = "zfs".*/a \ \ \ \ \ \ options = [ "zfsutil" ];' /mnt/etc/nixos/hardware-configuration.nix
sudo sed -i '/.*fsType = "vfat".*/a \ \ \ \ \ \ options = [ "X-mount.mkdir" ];' /mnt/etc/nixos/hardware-configuration.nix

sudo -E hostname $NEW_HOSTNAME
export HOSTID=$(hostname | md5sum | head -c 8)

sudo -E bash -c '
cat << EOF > /mnt/etc/nixos/config-host.nix
{ ... }:
{
  networking.hostName = "${NEW_HOSTNAME}";
  networking.hostId = "${HOSTID}";
}
EOF'

sudo nixos-install --show-trace --root /mnt

read -p "System installed.  Reboot?" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
else
  sudo reboot
fi
