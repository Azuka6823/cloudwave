#!/bin/bash
sudo yum update -y
sudo yum install -y mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld