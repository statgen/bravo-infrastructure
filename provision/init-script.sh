#!/usr/bin/env bash

# AWS Linux images
# sudo yum update -y
# sudo yum install httpd -y
# sudo systemctl enable httpd
# sudo systemctl start httpd

# Ubuntu Image
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt upgrade -y
#sudo apt install mini-httpd -y
#sudo syustemctl enable mini-httpd
#sudo syustemctl start mini-httpd

####################################
# Simple HTTP Server for Debugging #
####################################

# Create basic html content
sudo mkdir -p /var/www/html
sudo chown ubuntu:ubuntu /var/www/html
echo "I'm Alive!" > /var/www/html/index.html

# Create systemd service
cat << 'HEREDOC' | sudo tee /etc/systemd/system/busybox-httpd.service
[Unit]
Description=Simple http daemon

[Service]
Type=forking
WorkingDirectory=/var/www/html
ExecStart=/usr/bin/busybox httpd -p 8080 -h /var/www/html
ExecStop=/usr/bin/pkill busybox

[Install]
WantedBy=multi-user.target
HEREDOC

# Start systemd service
sudo systemctl daemon-reload
sudo systemctl start busybox-httpd.service

echo "End of User Data"
