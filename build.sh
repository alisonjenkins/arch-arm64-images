#!/bin/bash
set -euo pipefail

# Partition sizes
BOOT_SIZE_MB=300
ROOT_SIZE_MB=2000

function create_image_file() {
  local IMG_PATH=$1
  local BOOT_SIZE_MB=$2
  local ROOT_SIZE_MB=$3

  IMAGE_SIZE=$(( BOOT_SIZE_MB + ROOT_SIZE_MB + 3))

  echo "Creating empty image at $IMG_PATH with the size of $IMAGE_SIZE"
  test -f "$IMG_PATH" || dd if=/dev/zero of="$IMG_PATH" bs=1M count="$IMAGE_SIZE"
}

function partition_image_file() {
  local IMG_PATH=$1
  local BOOT_SIZE_MB=$2
  local ROOT_SIZE_MB=$3

  parted -s "$IMG_PATH" "mklabel msdos"
  parted --align optimal -s "$IMG_PATH" "mkpart primary fat32 2048s $((BOOT_SIZE_MB + 1))M"
  parted --align optimal -s "$IMG_PATH" "mkpart primary xfs $((BOOT_SIZE_MB + 2))M 100%"
  parted -s "$IMG_PATH" "toggle 1 boot"
}

IMG_PATH="$(pwd)/arch-aarch64.img"

# Create a file to partition to create the image
create_image_file "$IMG_PATH" "$BOOT_SIZE_MB" "$ROOT_SIZE_MB"

# Partition the image
partition_image_file "$IMG_PATH" "$BOOT_SIZE_MB" "$ROOT_SIZE_MB"

# Setup loopback devices
LBDEV=$(losetup --find --show --partscan "$IMG_PATH")

sleep 1

# Format partitions
mkfs.vfat -n "BOOT" -F32 "${LBDEV}p1"
mkfs.ext4 -L "ROOT" "${LBDEV}p2"

# mount partitions
mount "${LBDEV}p2" /mnt/
mkdir /mnt/boot
mount "${LBDEV}p1" /mnt/boot

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

# setup chroot
mount -t proc /proc /mnt/proc/
for mnt in sys dev run; do
  mkdir -p "/mnt/$mnt"
  mount -t rbind "/$mnt" "/mnt/$mnt/"
done
cp /etc/resolv.conf /mnt/etc/resolv.conf

chroot /mnt /chroot-script.sh

rm /mnt/chroot-script.sh

# Unmount loopback devices
umount -R /mnt

# Delete loopback devices
losetup -d "$LBDEV"
