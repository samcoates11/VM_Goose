###############################################################################
# variables.tf
# -----------------------------------------------------------------------------
# Declares every input variable. Do NOT put your real values here - put them
# in terraform.tfvars (copy terraform.tfvars.example to get started).
# Variables with no "default" MUST be set in terraform.tfvars.
###############################################################################

# ----------------------------- Account / region ------------------------------

variable "aws_account_id" {
  description = "12-digit AWS account ID to deploy into. The provider refuses to run against any other account."
  type        = string
  # No default - you MUST set this in terraform.tfvars.

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits, e.g. \"123456789012\"."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into, e.g. eu-west-2 (London) or us-east-1 (N. Virginia)."
  type        = string
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile to use. Set to null to use the default credential chain."
  type        = string
  default     = null
}

# ----------------------------- Naming / tagging ------------------------------

variable "project_name" {
  description = "Prefix used in resource names and tags."
  type        = string
  default     = "browser-vm"
}

variable "owner" {
  description = "Your name or email, added as an Owner tag on every resource."
  type        = string
  default     = "unset"
}

# ----------------------------- Networking ------------------------------------

variable "vpc_cidr" {
  description = "IP range for the new VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP range for the public subnet the VM sits in (must be inside vpc_cidr)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "allowed_rdp_cidrs" {
  description = <<-EOT
    List of IP ranges allowed to connect over RDP (TCP 3389).
    Use your own public IP with /32, e.g. ["203.0.113.25/32"].
    Find your IP with:  curl -s https://checkip.amazonaws.com
    NEVER use 0.0.0.0/0 - that exposes the desktop to the whole internet.
  EOT
  type        = list(string)
  # No default - you MUST set this in terraform.tfvars.

  validation {
    condition     = !contains(var.allowed_rdp_cidrs, "0.0.0.0/0")
    error_message = "Don't open RDP to 0.0.0.0/0. Use your own IP, e.g. [\"203.0.113.25/32\"]."
  }
}

# ----------------------------- Virtual machine -------------------------------

variable "instance_type" {
  description = "EC2 instance size. t3.medium (2 vCPU, 4 GiB) is the practical minimum for a desktop + browser."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size_gb" {
  description = "Size of the VM's root disk in GiB."
  type        = number
  default     = 30
}

variable "desktop_username" {
  description = "Linux username you log in with over RDP."
  type        = string
  default     = "browseruser"
}
