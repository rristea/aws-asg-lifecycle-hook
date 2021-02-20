#!/bin/bash

COMMAND=${1}
STACK=${2}
IS_CREATE_UPDATE=false

case ${COMMAND} in
    -c | --create)
        SCRIPT="create-stack.sh"
        IS_CREATE_UPDATE=true
    ;;
    -u | --update)
        SCRIPT="update-stack.sh"
        IS_CREATE_UPDATE=true
    ;;
    -rm | --delete)
        SCRIPT="delete-stack.sh"
    ;;
    -d | --describe)
        SCRIPT="describe-stack.sh"
    ;;
    *)
        echo "Unkown command"
    ;;
esac

if [ ! -z ${SCRIPT} ]; then
    case ${STACK} in
        asg)
            TEMPLATE="cloudformation/asg.yml"
        ;;
        lambda)
            TEMPLATE="cloudformation/lambda.yml"
            if [ ${IS_CREATE_UPDATE} = true ]; then
                ASG_NAME=$(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text)
                ASG_HOOK_NAME=$(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGLifecycleHookLaunchingName'].OutputValue" --output text)
                PARAMS="ParameterKey=ASGName,ParameterValue=${ASG_NAME} ParameterKey=ASGLifecycleHookLaunchingName,ParameterValue=${ASG_HOOK_NAME}"
            fi
        ;;
        *)
            echo "Unkown stack"
        ;;
    esac

    if [ ! -z ${TEMPLATE} ]; then
        ./${SCRIPT} ${TEMPLATE} ${PARAMS}
    fi
fi


