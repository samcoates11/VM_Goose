###############################################################################
# versions.tf
# -----------------------------------------------------------------------------
# Pins the Terraform version and the provider plugins this project needs, and
# configures the AWS provider (which account / region / credentials to use).
###############################################################################

terraform {
  # Minimum Terraform CLI version required to run this project.
  required_version = ">= 1.5.0"

  required_providers {
    # Official AWS provider - creates all the AWS resources.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Used to generate a strong random password for the desktop (RDP) user.
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # ---------------------------------------------------------------------------
  # OPTIONAL: Remote state in S3
  # ---------------------------------------------------------------------------
  # By default Terraform stores its state in a local file (terraform.tfstate).
  # That file contains the generated RDP password, so keep it private.
  # If you want to store state in S3 instead, create the bucket first, then
  # uncomment the block below and fill in:
  #   >>> UPDATE: bucket name (often includes your AWS account ID)
  #   >>> UPDATE: region of the bucket
  #
  # backend "s3" {
  #   bucket       = "tfstate-123456789012-eu-west-2"   # <-- UPDATE
  #   key          = "aws-browser-vm/terraform.tfstate"
  #   region       = "eu-west-2"                         # <-- UPDATE
  #   encrypt      = true
  #   use_lockfile = true   # S3-native state locking (Terraform >= 1.10)
  # }
}

# -----------------------------------------------------------------------------
# AWS provider configuration
# -----------------------------------------------------------------------------
provider "aws" {
  # Region to deploy into - set in terraform.tfvars (var.aws_region).
  region = var.aws_region

  # Named profile from ~/.aws/credentials or ~/.aws/config.
  # Set in terraform.tfvars (var.aws_profile). Leave it null to use the
  # default credential chain (env vars, SSO, default profile, etc.).
  profile = var.aws_profile

  # SAFETY GUARD: Terraform refuses to run if your credentials belong to any
  # account other than this one, so you can't deploy into the wrong account
  # by accident. Set in terraform.tfvars (var.aws_account_id).
  allowed_account_ids = [var.aws_account_id]

  # These tags are added automatically to every resource that supports tags.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Owner     = var.owner # <-- set in terraform.tfvars
    }
  }
}
