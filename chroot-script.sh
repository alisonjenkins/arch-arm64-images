#!/bin/bash
set -euo pipefail

echo "Initialising pacman"
pacman-key --init
pacman-key --populate archlinuxarm

echo "Updating the installed packages"
pacman -Syu --noconfirm

echo "Installing kernel"
pacman -R --noconfirm linux-aarch64
pacman -U --noconfirm /kernel.pkg.tar.xz /kernel-headers.pkg.tar.xz
echo "Kernel installed"

# Install sudo
pacman -S --noconfirm sudo base-devel git go

# Create aur_builder user for building AUR packages
useradd -mr aur_builder
echo "aur_builder ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/11-aur_builder-pacman

# Install po4a (dependency of fakeroot-tcp)
pacman -S --noconfirm po4a
ln -s /usr/bin/vendor_perl/po4a /usr/bin/po4a

# Install fakeroot-tcp to avoid (https://archlinuxarm.org/forum/viewtopic.php?t=14466&p=63662)
curl https://aur.archlinux.org/cgit/aur.git/snapshot/fakeroot-tcp.tar.gz -o /home/aur_builder/fakeroot-tcp.tar.gz
sudo -u aur_builder bash -c 'cd ~aur_builder && tar xvf fakeroot-tcp.tar.gz && cd fakeroot-tcp && makepkg -si'

# Install fakeroot-tcp
curl https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz -o /home/aur_builder/yay.tar.gz
sudo -u aur_builder bash -c 'cd ~aur_builder && tar xvf yay.tar.gz && cd yay && makepkg -si'
rm -Rf ~aur_builder/yay

# Install yay
useradd -mr aur_builder
echo "aur_builder ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/11-aur_builder-pacman
curl https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz -o /home/aur_builder/yay.tar.gz
sudo -u aur_builder bash -c 'cd ~aur_builder && tar xvf yay.tar.gz && cd yay && makepkg -si'
rm -Rf ~aur_builder/yay

# Install cloud-init
sudo -u aur_builder yay -S --noconfirm cloud-init growpart

# Install kubernetes binaries
sudo -u aur_builder yay -S --noconfirm kubectl-bin kubelet-bin kubeadm-bin containerd


echo "Cleaning up"
rm /kernel.pkg.tar.xz /kernel-headers.pkg.tar.xz
rm /var/cache/pacman/pkg/*.tar.xz