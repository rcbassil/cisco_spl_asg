# cisco_spl_asg

In this example I deploy a simple webserver behind an application load balancer. It will be using the AWS-generated load balancer hostname URL for accessing the public-facing web application. The infrastructure runs in a custom VPC with an application load balancer and auto-scaling group spanned across two availability zones. This implementation provides high availability and fault tolerance at the cost of additional charges.

I deploy a VPC with custom CIDR, 2 public subnets and 2 private subnets with custom CIDRs — where private subnets are used for compute instances running webservers & public subnets are used by application load balancers, the autoscaling group with AWS AMI and user data to install and start the Nginx server.

 This exercise assumes you have created a Key Pair.
 To create a key pair visit https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:sort=keyName

 To create the resources in AWS we will use terraform. This exercise assumes you have initialized your project directory with:

        terraform init

 To create the resources in AWS:

        terraform apply -var 'key_name=YOUR_KEY_NAME'


Finally, once you hit the AWS-generated load balancer hostname URL, you should be able to view the Web page.
