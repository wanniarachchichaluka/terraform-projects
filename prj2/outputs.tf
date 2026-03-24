output "jenkins_public_ip" {
  description = "Public IP of Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i your-key.pem ubuntu@${aws_instance.jenkins.public_ip}"
}