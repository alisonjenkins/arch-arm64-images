#!/bin/bash
yum install -y awslogs git https://s3.region.amazonaws.com/amazon-ssm-region/latest/linux_arm64/amazon-ssm-agent.rpm

systemctl enable --now awslogsd
systemctl enable --now amazon-ssm-agent

git clone https://github.com/alanjjenkins/arch-arm64-images.git /root/arch-arm64-images
cd /root/arch-arm64-images
./build.sh