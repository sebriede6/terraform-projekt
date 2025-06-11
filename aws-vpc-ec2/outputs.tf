output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet."
  value       = aws_subnet.public.id
}

output "web_server_public_ip" {
  description = "The public IP address of the web server EC2 instance."
  value       = aws_instance.web_server.public_ip
}

output "web_server_instance_id" {
  description = "The ID of the web server EC2 instance."
  value       = aws_instance.web_server.id
}

output "web_server_ami_id_used" {
  description = "The AMI ID that was used for the EC2 instance."
  value       = data.aws_ami.ubuntu.id
}

output "ssh_command" {
  description = "Command to SSH into the web server (replace 'your-key.pem' if you used a key pair)."
  value       = aws_instance.web_server.public_ip != "" ? "ssh -i your-key.pem ubuntu@${aws_instance.web_server.public_ip}" : "EC2 instance has no public IP or key pair not specified for SSH."
}