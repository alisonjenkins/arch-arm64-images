# This docker image creates an Arch Linux SD card image with cloud-init
FROM agners/archlinuxarm:20200805@sha256:6da86c1825fb77fd6fc95f3ab97078bb2d841fbb952dd81e3897960f66a31ba5

# Install required packages
RUN pacman -Sy --noconfirm parted dosfstools xfsprogs util-linux tar arch-install-scripts

# Create directory we will be working in
RUN mkdir /work
WORKDIR /work

# Build the image
ADD build.sh /usr/bin/build.sh
RUN chmod +x /usr/bin/build.sh

ENTRYPOINT [ "/usr/bin/build.sh" ]