# cisco_spl_asg

In this example I deploy a simple webserver behind an application load balancer. It will be using the AWS-generated load balancer hostname URL for accessing the public-facing web application. The infrastructure runs in a custom VPC with an application load balancer and auto-scaling group spanned across two availability zones. This implementation provides high availability and fault tolerance at the cost of additional charges.

I deploy a VPC with custom CIDR, 2 public subnets and 2 private subnets with custom CIDRs — where private subnets are used for compute instances running webservers & public subnets are used by application load balancers, the autoscaling group with AWS AMI and user data to install and start the Nginx server.
