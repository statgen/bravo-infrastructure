#!/bin/bash

# AWS Linux images
# sudo yum update -y
# sudo yum install httpd -y
# sudo systemctl enable httpd
# sudo systemctl start httpd

# Ubuntu Image
# sudo apt update -y
# sudo apt install mini-httpd -y
# sudo syustemctl enable mini-httpd
# sudo syustemctl start mini-httpd

echo "${file_content}!" > /var/www/html/index.html
