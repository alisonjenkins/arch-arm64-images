#!/usr/bin/env python3
import boto3
import base64


def start_instance():
    ec2 = boto3.client("ec2")
    ec2.create_instances(
        ImageId="ami-08f51d843bf37ded6",
        InstanceType="c6g.medium",
        SubnetId="subnet-4c778404",
        SecurityGroupIds="",
    )


if __name__ == "__main__":
    start_instance()