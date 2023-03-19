data "aws_ami" "latest-windows-image" {
    most_recent = true
    owners = [ "801119661308" ]
    filter {
      name = "name"
      values = ["Windows_Server-2022-English-Full-Base-2023.02.15"]
    }
}
data "aws_ami" "latest-database-sever-image" {
    most_recent = true
    owners = [ "amazon" ]
    filter {
      name = "name"
      values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
    }
}

##1 EC2 instance as Jump-Box
resource "aws_instance" "jumpbox-instance" {
ami = data.aws_ami.latest-windows-image.id
instance_type = var.instance_type
key_name = "cloudwave"
associate_public_ip_address = true
subnet_id = aws_subnet.mypubsubnet.id
vpc_security_group_ids = [aws_security_group.cloudwave.id]
 tags = {
    Name = "${var.environment}-jumpbox-instance"
  }

}

##EC2 instance as Application server (Private)
resource "aws_instance" "App-server" {
ami = data.aws_ami.latest-database-sever-image.id
instance_type = var.instance_type
key_name = "cloudwave"
subnet_id = aws_subnet.myprisubnet.id
vpc_security_group_ids = [aws_security_group.cloudwave-SG.id]
iam_instance_profile = aws_iam_instance_profile.cloudwave.name
 tags = {
    Name = "${var.environment}-App-server"
  }

}

## EPS volume with default encryption
resource "aws_ebs_volume" "cloudwave-EBS" {
  availability_zone = "us-east-1b"
  size              = 40
  encrypted = true

  tags = {
    Name = "${var.environment}-EBS"
  }
}
resource "aws_volume_attachment" "EBS_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.cloudwave-EBS.id
  instance_id = aws_instance.App-server.id
  stop_instance_before_detaching = true
}


##EC2 running database server 
resource "aws_instance" "Database-Server" {
ami = data.aws_ami.latest-database-sever-image.id
instance_type = var.instance_type
key_name = "cloudwave"
user_data = file("database_user_data.sh")
subnet_id = aws_subnet.myprisubnet.id
 tags = {
    Name = "${var.environment}-Database-server"
  }

}

resource "aws_iam_instance_profile" "cloudwave" {
    name = "cloudwave_instance_profile"
    role = aws_iam_role.ec2_s3_role.name
  
}