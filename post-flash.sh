#!/bin/bash
set -euo pipefail

# Add cloud-config-url to the boot args referencing the local url
# for the cloud-config.yml
## Get the line
function set-cloud-config-url() {
  BOOTARGS_LINE=$(awk '/setenv bootargs/ { print $0; }' "$TEMPDIR/boot/boot.txt")
  NEW_BOOTARGS_LINE=$(echo "$BOOTARGS_LINE" | sed "s;\"$; cloud-config-url=file:///media/boot/cloud-config.yml network-config=disabled cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory\";")
  echo "$BOOTARGS_LINE"
  echo "$NEW_BOOTARGS_LINE"
  sudo sed -i "s;${BOOTARGS_LINE};${NEW_BOOTARGS_LINE};" "$TEMPDIR/boot/boot.txt"
  PRECD=$(pwd)
  cd "$TEMPDIR/boot"
  sudo "$TEMPDIR/boot/mkscr"
  cd "$PRECD"
}

BLOCKDEVICE="$1"

TEMPDIR=$(mktemp -d)
sudo mount "$BLOCKDEVICE" "$TEMPDIR"

# create a random mac address
MACADDR=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
sudo sed -i "s/setenv macaddr \".*\"/setenv macaddr \"$MACADDR\"/" "$TEMPDIR/boot/boot.txt"

# Write the cloud-config.yml to boot
sudo cp cloud-config.yml "$TEMPDIR/boot/cloud-config.yml"

set-cloud-config-url

sudo umount "$TEMPDIR"
