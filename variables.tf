variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  type        = string
  default     = "us-west-2"
}

# ubuntu-server-22.04 64-bit x86
variable "aws_amis" {
  default = {
    "us-east-1" = "ami-09d56f8956ab235b3"
    "us-west-2" = "ami-0ee8244746ec5d6d4"
  }
}

variable "vpc_cidr" {
  type        = string
  default     = "172.16.0.0/16"
  description = "default vpc_cidr_block"
}


variable "pub_sub1_cidr_block"{
   type        = string
   default     = "172.16.1.0/24"
}

variable "pub_sub2_cidr_block"{
   type        = string
   default     = "172.16.2.0/24"
}
variable "prv_sub1_cidr_block"{
   type        = string
   default     = "172.16.3.0/24"
}
variable "prv_sub2_cidr_block"{
   type        = string
   default     = "172.16.4.0/24"
}

variable "az1"{
    type        = string
    default     = "us-west-2a"
}

variable "az2"{
    type        = string
    default     = "us-west-2b"
}