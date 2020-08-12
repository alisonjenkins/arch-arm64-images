#!/usr/bin/env python3
import boto3
import base64


def start_instance(userdata):
    ec2 = boto3.resource("ec2")
    response = ec2.create_instances(
        ImageId="ami-08f51d843bf37ded6",
        InstanceType="c6g.medium",
        SubnetId="subnet-4c778404",
        SecurityGroupIds=["sg-0caebfe03f435e0dc"],
        UserData=userdata,
        MaxCount=1,
        MinCount=1,
    )

    return response


if __name__ == "__main__":
    with open("instance_userdata.sh") as userdata:
        b64_userdata = base64.b64encode(userdata.read().encode())
    instance = start_instance(b64_userdata)