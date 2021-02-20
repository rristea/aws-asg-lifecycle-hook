#!/bin/bash

LAMBDA_NAME=$(./describe-stack.sh cloudformation/lambda.yml --query "Stacks[0].Outputs[?OutputKey=='LambdaFunctionName'].OutputValue" --output text)

aws logs get-log-events \
        --log-group-name "/aws/lambda/${LAMBDA_NAME}" \
        --log-stream-name $(aws logs describe-log-streams --log-group-name \
                                "/aws/lambda/${LAMBDA_NAME}" \
                                --max-items 1 \
                                --order-by LastEventTime \
                                --descending \
                                --query logStreams[].logStreamName \
                                --output text | head -n 1) \
        --query events[].message \
        --output text
