#!/bin/bash
set -euo pipefail

echo "Initialising pacman"
pacman-key --init
pacman-key --populate archlinuxarm

echo "Updating the installed packages"
pacman -Syu --noconfirm

echo "Installing kernel"
set +e
pacman -R --noconfirm linux-aarch64
set -e
pacman -U --noconfirm /kernel.pkg.tar.xz /kernel-headers.pkg.tar.xz
echo "Kernel installed"

# Install sudo
pacman -S --noconfirm sudo base-devel git go

# Create aur_builder user for building AUR packages
set +e
useradd -mr aur_builder
set -e
echo "aur_builder ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/11-aur_builder-pacman

# Install yay
chown -R aur_builder:aur_builder /home/aur_builder
curl https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz -o /home/aur_builder/yay.tar.gz
sudo -u aur_builder bash -c 'cd ~aur_builder && tar xvf yay.tar.gz && cd yay && yes | makepkg -si --noconfirm'
rm -Rf ~aur_builder/yay

# Install netplan (dependency of cloud-init)
## Have to patch it to remove all traces of pandoc from it's build
## As pandoc is awol in Arch Linux ARM's repos.
mkdir -p /home/aur_builder/netplan
chown -R aur_builder:aur_builder /home/aur_builder/netplan
sudo -u aur_builder bash -c 'cd ~aur_builder && cd /home/aur_builder/netplan/ && yes | makepkg -si --noconfirm'

# Install cloud-init
curl -L https://www.archlinux.org/packages/community/any/cloud-init/download/ -o /home/aur_builder/cloud-init.pkg.tar.xz
sudo pacman --noconfirm -U /home/aur_builder/cloud-init.pkg.tar.xz
sudo -u aur_builder yay -S --noconfirm growpart

# Install kubernetes binaries
sudo -u aur_builder yay -S --noconfirm kubectl-bin kubelet-bin kubeadm-bin containerd

echo "Cleaning up"
rm /kernel.pkg.tar.xz /kernel-headers.pkg.tar.xz
