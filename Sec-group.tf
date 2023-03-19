resource "aws_security_group" "cloudwave-SG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.cloudwave-vpc.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.jumpbox-instance.public_ip}/32"]
  }
  
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${aws_instance.jumpbox-instance.public_ip}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.environment}-SG"
  }
  depends_on = [aws_eip.cloudwave-eip]

}

resource "aws_security_group" "cloudwave" {
  name_prefix = "rdp-"
  description = "RDP access to Windows instances"
  vpc_id      = aws_vpc.cloudwave-vpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.myip
  }
  tags = {
    Name = "${var.environment}-RDPSG"
  }
}


##S3 bucket 
resource "aws_s3_bucket" "cloudwave-s3" {
  bucket = "cloudwavebucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm =  "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = 1
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

##Role for s3 access to assign to the application server.
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy" "ec2_s3_role_policy" {
    name = "ec2_s3_role_policy"
    role = aws_iam_role.ec2_s3_role.id
    policy = jsonencode(
      {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1637255959709",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": aws_s3_bucket.cloudwave-s3.arn
    }
  ]
 })
  
}


resource "aws_security_group" "database" {
  name_prefix = "database"
  vpc_id      = aws_vpc.cloudwave-vpc.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.App-server.private_ip}/32"]
  }


}

resource "aws_security_group_rule" "A27911_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.database.id
  protocol          = "tcp"
  from_port         = 27911
  to_port           = 27911
  cidr_blocks = ["${aws_instance.App-server.private_ip}/32"]
}

resource "aws_security_group_rule" "A1433_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.database.id
  protocol          = "tcp"
  from_port         = 1433
  to_port           = 1433
  cidr_blocks      = []
}

## Application server to s3 (internal communications)
# Create S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id              = aws_vpc.cloudwave-vpc.id
  service_name        = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.cloudwave-SG.id]
  subnet_ids         = [aws_subnet.myprisubnet.id]
}


# S3 Object
resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.cloudwave-s3.id
  key    = "index.html"
  source = "index.html"
  etag   = filemd5("index.html")
}