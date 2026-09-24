###############################################################################
# outputs.tf
# -----------------------------------------------------------------------------
# Values printed after `terraform apply`. Show them again any time with
# `terraform output`.
###############################################################################

output "public_ip" {
  description = "Public IP address to connect to with your Remote Desktop client."
  value       = aws_eip.browser_vm.public_ip
}

output "rdp_address" {
  description = "Paste this into your RDP client (Windows App / Microsoft Remote Desktop / Remmina)."
  value       = "${aws_eip.browser_vm.public_ip}:3389"
}

output "desktop_username" {
  description = "Username for the RDP login."
  value       = var.desktop_username
}

output "desktop_password" {
  description = "Password for the RDP login. Show it with: terraform output -raw desktop_password"
  value       = random_password.desktop.result
  sensitive   = true # hidden in normal output
}

output "instance_id" {
  description = "EC2 instance ID (used for SSM Session Manager and start/stop)."
  value       = aws_instance.browser_vm.id
}

output "ssm_shell_command" {
  description = "Command to open a shell on the VM without SSH."
  value       = "aws ssm start-session --target ${aws_instance.browser_vm.id} --region ${var.aws_region}"
}
