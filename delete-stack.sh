#!/bin/bash

TEMPLATE="${1}"

# Get directory of this script.
CURRENT_DIR=${PWD##*/}
# Replace any '/' with '-' and remove the extension.
STACK_NAME=${CURRENT_DIR}-$(echo "${1/\//-}" | cut -f 1 -d '.')

aws cloudformation delete-stack --stack-name "${STACK_NAME}"

aws cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}"
