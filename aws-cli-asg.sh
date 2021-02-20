#!/bin/bash

COMMAND=${1}

case ${COMMAND} in
    -dasg | --describe-auto-scaling-groups)
        aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text)
    ;;
    -dlh | --describe-lifecycle-hooks)
        aws autoscaling describe-lifecycle-hooks \
            --auto-scaling-group-name $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text)
    ;;
    -dsa | --describe-scaling-activities)
        aws autoscaling describe-scaling-activities \
            --auto-scaling-group-name $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text)
    ;;
    -dasi | --describe-auto-scaling-instances)
        INSTANCE=${2}
        aws autoscaling describe-auto-scaling-instances \
            --instance-ids ${INSTANCE}
    ;;
    -sdc | --set-desired-capacity)
        CAPACITY=${2}
        aws autoscaling set-desired-capacity \
            --desired-capacity ${CAPACITY} \
            --auto-scaling-group-name $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text)
    ;;
    -rlah | --record-lifecycle-action-heartbeat)
        INSTANCE=${2}
        aws autoscaling record-lifecycle-action-heartbeat \
            --lifecycle-hook-name  $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGLifecycleHookLaunchingName'].OutputValue" --output text) \
            --auto-scaling-group-name  $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text) \
            --instance-id ${INSTANCE}
    ;;
    -cla | --complete-lifecycle-action)
        INSTANCE=${2}
        aws autoscaling complete-lifecycle-action \
            --lifecycle-action-result CONTINUE \
            --lifecycle-hook-name $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGLifecycleHookLaunchingName'].OutputValue" --output text) \
            --auto-scaling-group-name  $(./describe-stack.sh cloudformation/asg.yml --query "Stacks[0].Outputs[?OutputKey=='ASGName'].OutputValue" --output text) \
            --instance-id ${INSTANCE}
    ;;
    *)
        echo "Unkown option"
    ;;
esac
