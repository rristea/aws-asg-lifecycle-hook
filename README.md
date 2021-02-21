# AWS AutoScaling with Lifecycle Hooks

This is an example of An AWS Autoscaling Group with the following properties:
* It is created in the Default VPC.
* It starts with zero instances (DesiredCapacity=0).
* Has a Lifecycle Hook for Instance Launch:
    * Heartbeat set to 120s.
    * If lifecycle action is not completed (within the heartbeat timeout), the instance will be removed (DefaultResult=ABANDON).

The Lifecycle Hook will be completed in three ways:
* With the AWS CLI
* With a Lambda (python) using the SDK (boto3).
* With a Lambda that will run a SSM command on the Instance, which will run the AWS CLI.

There are a few helper scripts to assist with the AWS CLI commands:
* `aws-cli-cloudformation.sh` - For creating/deploying/describing/deleting stacks.
* `aws-cli-asg.sh` - For executing autoscaling commands.
* `aws-cli-logs.sh` - For getting CloudWatch logs for the executing Lambda functions.

## Creating the ASG

The ASG is defined in a CloudFormation template (`cloudformation/asg.yml`), which can be deployed with:
```
./aws-cli-cloudformation.sh --create asg
```
Once it's created we can inspect it:
* We can describe the CF stack. The names of the ASG and the Lifecycle Hook are exported as Outputs:
  ```
  $ ./aws-cli-cloudformation.sh --describe asg
    {
        "Stacks": [
            {
                [...]
                "Outputs": [
                    {
                        "Description": "ASG Livecycle Hook Launching Name",
                        "OutputKey": "ASGLifecycleHookLaunchingName",
                        "OutputValue": "aws-asg-lifecycle-hook-cloudformation-asg-LifecycleHookLaunching"
                    },
                    {
                        "Description": "ASG Name",
                        "OutputKey": "ASGName",
                        "OutputValue": "aws-asg-lifecycle-hook-cloudformation-asg-ASG-17VR4Z4553R7D"
                    }
                ],
                [...]
            }
        ]
    }
  ```
* We can use the AWS CLI for inspecting and ASG and the Lifecycle Hooks:
    * Inspect the ASG (we see there are no instances assigned):
    ```
    $ ./aws-cli-asg.sh --describe-auto-scaling-groups
    {
        "AutoScalingGroups": [
            {
                [...]
                "AutoScalingGroupName": "aws-asg-lifecycle-hook-cloudformation-asg-ASG-17VR4Z4553R7D",
                "MinSize": 0,
                "Instances": [],
                "MaxSize": 5,
                [...]
                "DesiredCapacity": 0
            }
        ]
    }
    ```
    * Inspect the ASG's Lifecycle Hooks (only one defined):
    ```
    $ ./aws-cli-asg.sh --describe-lifecycle-hooks
    {
        "LifecycleHooks": [
            {
                "GlobalTimeout": 12000,
                "HeartbeatTimeout": 120,
                "AutoScalingGroupName": "aws-asg-lifecycle-hook-cloudformation-asg-ASG-17VR4Z4553R7D",
                "LifecycleHookName": "aws-asg-lifecycle-hook-cloudformation-asg-LifecycleHookLaunching",
                "DefaultResult": "ABANDON",
                "LifecycleTransition": "autoscaling:EC2_INSTANCE_LAUNCHING"
            }
        ]
    }
    ```

## Test the Lifecycle Hook
* Add one Instance to the ASG by increasing the DesiredCapacity
```
$ ./aws-cli-asg.sh --set-desired-capacity 1
```
* We can see that a scaling activity is registered (might take a few seconds before appearing)
```
$ ./aws-cli-asg.sh --describe-scaling-activities
{
    "Activities": [
        {
            "Description": "Launching a new EC2 instance: i-04fc320ef28f4887a",
            [...]
        }
    ]
}
```
* We can inspect the status of the instance, and after a while it will enter the `Pending:Wait` state, which means the Lifecycle Hook has been triggered
```
$ ./aws-cli-asg.sh --describe-auto-scaling-instances i-04fc320ef28f4887a
{
    "AutoScalingInstances": [
        {
            [...]
            "InstanceId": "i-04fc320ef28f4887a",
            "LifecycleState": "Pending:Wait",
        }
    ]
}
```
* If we don't do anything for 120 seconds (the HeartBeat period) then the instance will get deleted (DefaultResult=ABANDON)
```
$ ./aws-cli-asg.sh --describe-scaling-activities
{
    "Activities": [
        {
            "Description": "Terminating EC2 instance: i-04fc320ef28f4887a",
            "Cause": "At 2021-02-20T11:02:35Z an instance was taken out of service in response to a launch failure.",
            [...]
        }
    ]
}
```
* After the previous one is deleted, a new one will be spawned (DesiredCapacity is still 1). We can wait to get in to the `Pending:Wait` state, and then send HeartBeats wo reset the 120 counter, and keep the Instance in the Wait state (note: you will need to get the instance ID again, since it is a new instance)
```
$ ./aws-cli-asg.sh --record-lifecycle-action-heartbeat i-0f584988049332ab3
```
* We can set the DesiredCapacity back to zero, and the ASG will no longer create an instance once the Hearbeat timeout expires
```
$ ./aws-cli-asg.sh --set-desired-capacity 0
```

## Complete the Lifecycle Hook through the AWS CLI
* Set again the DesiredCapacity to 1. Wait for the instance to get into the Wait state.
* Complete the Lifecycle Hook for this Instance
```
$ ./aws-cli-asg.sh --complete-lifecycle-action i-0f584988049332ab3
```
* The instance is now in service
```
$ ./aws-cli-asg.sh --describe-auto-scaling-instances i-0f584988049332ab3
{
    "AutoScalingInstances": [
        {
            [...]
            "InstanceId": "i-0f584988049332ab3",
            "LifecycleState": "InService",
        }
    ]
}
```
* Set the DesiredCapacity back to zero, and the ASG will delete the instance


## Complete the Lifecycle Hook through AWS Lambda

* The Lambda function is defined in a CloudFormation template (`cloudformation/lambda.yml`), which can be deployed with:
  ```
  ./aws-cli-cloudformation.sh --create lambda
  ```
  The template also contains an EventBridge Rule that searches for events emitted by our ASG Lyfecycle Hook. It then forwards that event to the Lambda. The Lambda then gets the information from the Event, and uses the SDK to complete the Lifecycle event.
* Set the DesiredCapacity to one, so that the ASG will spawn an instance.
* This time the Instance will get set to InService automatically via the Lambda function.
* We can check the CloudWatch logs of the function to see that it was triggered
```
$ ./aws-cli-logs.sh
START RequestId: cc1f8270-10f9-4fba-b0ac-9d69bfef3410 Version: $LATEST
        Received event for instance i-0490837f70c594463
        Lifecycle hook continued correctly: [...]
```

