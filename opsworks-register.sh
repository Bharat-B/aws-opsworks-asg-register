#!/bin/bash
# Copyright (C) 2021 Bharat Bala <bharat.bala@opskins.com>
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

#Get Instance Data
USERDATA=$(curl -sL http://169.254.169.254/latest/user-data)
INSTANCE_ID=$(curl -sL http://169.254.169.254/latest/meta-data/instance-id)
REGION=`curl -sL http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`

#Parse the data to retrieve OpsWorks data
INSTANCE_PREFIX=`echo $USERDATA | jq -r .INSTANCE_PREFIX`
TIMESTAMP=$(($(date +"%s%N")/1000000))
OPSWORKS_HOSTNAME="$INSTANCE_PREFIX-$TIMESTAMP"
OPSWORKS_STACK_ID=`echo $USERDATA | jq -r .STACK_ID`
OPSWORKS_LAYER_ID=`echo $USERDATA | jq -r .LAYER_ID`

#Default parameters for OpsWorks registration
REGISTER_OPTS="--region $REGION --stack-id $OPSWORKS_STACK_ID --infrastructure-class ec2 --use-instance-profile --override-hostname $OPSWORKS_HOSTNAME --local"

#Start Process

#Check if the instance is already registered in the stack
if [ ! -f "/var/lib/aws/opsworks/setup.done" ]; then
	#Create a Hostname
        #Assign the same to the EC2 Instance
        aws ec2 create-tags --region $REGION --resources $INSTANCE_ID --tags Key=Name,Value="$OPSWORKS_HOSTNAME"
        #Register the EC2 instance to OpsWorks
        OPSWORKS_INSTANCE_ID=$(aws opsworks register $REGISTER_OPTS | grep -o "Instance ID: .*" | cut -d':' -f2 | tr -d ' ')
        #Wait while the registration happens
        while [ ! -f "/var/lib/aws/opsworks/setup.done" ]
	do
		sleep 5
	done
fi

if [ -f "/etc/motd" ] && [ -z "$OPSWORKS_INSTANCE_ID" ]; then
        OPSWORKS_INSTANCE_ID=`cat /etc/motd | grep -o "OpsWorks Instance ID: .*" | cut -d ':' -f2 | tr -d ' '`
fi

#Let's assign this instance to the Layer
aws opsworks assign-instance --region $REGION --instance-id $OPSWORKS_INSTANCE_ID --layer-id $OPSWORKS_LAYER_ID
