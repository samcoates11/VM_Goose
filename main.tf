###############################################################################
# main.tf
# -----------------------------------------------------------------------------
# The virtual machine itself: an Ubuntu 24.04 EC2 instance that installs, on
# first boot, the XFCE desktop, Firefox, and xrdp (a Remote Desktop server).
###############################################################################

# ----------------------------------------------------------------------------
# Find the latest official Ubuntu 24.04 LTS image in your region.
# 099720109477 is Canonical's (Ubuntu's publisher) AWS account ID.
# It is NOT your account ID - don't change it.
# ----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical - leave as is

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------------------------------------------------------
# Random password for the desktop user.
# Retrieve it after `terraform apply` with:
#   terraform output -raw desktop_password
# It is stored in the Terraform state file, so keep that file private.
# ----------------------------------------------------------------------------
resource "random_password" "desktop" {
  length           = 20
  special          = true
  override_special = "!#%*-_=+" # characters that are safe inside the shell script
}

# ----------------------------------------------------------------------------
# The EC2 instance (the virtual machine).
# ----------------------------------------------------------------------------
resource "aws_instance" "browser_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vm.id]
  iam_instance_profile   = aws_iam_instance_profile.vm.name

  # No SSH key pair. Use SSM Session Manager for shell access (see README).

  # First-boot script: installs the desktop, Firefox and xrdp, and creates
  # the login user. templatefile() fills in the ${...} placeholders in the
  # script with the values below.
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    username = var.desktop_username
    password = random_password.desktop.result
  })

  # Rebuild the VM if the startup script changes (it only runs on first boot).
  user_data_replace_on_change = true

  # Root disk: encrypted gp3 SSD, deleted when the instance is destroyed.
  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Require IMDSv2 (session tokens) for the instance metadata service.
  # This is an AWS security best practice.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-instance"
  }

  lifecycle {
    # Don't rebuild the VM just because Canonical publishes a newer image.
    # Remove this if you want every apply to move to the latest AMI.
    ignore_changes = [ami]
  }
}

# ----------------------------------------------------------------------------
# Elastic IP - a fixed public IP, so the address you RDP to doesn't change
# when you stop and start the VM.
# Note: AWS charges for public IPv4 addresses (about $0.005/hour).
# ----------------------------------------------------------------------------
resource "aws_eip" "browser_vm" {
  domain   = "vpc"
  instance = aws_instance.browser_vm.id

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}
