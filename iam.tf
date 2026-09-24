###############################################################################
# iam.tf
# -----------------------------------------------------------------------------
# Gives the VM an IAM role so AWS Systems Manager (SSM) can manage it.
# That lets you open a shell on the VM from the AWS Console or CLI
# (Session Manager) without SSH keys or an open port 22.
###############################################################################

# Trust policy: allows the EC2 service to "assume" (use) this role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The role the VM runs as.
resource "aws_iam_role" "vm" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# AWS-managed policy with the minimum permissions the SSM agent needs.
# "aws" in the ARN means this is an AWS-owned policy, so you don't need to
# change the account ID here.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.vm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# An instance profile is the wrapper that attaches an IAM role to an EC2 instance.
resource "aws_iam_instance_profile" "vm" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.vm.name
}
