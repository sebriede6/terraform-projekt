
# Recherche: Der AWS Provider für Terraform

## Einleitung
Diese Aufgabe diente der Recherche und dem praktischen Verständnis des AWS Providers in Terraform, insbesondere am Beispiel der Erstellung einer `aws_s3_bucket` Ressource in einem AWS Sandbox Account.

## Die Rolle des AWS Providers
Der AWS Provider ist ein Plugin für Terraform, das es ermöglicht, AWS-Infrastrukturressourcen deklarativ zu verwalten. Er fungiert als Übersetzer zwischen der abstrakten Terraform-Konfigurationssprache (HCL) und den spezifischen API-Aufrufen der Amazon Web Services. Durch den Provider kann Terraform den Lebenszyklus von AWS-Ressourcen (Erstellen, Lesen, Aktualisieren, Löschen – CRUD) steuern und den gewünschten Zustand der Infrastruktur herstellen und beibehalten.

## Konfiguration des AWS Providers
Der AWS Provider wird im `provider "aws" {}` Block konfiguriert. Die wichtigsten Konfigurationsaspekte sind die AWS-Region und die Authentifizierung.

**Meine Konfiguration (`providers.tf` oder Teil einer zentralen Konfigurationsdatei):**
```terraform
provider "aws" {
  region = "eu-central-1" # Beispiel: Frankfurt. Ersetze dies durch deine gewählte AWS-Region.

  default_tags { # Standard-Tags für alle von diesem Provider erstellten Ressourcen
    tags = {
      TerraformManaged = "true"
      Project          = "aws-s3-research-exercise"
      Owner            = "Max Mustermann" # Ersetze durch deinen Namen/Kennung
    }
  }
}

# Der Provider für Zufallswerte, genutzt für eindeutige Bucket-Namen
provider "random" {}
```
**Erläuterung der Konfiguration:**
*   `region = "eu-central-1"`: Dieses Argument legt die AWS-Region fest, in der Terraform standardmäßig Ressourcen erstellt. Es ist ein kritisches Argument, da viele AWS-Dienste regional sind.
*   `default_tags`: Dieser Block ist eine sehr nützliche Funktion des AWS Providers. Er erlaubt die Definition von Tags, die automatisch auf alle Ressourcen angewendet werden, die durch Instanzen dieses Providers erstellt werden. Dies fördert Konsistenz bei der Tag-Vergabe, was für Kostenmanagement, Organisation und Automatisierung wichtig ist.
*   **Authentifizierung:** Die AWS-Anmeldeinformationen (Access Key ID und Secret Access Key) wurden **nicht** direkt in der Terraform-Konfiguration hinterlegt. Stattdessen verlässt sich Terraform auf die Standardmethoden zur Bereitstellung von Credentials:
    1.  Umgebungsvariablen (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (optional), `AWS_DEFAULT_REGION`).
    2.  Die Shared Credentials File (`~/.aws/credentials`) und die AWS CLI Configuration File (`~/.aws/config`), die typischerweise durch `aws configure` eingerichtet werden.
    Dies ist eine Sicherheits-Best-Practice, um sensible Daten nicht im Code zu exponieren.

## Die `aws_s3_bucket` Ressource
Die Terraform-Ressource `aws_s3_bucket` repräsentiert einen **Amazon Simple Storage Service (S3) Bucket** in der AWS-Cloud. Ein S3 Bucket ist ein grundlegender Datenspeicher-Container in AWS. Er dient zur Speicherung von Objekten (Dateien jeglicher Art) und bietet hohe Skalierbarkeit, Verfügbarkeit, Datensicherheit und Performance. S3 Buckets sind eine Kernkomponente vieler AWS-Architekturen.

## Gefundene Dokumentation
Die primäre Quelle für die Dokumentation des AWS Providers und seiner Ressourcen ist die **HashiCorp Terraform Registry**:

*   **AWS Provider Hauptseite:** [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
*   **`aws_s3_bucket` Ressourcendokumentation:** [https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

**Unterschied "Argument Reference" vs. "Attribute Reference":**
In der Dokumentation einer Terraform-Ressource (wie `aws_s3_bucket`) haben diese beiden Abschnitte folgende Bedeutung:

*   **Argument Reference:** Definiert die Parameter, die du als **Input** beim Schreiben deiner Terraform-Konfiguration im `resource` Block angeben kannst (oder musst), um die Ressource zu erstellen und zu konfigurieren. Beispiele für `aws_s3_bucket` sind `bucket` (der Name des Buckets, Pflicht), `acl` (Access Control List), `tags`, `versioning` (Block zur Konfiguration der Versionierung). Man unterscheidet hier zwischen optionalen und erforderlichen Argumenten.

*   **Attribute Reference:** Listet die Werte auf, die eine Ressource **exportiert**, nachdem sie von Terraform erstellt wurde. Diese Attribute können als **Output** deiner Terraform-Konfiguration verwendet werden (mittels `output` Blöcken) oder als Input-Werte für andere Terraform-Ressourcen dienen, um Abhängigkeiten und Datenflüsse zu modellieren. Beispiele für `aws_s3_bucket` sind `id` (oft der Bucket-Name), `arn` (Amazon Resource Name), `bucket_domain_name`, `region`.

## Umgesetztes Beispiel (S3 Bucket Erstellung)

**`versions.tf`:**
```terraform
terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40" 
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

**`providers.tf`:** 
```terraform
provider "aws" {
  region = "eu-central-1" # Ersetze dies durch deine gewählte AWS-Region.

  default_tags {
    tags = {
      TerraformManaged = "true"
      Project          = "aws-s3-research-exercise"
      Owner            = "Max Mustermann" 
    }
  }
}

provider "random" {}
```

**`main.tf`:**
```terraform
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "my_research_bucket" {
  # Bucket-Namen müssen global eindeutig sein.
  bucket = "tf-research-sriede-${random_string.bucket_suffix.result}" 

  tags = {
    Name        = "My Terraform Research Bucket"
    Environment = "Sandbox-Research"
  }
}
```

**`outputs.tf`:**
```terraform
output "research_bucket_id" {
  description = "The ID (name) of the created S3 bucket."
  value       = aws_s3_bucket.my_research_bucket.id
}

output "research_bucket_arn" {
  description = "The ARN of the created S3 bucket."
  value       = aws_s3_bucket.my_research_bucket.arn
}

output "research_bucket_regional_domain_name" {
  description = "The regional domain name of the created S3 bucket, e.g., bucket-name.s3.region.amazonaws.com."
  value       = aws_s3_bucket.my_research_bucket.bucket_regional_domain_name
}
```

**Erläuterung des Output Blocks:**
Die `output` Blöcke in `outputs.tf` dienen dazu, nach einem erfolgreichen `terraform apply` spezifische Informationen über die erstellte Infrastruktur anzuzeigen. In diesem Fall:
*   `research_bucket_id`: Zeigt den eindeutigen Namen des erstellten S3 Buckets.
*   `research_bucket_arn`: Gibt den Amazon Resource Name des Buckets aus, eine global eindeutige Kennung innerhalb von AWS.
*   `research_bucket_regional_domain_name`: Stellt die DNS-Adresse bereit, unter der der Bucket in seiner spezifischen AWS-Region direkt adressierbar ist.

[Screenshots](./assets/)
```
