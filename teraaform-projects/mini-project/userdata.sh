#!/bin/bash
yum -y install httpd
systemctl enable httpd
systemctl start httpd
echo "Hello, World!" > /var/www/html/index.html