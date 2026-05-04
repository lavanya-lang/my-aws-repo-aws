# Creates a production-oriented payments-api Auto Scaling Group using a launch template with custom AMI and user data, attached to an Application Load Balancer target group. Expects existing VPC/subnets and security groups via variables, and outputs ALB DNS name and ASG name.
# Generated Terraform code for AWS in us-east-1

terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.25.0"
    }
  }
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer. Must allow inbound HTTP/HTTPS from desired sources."
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.alb_security_group_id))
    error_message = "alb_security_group_id must look like an AWS security group id (sg-...)."
  }
}

variable "ami_id" {
  description = "Custom AMI ID to use in the launch template (e.g., ami-xxxxxxxxxxxxxxxxx)."
  type        = string

  validation {
    condition     = can(regex("^ami-[a-z0-9]{17}$", var.ami_id))
    error_message = "ami_id must match pattern ami- followed by 17 lowercase hex characters."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.asg_desired_capacity >= 0
    error_message = "asg_desired_capacity must be >= 0."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 4

  validation {
    condition     = var.asg_max_size >= 1
    error_message = "asg_max_size must be >= 1."
  }
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.asg_min_size >= 0
    error_message = "asg_min_size must be >= 0."
  }
}

variable "health_check_grace_period" {
  description = "Time (seconds) after instance launch before health checks start."
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0
    error_message = "health_check_grace_period must be >= 0."
  }
}

variable "instance_security_group_id" {
  description = "Security group ID for the EC2 instances in the ASG. Typically allows inbound only from the ALB SG on app_port."
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.instance_security_group_id))
    error_message = "instance_security_group_id must look like an AWS security group id (sg-...)."
  }
}

variable "instance_type" {
  description = "EC2 instance type for payments-api."
  type        = string
  default     = "t3.micro"
}

variable "lb_subnet_ids" {
  description = "Subnet IDs for the ALB (typically public subnets) in at least 2 AZs for production."
  type        = list(string)

  validation {
    condition     = length(var.lb_subnet_ids) >= 2
    error_message = "lb_subnet_ids must include at least 2 subnets for ALB high availability."
  }
}

variable "name_prefix" {
  description = "Name prefix used for resource naming."
  type        = string
  default     = "payments-api"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name_prefix))
    error_message = "name_prefix may contain only letters, numbers, and hyphens."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the Auto Scaling Group instances (typically private subnets) in at least 2 AZs for production."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must include at least 2 subnets for ASG high availability."
  }
}

variable "tags" {
  description = "Tags to apply to supported resources."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "target_group_port" {
  description = "Port the Target Group forwards traffic to on the instances."
  type        = number
  default     = 8080

  validation {
    condition     = var.target_group_port >= 1 && var.target_group_port <= 65535
    error_message = "target_group_port must be between 1 and 65535."
  }
}

variable "user_data" {
  description = "User data script to bootstrap payments-api. Provide plain text; it will be base64-encoded by Terraform."
  type        = string
  sensitive   = true
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where the ALB, target group, and ASG will be created."
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must look like an AWS VPC id (vpc-...)."
  }
}

provider "aws" {
  region = "us-east-1"
  {{block_to_replace_cred}}
}

locals {
  common_tags = merge(
    {
      Environment = "prod"
      Project     = var.name_prefix
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_lb" "payments_api" {
  internal           = false
  load_balancer_type = "application"
  name               = substr("${var.name_prefix}-alb", 0, 32)
  security_groups    = [var.alb_security_group_id]
  subnets            = var.lb_subnet_ids

  tags = local.common_tags
}

resource "aws_lb_target_group" "payments_api" {
  name     = substr("${var.name_prefix}-tg", 0, 32)
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200-399"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.payments_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.payments_api.arn
    type             = "forward"
  }
}

resource "aws_launch_template" "payments_api" {
  image_id      = var.ami_id
  instance_type = var.instance_type
  name_prefix   = "${var.name_prefix}-lt-"

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = [var.instance_security_group_id]
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.common_tags
  }

  tags = local.common_tags
}

resource "aws_autoscaling_group" "payments_api" {
  desired_capacity          = var.asg_desired_capacity
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = "ELB"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  name                      = "${var.name_prefix}-asg"
  vpc_zone_identifier       = var.subnet_ids

  launch_template {
    id      = aws_launch_template.payments_api.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.payments_api.arn]

  termination_policies = ["OldestLaunchTemplate", "Default"]

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.name_prefix}-instance"
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.payments_api.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.payments_api.name
}

output "target_group_arn" {
  description = "ARN of the ALB target group attached to the ASG."
  value       = aws_lb_target_group.payments_api.arn
}