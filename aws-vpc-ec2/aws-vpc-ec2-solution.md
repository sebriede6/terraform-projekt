Aufgabe: AWS VPC und EC2 Instanz mit Terraform deployen
Einleitung
Diese Aufgabe umfasste die Definition und das Management einer grundlegenden AWS-Cloud-Infrastruktur bestehend aus einem Virtual Private Cloud (VPC), einem öffentlichen Subnetz, einem Internet Gateway, einer Route Table, einer Security Group und einer EC2-Instanz (Ubuntu Webserver) mittels Terraform.

Ziel war es, den gesamten IaC-Workflow von der Initialisierung über Planung und Anwendung bis hin zur Zerstörung der Ressourcen praktisch durchzuführen und das Zusammenspiel abhängiger Ressourcen zu verstehen.

Verwendete Terraform-Konfiguration
Die Terraform-Konfiguration für diese Aufgabe ist in mehrere Dateien im Verzeichnis aws-vpc-ec2/ aufgeteilt:

versions.tf

providers.tf

network.tf

compute.tf

outputs.tf

Kernkomponenten der Konfiguration
providers.tf: Definiert den AWS Provider und setzt die Region sowie Standard-Tags
h
Kopieren
Bearbeiten
provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      TerraformManaged = "true"
      Project          = "aws-vpc-ec2-ubuntu"
      Owner            = "SebastianRiede"
    }
  }
}
network.tf: Definiert die Netzwerkinfrastruktur
aws_vpc.main: CIDR 10.0.0.0/16

aws_internet_gateway.gw: An die VPC angebunden

aws_subnet.public: CIDR 10.0.1.0/24, mit map_public_ip_on_launch = true

aws_route_table.public: Mit einer Default-Route (0.0.0.0/0) zum Internet Gateway

aws_route_table_association.public_subnet_assoc: Verknüpft das Subnetz mit der Route Table

aws_security_group.allow_web_ssh: Erlaubt Ingress für TCP Port 22 (SSH) und Port 80 (HTTP) von 0.0.0.0/0

compute.tf: Definiert die EC2-Instanz
hcl
Kopieren
Bearbeiten
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_web_ssh.id]

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
outputs.tf: Definiert Ausgabewerte wie die öffentliche IP der EC2-Instanz
Reflexion
1. Welche AWS-Ressourcen (Typen) hast du in dieser Aufgabe mit Terraform erstellt?
aws_vpc

aws_internet_gateway

aws_subnet

aws_route_table

aws_route_table_association

aws_security_group

aws_instance

Zusätzlich habe ich data "aws_ami" verwendet, um das passende Ubuntu-Image zu finden.

2. Wie wurden die Abhängigkeiten definiert?
Terraform nutzt implizite Abhängigkeiten über Referenzen wie:

aws_subnet.public.vpc_id = aws_vpc.main.id

aws_internet_gateway.gw.vpc_id = aws_vpc.main.id

aws_route_table.public.gateway_id = aws_internet_gateway.gw.id

aws_instance.web_server.subnet_id = aws_subnet.public.id

aws_instance.web_server.vpc_security_group_ids = [aws_security_group.allow_web_ssh.id]

So stellt Terraform die richtige Erstellungsreihenfolge sicher. depends_on war nicht nötig.

3. Welche Rolle spielt die Sicherheitsgruppe?
Sie agiert als virtuelle Firewall:

Port 22 (SSH): für Admin-Zugriff (wichtig für Konfiguration/Fehlersuche)

Port 80 (HTTP): für den Zugriff auf den Webserver

Für Produktivumgebungen sollte SSH auf einzelne IPs eingeschränkt werden.

4. Vergleich: terraform plan/apply vs. S3-Bucket-Aufgabe
S3-Bucket: 1–2 Ressourcen, Plan kurz und einfach.

VPC & EC2: Komplexer, viele zusammenhängende Ressourcen. Der Plan zeigt viele dynamische Werte („wird nach Apply bekannt sein“), apply dauert länger wegen EC2-Provisionierung.

5. Was passiert mit der terraform.tfstate?
Nach apply: Die Datei enthält den vollständigen Stand aller erstellten Ressourcen inkl. IDs.

Nach destroy: Alle gelöschten Ressourcen werden aus dem State entfernt. Ist alles zerstört, ist der State leer.

Screenshots des Terraform-Workflows
Siehe Ordner: ./assets/
→ Enthält Screenshots von terraform init, terraform plan, terraform apply und terraform destroy.

