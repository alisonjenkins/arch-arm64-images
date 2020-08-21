#!/bin/bash
set -euo pipefail

# Partition sizes
ROOT_SIZE_MB=4000

IMG_PATH="$(pwd)/arch-aarch64.img"

# Create a file to partition to create the image
test -f "$IMG_PATH" || dd if=/dev/zero of="$IMG_PATH" bs=1M count="$ROOT_SIZE_MB"

# Partition the image
parted -s "$IMG_PATH" "mklabel msdos"
parted --align optimal -s "$IMG_PATH" "mkpart primary fat32 2048s ${ROOT_SIZE_MB}M"
parted -s "$IMG_PATH" "toggle 1 boot"

# Setup loopback devices
LBDEV=$(losetup --find --show --partscan "$IMG_PATH")

sleep 1

# Format partitions
mkfs.ext4 -L "ROOT" "${LBDEV}p1"

# mount partitions
mount "${LBDEV}p1" /mnt/

# Download the Arch aarch64 base
ARCH_BASE_TAR_PATH="$(pwd)/arch-aarch64.tar.gz"
test -f "$ARCH_BASE_TAR_PATH" || curl -L 'https://olegtown.pw/Public/ArchLinuxArm/RPi4/rootfs/ArchLinuxARM-rpi-4-aarch64-2020-07-12.tar.gz' -o "$ARCH_BASE_TAR_PATH"

KERNEL_PATH="/mnt/kernel.pkg.tar.xz"
test -f "$KERNEL_PATH" || curl -L 'https://olegtown.pw/Public/ArchLinuxArm/RPi4/kernel/linux-raspberrypi4-5.4.51-1-aarch64.pkg.tar.xz' -o "$KERNEL_PATH"

KERNEL_HEADERS_PATH="/mnt/kernel-headers.pkg.tar.xz"
test -f "$KERNEL_HEADERS_PATH" || curl -L 'https://olegtown.pw/Public/ArchLinuxArm/RPi4/kernel/linux-raspberrypi4-headers-5.4.51-1-aarch64.pkg.tar.xz' -o "$KERNEL_HEADERS_PATH"

tar xvpf "$ARCH_BASE_TAR_PATH" -C /mnt/

cp ./chroot-script.sh /mnt/
chown 755 /mnt/chroot-script.sh

# Copy patches
# cp ./netplan-Makefile /mnt/
# cp ./netplan-PKGBUILD /mnt/

# setup chroot
mount -t proc /proc /mnt/proc/
for mnt in sys dev run; do
  mkdir -p "/mnt/$mnt"
  mount -o bind "/$mnt" "/mnt/$mnt/"
done

rm /mnt/etc/resolv.conf
cp /etc/resolv.conf /mnt/etc/resolv.conf

chroot /mnt /chroot-script.sh

rm /mnt/chroot-script.sh

# Put resolv.conf symlink back
ln -sf /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf

# Unmount loopback devices
umount /mnt

# Zero empty space
yum install zerofree
zerofree "${LBDEV}p1"

# Delete loopback devices
losetup -D "$LBDEV"
