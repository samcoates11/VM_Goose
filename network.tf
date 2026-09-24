###############################################################################
# network.tf
# -----------------------------------------------------------------------------
# Builds a small, dedicated network for the VM:
#   VPC -> public subnet -> internet gateway -> route table -> security group
# A dedicated VPC keeps this separate from anything else in your account and
# doesn't rely on the account still having its "default VPC".
###############################################################################

# Looks up the Availability Zones in the chosen region so we can place the
# subnet in the first one without hard-coding a name like "eu-west-2a".
data "aws_availability_zones" "available" {
  state = "available"
}

# ----------------------------------------------------------------------------
# VPC - your private network in AWS.
# ----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # needed for SSM and package downloads
  enable_dns_hostnames = true # gives the instance a public DNS name

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ----------------------------------------------------------------------------
# Internet gateway - lets the VPC reach the internet (and lets you reach the VM).
# ----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ----------------------------------------------------------------------------
# Public subnet - the VM gets a public IP here so you can RDP to it and the
# browser can reach the internet.
# ----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# ----------------------------------------------------------------------------
# Route table - sends all non-local traffic (0.0.0.0/0) to the internet gateway.
# ----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associates the route table with the subnet.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------------------------------
# Security group - the VM's firewall.
#   Inbound:  RDP (3389) ONLY from the IPs in var.allowed_rdp_cidrs.
#             No SSH (22) - use SSM Session Manager for a shell instead.
#   Outbound: all traffic (so the browser and package updates work).
# ----------------------------------------------------------------------------
resource "aws_security_group" "vm" {
  name        = "${var.project_name}-sg"
  description = "Allow RDP from trusted IPs only; allow all outbound"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# One inbound rule per allowed CIDR.
resource "aws_vpc_security_group_ingress_rule" "rdp" {
  for_each = toset(var.allowed_rdp_cidrs)

  security_group_id = aws_security_group.vm.id
  description       = "RDP from trusted IP"
  ip_protocol       = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_ipv4         = each.value
}

# Allow all outbound traffic (web browsing, apt updates, SSM agent).
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.vm.id
  description       = "All outbound traffic"
  ip_protocol       = "-1" # -1 = all protocols
  cidr_ipv4         = "0.0.0.0/0"
}
