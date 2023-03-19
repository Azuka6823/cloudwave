#!/bin/bash
yum update -y
yum install -y httpd awscli
aws s3 cp s3://${cloudwavebucket}/index.html /var/www/html/
service httpd start
chkconfig httpd on