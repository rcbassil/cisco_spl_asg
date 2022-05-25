#!/bin/bash -v
apt-get update -y
apt-get install -y nginx > /tmp/nginx.log
systemctl start nginx
systemctl enable nginx
echo "<h1>CISCO SPL</h1>" > /var/www/html/index.html
