#!/bin/bash

source ./.env
source ./util.sh

if stack_exists $STACK_NAME; then
  change_set_type=UPDATE
else
  change_set_type=CREATE
fi

echo "creatin change set"

aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGE_SET_NAME \
  --change-set-type $change_set_type \
  --template-body file://stack.yml

change_set="$( \
  aws cloudformation describe-change-set \
    --stack-name $STACK_NAME \
    --change-set-name $CHANGE_SET_NAME \
)"

echo "$change_set"

read -n 1 -p "execute change set? (y/n) " answer
echo

if [[ "${answer,,}" == "n" ]]; then exit 0; fi

instance="$( \
  jq -r '.Changes[] | select(.ResourceChange.LogicalResourceId == "Instance")' <<< "$change_set" \
)"

instance_replacement="$(jq -r '.ResourceChange.Replacement' <<< "$instance")"

if [[ "$instance_replacement" == "True" ]]; then
  echo "detachin volume"

  stack="$( \
    aws cloudformation describe-stacks \
      --stack-name $STACK_NAME \
  )"

  volume_id="$( \
    jq -r '.Stacks[] | select(.StackName == "zyzx") | .Outputs[] | select(.OutputKey == "VolumeId") | .OutputValue' <<< "$stack" \
  )"

  instance_id="$(jq -r '.ResourceChange.PhysicalResourceId' <<< "$instance")"

  aws ec2 detach-volume \
    --device /dev/xvdh \
    --instance-id $instance_id \
    --volume-id $volume_id
fi

aws cloudformation execute-change-set \
  --stack-name $STACK_NAME \
  --change-set-name $CHANGE_SET_NAME
