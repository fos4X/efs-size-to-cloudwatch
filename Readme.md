We are using AWS EFS as a backing storage for some of our services. Unfortunately AWS does not (yet?) provide a mechanism of monitoring the size of the storage using CloudWatch.

We found [this](https://stackoverflow.com/questions/55358277/how-can-i-create-a-custom-metric-watching-efs-metered-size-in-aws-cloudwatch) thread on stackoverflow about using a scheduled Lambda-Function to record the size of all EFS volumes into CloudWatch.

Here is a complete terraform-script and Lambda-Function that rolls out the function to your infrastructure; you need to supply the Lambda as a zip-file called `efs_size.zip`.
