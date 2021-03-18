#!/bin/bash

source ./.env
source ./util.sh

# change_set_name=$stack_name-change-set-$(date +%s)

if ! stack_exists $STACK_NAME; then exit 0; fi

read -n 1 -p "destroy the $STACK_NAME stack - are you sure? (y/n) " answer
echo

echo "destroyin the $STACK_NAME stack"

if [[ "${answer,,}" != "y" ]]; then exit 0; fi

aws cloudformation delete-stack --stack-name $STACK_NAME
#   --retain-resources