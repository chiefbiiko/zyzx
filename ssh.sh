#!/bin/bash

source ./.env

stack="$( \
  aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
)"

public_ip="$( \
  jq -r '.Stacks[] | select(.StackName == "zyzx") | .Outputs[] | select(.OutputKey == "PublicIp") | .OutputValue' <<< "$stack" \
)"

ssh -i $HOME/.ssh/$SSH_PRIVATE_KEY_NAME $SSH_USERNAME@$public_ip