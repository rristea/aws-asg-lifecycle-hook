#!/bin/bash

TEMPLATE="${1}"

# Get directory of this script.
CURRENT_DIR=${PWD##*/}
# Replace any '/' with '-' and remove the extension.
STACK_NAME=${CURRENT_DIR}-$(echo "${1/\//-}" | cut -f 1 -d '.')

shift 1
PARAMETERS=""
if [ $# -gt 0 ]; then
    PARAMETERS="--parameters ${@}"
fi

aws cloudformation update-stack --stack-name "${STACK_NAME}" --template-body file://"${TEMPLATE}" ${PARAMETERS}  --capabilities CAPABILITY_NAMED_IAM

aws cloudformation wait stack-update-complete --stack-name "${STACK_NAME}"

