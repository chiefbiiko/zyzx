#!/bin/sh

stack_exists() { # $stack_name
  &>/dev/null aws cloudformation describe-stacks --stack-name $1
}

stack_name=zyzx
change_set_name=$stack_name-change-set-$(date +%s)

if stack_exists $stack_name; then
  change_set_type=UPDATE
else
  change_set_type=CREATE
fi

echo "creatin change set"

aws cloudformation create-change-set \
  --stack-name $stack_name \
  --change-set-name $change_set_name \
  --change-set-type $change_set_type \
  --template-body file://stack.yml

if [[ $change_set_type -eq UPDATE ]]; then
  change_set="$( \
    aws cloudformation describe-change-set \
      --stack-name $stack_name \
      --change-set-name $change_set_name \
  )"

  stack="$( \
    aws cloudformation describe-stacks \
      --stack-name $stack_name \
  )"

  instance="$( \
    jq -r '.Changes[] | select(.ResourceChange.LogicalResourceId == "Instance")' <<< "$change_set" \
  )"

  volume_id="$( \
    jq -r '.Stacks[] | select(.StackName == "zyzx") | .Outputs[] | select(.OutputKey == "VolumeId") | .OutputValue' <<< "$stack" \
  )"

  instance_replacement="$(jq -r '.ResourceChange.Replacement' <<< "$instance")"
  instance_id="$(jq -r '.ResourceChange.PhysicalResourceId' <<< "$instance")"

  if [ "$instance_replacement" == "True" ]; then
    echo "detachin volume"

    aws ec2 detach-volume \
      --device /dev/sdh \
      --instance-id $instance_id \
      --volume-id $volume_id
  fi
fi

echo "executin change set"

aws cloudformation execute-change-set \
  --stack-name $stack_name \
  --change-set-name $change_set_name
