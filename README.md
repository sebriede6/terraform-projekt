

```markdown
# Terraform Ganztagesprojekt: Aufbau einer lokalen Entwicklungsumgebung mit Remote State

Ziel dieser Aufgabe war es, die Kernkonzepte von Infrastructure as Code (IaC) mit Terraform praktisch anzuwenden. Dafür wurde ein eigener, nicht-trivialer Anwendungsfall identifiziert und umgesetzt: die Erstellung einer lokalen Full-Stack-Entwicklungsumgebung mittels Docker. Zusätzlich wurde das Konzept des Remote State Backends implementiert, um den Terraform State sicher und zentral in Azure Blob Storage zu verwalten.

## Inhaltsverzeichnis

- [Der Anwendungsfall: Problem und Lösung]
- [Warum Terraform für diese Aufgabe?]
- [Architektur der Lösung]
- [Terraform-Bausteine im Einsatz]
  - [Provider]
  - [Ressourcen]
  - [Variablen]
  - [Locals]
  - [Outputs]
  - [Module]
- [Remote State Backend mit Azure Blob Storage]
  - [Notwendigkeit und Vorteile]
  - [Konfiguration des Backends]
  - [Initialisierung und Migration des States]
  - [Überprüfung des Remote States]
- [Der Terraform Workflow in Aktion]
  - [Initialisierung (`terraform init`)]
  - [Planung (`terraform plan`)]
  - [Anwendung (`terraform apply`)]
  - [Überprüfung der Infrastruktur]
  - [Aktualisierung der Infrastruktur]
  - [Zerstörung der Infrastruktur (`terraform destroy`)]
- [Reflexion und Erkenntnisse]
  - [Herausforderungen und Lösungen]
  - [Warum "nicht-trivial"?]
  - [Vergleich zu manuellen Ansätzen]

- [Setup und Ausführung]

## Der Anwendungsfall: Problem und Lösung

**Das Problem:** Entwickler benötigen oft schnell eine isolierte und reproduzierbare Umgebung, um Full-Stack-Anwendungen lokal zu entwickeln, zu testen oder zu demonstrieren. Das manuelle Aufsetzen von mehreren Diensten (Frontend, Backend, Datenbank, Reverse Proxy), deren Netzwerkkonfiguration und Datenpersistenz kann zeitaufwendig und fehleranfällig sein. Zudem muss der Zustand der Infrastruktur sicher verwaltet werden, besonders im Team.

**Die Lösung:** Dieses Terraform-Projekt definiert deklarativ eine kleine, aber vollständige Entwicklungsumgebung bestehend aus:
*   Einem **Frontend-Webserver** (simuliert mit Nginx, der statische Dateien ausliefert).
*   Einem **Backend-API-Dienst** (eine einfache Node.js/Express-Anwendung).
*   Einer **PostgreSQL-Datenbank** zur Datenspeicherung.
*   Einem **Nginx Reverse Proxy**, der als zentraler Eingangspunkt dient und Anfragen an das Frontend und Backend weiterleitet.

Alle diese Dienste laufen als Docker-Container in einem dedizierten Docker-Netzwerk, wobei die Datenbankdaten in einem Docker-Volume persistiert werden. Der Terraform State wird zentral und sicher in Azure Blob Storage gespeichert.

## Warum Terraform für diese Aufgabe?

Obwohl man eine solche lokale Umgebung auch mit Tools wie Docker Compose erstellen könnte, wurde Terraform gewählt, um dessen Kernkonzepte im Kontext von IaC zu erlernen und anzuwenden:

*   **Deklarative Konfiguration:** Man beschreibt den *gewünschten Zustand* der Infrastruktur, nicht die einzelnen Schritte dorthin.
*   **Reproduzierbarkeit & Konsistenz:** Die Umgebung kann zuverlässig und identisch immer wieder erstellt werden.
*   **Automatisierung:** Das Erstellen, Ändern und Zerstören der Infrastruktur erfolgt über einfache Befehle.
*   **Versionierung:** Die gesamte Infrastrukturdefinition liegt als Code vor und kann versioniert werden (z.B. mit Git).
*   **Zustandsmanagement (State):** Terraform behält den Überblick über die erstellten Ressourcen. Die Nutzung eines **Remote State Backends** erhöht die Robustheit und ermöglicht Teamarbeit.
*   **Modularität:** Komplexe Setups können in wiederverwendbare Module aufgeteilt werden.
*   **Lernziel:** Die Prinzipien sind direkt auf die Verwaltung komplexer Cloud-Infrastrukturen übertragbar.

## Architektur der Lösung

Die Umgebung besteht aus folgenden Hauptkomponenten, die als Docker-Container in einem gemeinsamen Netzwerk (`app_network`) laufen:


Der Terraform State wird in Azure Blob Storage gespeichert.

## Terraform-Bausteine im Einsatz

Um diese Infrastruktur zu definieren, habe ich alle wesentlichen Terraform-Konzepte genutzt:

### Provider
*   **`kreuzwerker/docker`**: Wird verwendet, um Docker-Ressourcen wie Container, Netzwerke, Images und Volumes auf dem lokalen System zu verwalten.
*   **`hashicorp/random`**: Dient hier zur optionalen Generierung eines sicheren Passworts für die Datenbank, falls keines explizit angegeben wird.
*   **`hashicorp/azurerm`**: Notwendig für die Konfiguration des Azure Blob Storage Backends für den Remote State.

### Ressourcen
Mindestens drei verschiedene Ressourcentypen wurden definiert:
*   `docker_network`: Erstellt ein isoliertes Netzwerk für die Kommunikation der Dienste.
*   `docker_volume`: Sorgt für die Persistenz der Datenbankdaten.
*   `docker_image`: Baut ein benutzerdefiniertes Docker-Image für den Backend-Dienst.
*   `docker_container`: Definiert und startet die einzelnen Anwendungsdienste (Frontend/Nginx, Backend, Datenbank, optionaler Monitoring-Dummy).
*   `random_string`: Zur Generierung des Datenbankpassworts.

### Variablen
Mindestens drei Variablen mit unterschiedlichen Typen wurden zur Parametrisierung der Konfiguration verwendet:
*   `app_prefix` (string): Ein Präfix für alle Ressourcennamen, um Eindeutigkeit zu gewährleisten und das parallele Betreiben mehrerer solcher Stacks zu ermöglichen.
*   `external_nginx_port` (number): Der Port auf dem Host-System, über den der Nginx Reverse Proxy erreichbar ist.
*   `db_credentials` (map(string), sensitive): Ein Map-Objekt für Datenbankbenutzer, -name und optional -passwort. Das Passwort wird als sensitiv behandelt.
*   `deploy_monitoring_dummy` (bool): Eine boolesche Variable, um optional einen zusätzlichen Dummy-Container zu Demonstrationszwecken zu starten.
*   `backend_replicas` (number): Zur Demonstration der `count`-Meta-Argument-Nutzung, um optional mehrere Instanzen eines Dienstes zu starten (hier ohne echtes Load-Balancing).

### Locals
Mindestens ein `locals`-Block wurde für berechnete oder lokal wiederverwendete Werte genutzt:
*   Generierte Namen für Container, Netzwerk und Volume basierend auf `var.app_prefix` zur Wahrung der Konsistenz (DRY-Prinzip).
*   Die dynamisch generierte Nginx-Konfigurationsdatei mittels der `templatefile`-Funktion, um den Backend-Hostnamen korrekt einzutragen.
*   Das endgültige Datenbankpasswort (entweder aus der Variable oder zufällig generiert).

### Outputs
Mindestens zwei `output`-Blöcke extrahieren relevante Informationen über die erstellte Infrastruktur:
*   `application_url`: Die vollständige URL, unter der die Anwendung über den Nginx-Proxy erreichbar ist.
*   `database_internal_host`: Der interne Docker-Hostname des Datenbankservers, nützlich für Konfigurationen oder Debugging.
*   `generated_db_password`: Das ggf. automatisch generierte Datenbankpasswort (als sensitiver Output).

### Module
Mindestens ein eigenes lokales Modul wurde erstellt und genutzt:
*   **Modul `app_service`**: Kapselt die Logik zur Erstellung eines generischen Anwendungscontainers. Dieses Modul nimmt Parameter wie Image-Name, Netzwerkdetails, Umgebungsvariablen und Port-Mappings entgegen.
    *   **Sinn und Zweck**: Reduziert Code-Duplizierung in der Hauptkonfiguration (`main.tf`), verbessert die Struktur und Lesbarkeit und fördert die Wiederverwendbarkeit für ähnliche Dienste (hier für Backend, Datenbank und den optionalen Monitoring-Dummy genutzt).

## Remote State Backend mit Azure Blob Storage

Um den Terraform State sicher, persistent und für potenzielle Teamarbeit zugänglich zu machen, wurde ein Remote State Backend in Azure Blob Storage konfiguriert.

### Notwendigkeit und Vorteile
*   **Teamarbeit:** Mehrere Teammitglieder können auf denselben State zugreifen und Änderungen koordiniert durchführen (obwohl Locking in dieser Aufgabe nicht konfiguriert wurde, ist es ein wichtiger Aspekt).
*   **Robustheit:** Der State ist vor lokalem Datenverlust (z.B. Festplattendefekt) geschützt.
*   **Sicherheit:** Sensible Informationen im State können durch Cloud-Sicherheitsmechanismen (Verschlüsselung, Zugriffskontrollen) besser geschützt werden als bei einer rein lokalen Datei.
*   **Automatisierung:** Remote State ist essentiell für CI/CD-Pipelines, die Terraform-Operationen ausführen.

### Konfiguration des Backends
Die Konfiguration erfolgte in einer `backend.tf`-Datei (oder direkt im `terraform`-Block in einer anderen `.tf`-Datei):

```terraform
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-24-08-on-riede-zwatz-sebastian" # Meine Azure Resource Group
    storage_account_name = "tfstateriedese15d90037"           # Mein Azure Storage Account Name
    container_name       = "tfstate"                          # Mein Blob Container Name
    key                  = "prod/docker-dev-stack.tfstate"    # Pfad zur State-Datei im Container
  }
}
```
Der Storage Account und der Container wurden zuvor manuell über die Azure CLI erstellt.

### Initialisierung und Migration des States
Nachdem der `backend "azurerm"`-Block zur Konfiguration hinzugefügt wurde, führte der Befehl `terraform init` folgende Aktionen aus:
*   Erkennung der neuen Backend-Konfiguration.
*   Angebot, den bestehenden lokalen `terraform.tfstate` (falls vorhanden) zum neuen Azure Blob Storage Backend zu migrieren.
*   Nach Bestätigung mit `yes` wurde der State erfolgreich in den konfigurierten Azure Storage Container hochgeladen.

### Überprüfung des Remote States
Die erfolgreiche Speicherung des States in der Cloud wurde überprüft, indem:
1.  Im Azure Portal zum Storage Account (`tfstateriedese15d90037`), dann zum Container (`tfstate`) navigiert wurde.
2.  Dort die Existenz des Blobs `prod/docker-dev-stack.tfstate` verifiziert wurde.

Die lokale `terraform.tfstate`-Datei ist nach der Migration entweder nicht mehr vorhanden oder enthält nur noch einen Verweis auf das Remote Backend, nicht aber den eigentlichen State-Inhalt.

## Der Terraform Workflow in Aktion

Der komplette Standard-Workflow wurde durchlaufen, wobei Terraform nun den State aus dem Azure Backend liest und dorthin schreibt:

### Initialisierung (`terraform init`)
Hiermit werden die benötigten Provider heruntergeladen und das (Remote-)Backend initialisiert. Wenn ein Backend neu konfiguriert wird, findet hier die Migration des States statt.


### Planung (`terraform plan`)
Zeigt eine Vorschau der Änderungen, die Terraform an der Infrastruktur vornehmen wird, basierend auf dem Remote State. Man kann genau sehen, welche Ressourcen erstellt, geändert oder gelöscht werden.


### Anwendung (`terraform apply`)
Erstellt oder aktualisiert die Infrastruktur gemäß der Konfiguration. Nach Bestätigung mit `yes` werden die Ressourcen angelegt. Die Outputs werden am Ende angezeigt. Der Remote State wird aktualisiert.


### Überprüfung der Infrastruktur
Nach dem `apply` kann man manuell prüfen, ob alles wie erwartet läuft:
*   Die `application_url` im Browser öffnen und die Webanwendung testen.
*   Mit `docker ps` die laufenden Container auflisten.

*   Mit `terraform state list` die im Remote State verwalteten Ressourcen anzeigen.


### Aktualisierung der Infrastruktur
Eine kleine Änderung in der Konfiguration (z.B. Anpassung eines Variablenwertes wie `external_nginx_port` oder Aktivierung des `deploy_monitoring_dummy`) demonstriert, wie Terraform gezielt nur die notwendigen Modifikationen vornimmt.


### Zerstörung der Infrastruktur (`terraform destroy`)
Entfernt alle von Terraform in diesem Projekt erstellten Ressourcen sauber wieder vom System. Der Remote State wird entsprechend aktualisiert.


## Reflexion und Erkenntnisse

### Herausforderungen und Lösungen
*   **Korrekte Label-Syntax für Docker-Ressourcen:** Die Syntax für Labels unterschied sich zwischen `docker_container`/`docker_image` und `docker_network`/`docker_volume`. Die dynamische Erzeugung mit `dynamic "labels"` (Plural!) für `docker_network` und `docker_volume` (wiederholbarer `labels`-Block mit `label`- und `value`-Argumenten) war hier der Schlüssel, während für `docker_container` und `docker_image` die direkte Map-Zuweisung (`labels = local.common_tags`) korrekt ist. *Hinweis: Nach weiterem Testen stellte sich heraus, dass der Provider für alle diese Ressourcen (network, volume, container) die `dynamic "labels"`-Syntax zu bevorzugen scheint, wenn man alle `common_tags` anwenden möchte.*
*   **Dynamische Nginx-Konfiguration:** Die Nginx-Konfig musste den internen Hostnamen des Backends kennen. Dies wurde mit `templatefile` und einem `local-exec` Provisioner gelöst, der die Konfig temporär schreibt und per Volume mountet.
*   **Abhängigkeiten zwischen Ressourcen:** `depends_on` wurde genutzt, um sicherzustellen, dass z.B. das Backend erst startet, wenn die Datenbank bereit ist (oder zumindest der Container gestartet wurde).
*   **Remote State Konfiguration:** Die korrekten Namen für Ressourcengruppe, Storage Account und Container mussten ermittelt und die Azure-Infrastruktur für das Backend manuell (oder per separatem IaC-Skript) erstellt werden, bevor Terraform es nutzen konnte.

### Warum "nicht-trivial"?
Diese Aufgabe geht über eine einfache Ressourcendefinition hinaus, weil:
*   **Mehrere voneinander abhängige Dienste** (Frontend, Backend, DB, Proxy) konfiguriert und vernetzt werden müssen.
*   Ein **benutzerdefiniertes Docker-Image** für das Backend gebaut wird.
*   **Dynamische Konfigurationen** (Nginx) zum Einsatz kommen.
*   **Datenpersistenz** für die Datenbank berücksichtigt wird.
*   Eine klare **Strukturierung durch ein eigenes Modul** erfolgt.
*   Die sinnvolle **Kombination aller gelernten Terraform-Bausteine** (Variablen, Locals, Outputs, Ressourcen, Modul, Backend) erforderlich ist, um ein funktionierendes Gesamtsystem zu schaffen.
*   Die **Konfiguration eines Remote State Backends** eine zusätzliche Komplexitätsebene für robustes Infrastrukturmanagement hinzufügt.

### Vergleich zu manuellen Ansätzen
Die manuelle Erstellung dieser Umgebung wäre deutlich aufwendiger, fehleranfälliger und schwerer reproduzierbar gewesen. Auch im Vergleich zu reinen Shell-Skripten mit Docker-Befehlen bietet Terraform durch sein Zustandsmanagement (insbesondere Remote State) und die Planungsphase deutliche Vorteile in Bezug auf Nachvollziehbarkeit, Sicherheit bei Änderungen und Teamkollaboration.


## Setup und Ausführung

1.  Stelle sicher, dass Terraform (Version >= 1.0) und Docker Desktop installiert sind und Docker läuft.
2.  Stelle sicher, dass du bei Azure CLI angemeldet bist (`az login`) und das korrekte Abonnement ausgewählt ist.
3.  Klone dieses Repository.
4.  **Erstelle die Azure-Infrastruktur für das Remote Backend manuell (falls noch nicht geschehen):**
    *   Azure Resource Group (z.B. `rg-24-08-on-riede-zwatz-sebastian`)
    *   Azure Storage Account (z.B. `tfstateriedese15d90037`)
    *   Azure Blob Container im Storage Account (z.B. `tfstate`)
5.  Navigiere im Terminal in das Projektverzeichnis (wo sich die `.tf`-Dateien befinden).
6.  Führe `terraform init` aus. Bei erstmaliger Konfiguration des Backends bestätige die Migration des States mit `yes`.
7.  Führe `terraform plan` aus, um die geplanten Änderungen zu sehen.
8.  Führe `terraform apply` aus und bestätige mit `yes`.
9.  Öffne die in den Outputs angezeigte `application_url` im Browser.
10. Um die Umgebung wieder abzubauen, führe `terraform destroy` aus.

```

