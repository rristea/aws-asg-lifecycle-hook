#!/bin/bash

TEMPLATE="${1}"

# Get directory of this script.
CURRENT_DIR=${PWD##*/}
# Replace any '/' with '-' and remove the extension.
STACK_NAME=${CURRENT_DIR}-$(echo "${1/\//-}" | cut -f 1 -d '.')

aws cloudformation describe-stacks --stack-name "${STACK_NAME}"
