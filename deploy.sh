#!/bin/bash

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

aws cloudformation create-change-set \
  --stack-name $stack_name \
  --change-set-name $change_set_name \
  --change-set-type $change_set_type \
  --template-body file://stack.yml

aws cloudformation describe-change-set \
  --stack-name $stack_name \
  --change-set-name $change_set_name \
| \
jq '.Changes'

# example change sets
# https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets-samples.html
# TODO
    # + inspect changes & check whether the ec2 needs to be replaced
    # + if yes detach the volume beforehand
    # + `aws cloudformation execute-change-set ...`
    