# AWS OpsWorks Registeration using ASG and Launch Templates.

1. Create an Instance, Install the jq package, perform all the updates and changes you need and then push the `opsworks-register.sh` to the instance in such a way that it gets called upon booting up.
2. Create a new Launch Template, make sure that you provide the following JSON in userData section. 
```
{"STACK_ID": "", "LAYER_ID": ""}
```
3. Also make sure that the Policy "opsworks-ec2-register-policy.json" is created and added to the instance IAM profile.
4. Create an ASG and use the Launch template created in Step 2.
