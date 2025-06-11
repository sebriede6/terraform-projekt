```markdown
# Aufgabe: AWS VPC und EC2 Instanz mit Terraform deployen

## Einleitung
Diese Aufgabe umfasste die Definition und das Management einer grundlegenden AWS-Cloud-Infrastruktur bestehend aus einem Virtual Private Cloud (VPC), einem öffentlichen Subnetz, einem Internet Gateway, einer Route Table, einer Security Group und einer EC2-Instanz (Ubuntu Webserver) mittels Terraform. Ziel war es, den gesamten IaC-Workflow von der Initialisierung über Planung und Anwendung bis hin zur Zerstörung der Ressourcen praktisch durchzuführen und das Zusammenspiel abhängiger Ressourcen zu verstehen.

## Verwendete Terraform-Konfiguration

Die Terraform-Konfiguration für diese Aufgabe ist in mehrere Dateien im Verzeichnis `aws-vpc-ec2/` aufgeteilt (`versions.tf`, `providers.tf`, `network.tf`, `compute.tf`, `outputs.tf`).

**Kernkomponenten der Konfiguration:**

*   **`providers.tf`:** Definiert den AWS Provider und setzt die Region sowie Standard-Tags.
    ```terraform
    provider "aws" {
      region = "eu-central-1" # Konfigurierte AWS-Region

      default_tags {
        tags = {
          TerraformManaged = "true"
          Project          = "aws-vpc-ec2-ubuntu"
          Owner            = "SebastianRiede" # Angepasst
        }
      }
    }
    ```

*   **`network.tf`:** Definiert die Netzwerkinfrastruktur.
    *   `aws_vpc.main`: CIDR "10.0.0.0/16".
    *   `aws_internet_gateway.gw`: An die VPC angebunden.
    *   `aws_subnet.public`: CIDR "10.0.1.0/24", mit `map_public_ip_on_launch = true`.
    *   `aws_route_table.public`: Mit einer Default-Route (`0.0.0.0/0`) zum Internet Gateway.
    *   `aws_route_table_association.public_subnet_assoc`: Verknüpft das Subnetz mit der Route Table.
    *   `aws_security_group.allow_web_ssh`: Erlaubt Ingress für TCP Port 22 (SSH) und Port 80 (HTTP) von `0.0.0.0/0`.

*   **`compute.tf`:** Definiert die EC2-Instanz.
    ```terraform
    data "aws_ami" "ubuntu" {
      most_recent = true
      owners      = ["099720109477"] # Canonical

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
    ```

*   **`outputs.tf`:** Definiert Ausgabewerte wie die öffentliche IP der EC2-Instanz.

## Reflexion

**1. Welche AWS-Ressourcen (Typen) hast du in dieser Aufgabe mit Terraform erstellt?**

In dieser Aufgabe habe ich folgende AWS-Ressourcentypen mit Terraform erstellt:
*   `aws_vpc`: Ein Virtual Private Cloud, isoliertes Netzwerk in AWS.
*   `aws_internet_gateway`: Internet Gateway, um der VPC den Zugriff auf das Internet zu ermöglichen.
*   `aws_subnet`: öffentliches Subnetz innerhalb der VPC.
*   `aws_route_table`: Routing-Tabelle für das öffentliche Subnetz.
*   `aws_route_table_association`: Verknüpfung zwischen der Route Table und dem öffentlichen Subnetz.
*   `aws_security_group`: virtuelle Firewall für die EC2-Instanz.
*   `aws_instance`: virtuelle Maschine (EC2-Instanz) mit Ubuntu und Apache.
Zusätzlich habe ich die Datenquellen `data "aws_availability_zones"` und `data "aws_ami"` genutzt, um dynamisch Informationen für die Konfiguration zu beziehen.

**2. Beschreibe, wie du die Abhängigkeiten zwischen den Ressourcen (z.B. dass das Subnetz erst nach dem VPC erstellt wird) in deiner Terraform-Konfiguration definiert hast. Waren es implizite oder explizite Abhängigkeiten?**

Die Abhängigkeiten habe ich durch **implizite Dependencies** definiert. Terraform erkennt diese automatisch, wenn Attribute einer Ressource in der Definition einer anderen Ressource referenziert werden.
Beispiele:
*   `aws_subnet.public.vpc_id = aws_vpc.main.id`
*   `aws_internet_gateway.gw.vpc_id = aws_vpc.main.id`
*   `aws_route_table.public.gateway_id = aws_internet_gateway.gw.id`
*   `aws_instance.web_server.subnet_id = aws_subnet.public.id`
*   `aws_instance.web_server.vpc_security_group_ids = [aws_security_group.allow_web_ssh.id]`
Diese Referenzen stellen sicher, dass Terraform die Ressourcen in der korrekten Reihenfolge erstellt (z.B. VPC zuerst, dann Subnetz und IGW, dann Routen, dann die EC2-Instanz). Explizite `depends_on`-Anweisungen waren nicht erforderlich.

**3. Was ist die Rolle der Sicherheitsgruppe in diesem Setup? Warum ist es wichtig, die SSH-Regel darin zu konfigurieren?**

Die Sicherheitsgruppe (`aws_security_group.allow_web_ssh`) agiert als zustandsbehaftete virtuelle Firewall auf Instanzebene. Sie kontrolliert den erlaubten ein- und ausgehenden Netzwerkverkehr.
*   **HTTP-Regel (Port 80):** Ermöglicht den Zugriff auf den Apache-Webserver auf der EC2-Instanz aus dem Internet.
*   **SSH-Regel (Port 22):** Ermöglicht den administrativen Zugriff auf die EC2-Instanz über SSH. Das ist essenziell für Wartung, Konfiguration, Log-Analyse und Fehlersuche. Für Produktionsumgebungen sollte die Quell-IP für SSH stark eingeschränkt werden.

**4. Vergleiche den Output von `terraform plan` und `terraform apply` in dieser Aufgabe mit dem, was du bei der S3-Bucket-Aufgabe gesehen hast. Was war der Hauptunterschied?**

Der Hauptunterschied lag in der **Anzahl und Komplexität der Ressourcen**:
*   **S3-Bucket-Aufgabe:** `plan` und `apply` betrafen meist nur 1-2 Ressourcen. Der Prozess war schnell und der Plan übersichtlich.
*   **VPC- und EC2-Aufgabe:** `plan` und `apply` verwalteten eine größere Anzahl miteinander verbundener Ressourcen (ca. 6-7). Der Plan war detaillierter und zeigte deutlicher die Abhängigkeiten (Werte, die erst nach dem `apply` bekannt sind). Der `apply`-Vorgang dauerte aufgrund der Komplexität und der Provisionierungszeit der EC2-Instanz länger.

**5. Was passiert mit der Datei `terraform.tfstate` nach einem erfolgreichen `terraform apply` und nach einem erfolgreichen `terraform destroy`?**

Die `terraform.tfstate`-Datei (oder der State im Remote Backend) ist die "Wahrheitsquelle" für Terraform über den Zustand der gemanagten Infrastruktur.
*   **Nach `terraform apply`:** Die State-Datei wird aktualisiert und enthält detaillierte Informationen über alle erstellten oder geänderten Ressourcen, inklusive ihrer von AWS zugewiesenen IDs und Attribute.
*   **Nach `terraform destroy`:** Die State-Datei wird aktualisiert, indem die Einträge für die zerstörten Ressourcen entfernt werden. Wenn alle Ressourcen der Konfiguration zerstört wurden, ist der State bezüglich dieser Ressourcen leer.

## Screenshots des Terraform Workflows

[Screenshots des Workflows](./assets/)

