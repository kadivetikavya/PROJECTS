output "jenkins_public_ip" {
  value       = aws_instance.jenkins.public_ip
  description = "Public IP of Jenkins Server"
}

output "app_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of App Server"
}
