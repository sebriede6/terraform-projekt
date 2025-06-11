data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS Account ID für offizielle Ubuntu AMIs

  filter {
    name   = "name"
    # Suche nach Ubuntu 22.04 LTS (Jammy) amd64 server AMI
    # Das genaue Namensmuster kann sich leicht ändern, dies ist ein gängiges.
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro" # Free Tier fähig
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_web_ssh.id]
  # Optional: key_name = "dein-aws-key-pair-name" # Wenn du dich per SSH verbinden willst

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              echo "<h1>Deployed Ubuntu Web Server via Terraform by SebastianRiede</h1><h2>AMI ID: ${data.aws_ami.ubuntu.id}</h2>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "tf-web-server-ubuntu"
  }
}