# terraform-projekt

---

```markdown
# Terraform Ganztagesprojekt: Aufbau einer lokalen Entwicklungsumgebung

 Ziel dieser Aufgabe war es, die Kernkonzepte von Infrastructure as Code (IaC) mit Terraform praktisch anzuwenden. Dafür wurde ein eigener, nicht-trivialer Anwendungsfall identifiziert und umgesetzt: die Erstellung einer lokalen Full-Stack-Entwicklungsumgebung mittels Docker.

## Inhaltsverzeichnis

- [Der Anwendungsfall: Problem und Lösung](#der-anwendungsfall-problem-und-lösung)
- [Warum Terraform für diese Aufgabe?](#warum-terraform-für-diese-aufgabe)
- [Architektur der Lösung](#architektur-der-lösung)
- [Terraform-Bausteine im Einsatz](#terraform-bausteine-im-einsatz)
  - [Provider](#provider)
  - [Ressourcen](#ressourcen)
  - [Variablen](#variablen)
  - [Locals](#locals)
  - [Outputs](#outputs)
  - [Module](#module)
- [Der Terraform Workflow in Aktion](#der-terraform-workflow-in-aktion)
  - [Initialisierung (`terraform init`)](#initialisierung-terraform-init)
  - [Planung (`terraform plan`)](#planung-terraform-plan)
  - [Anwendung (`terraform apply`)](#anwendung-terraform-apply)
  - [Überprüfung der Infrastruktur](#überprüfung-der-infrastruktur)
  - [Aktualisierung der Infrastruktur](#aktualisierung-der-infrastruktur)
  - [Zerstörung der Infrastruktur (`terraform destroy`)](#zerstörung-der-infrastruktur-terraform-destroy)
- [Reflexion und Erkenntnisse](#reflexion-und-erkenntnisse)
  - [Herausforderungen und Lösungen](#herausforderungen-und-lösungen)
  - [Warum "nicht-trivial"?](#warum-nicht-trivial)
  - [Vergleich zu manuellen Ansätzen](#vergleich-zu-manuellen-ansätzen)
- [Screenshots des Workflows](#screenshots-des-workflows)
- [Setup und Ausführung](#setup-und-ausführung)

## Der Anwendungsfall: Problem und Lösung

**Das Problem:** Entwickler benötigen oft schnell eine isolierte und reproduzierbare Umgebung, um Full-Stack-Anwendungen lokal zu entwickeln, zu testen oder zu demonstrieren. Das manuelle Aufsetzen von mehreren Diensten (Frontend, Backend, Datenbank, Reverse Proxy), deren Netzwerkkonfiguration und Datenpersistenz kann zeitaufwendig und fehleranfällig sein.

**Die Lösung:** Dieses Terraform-Projekt definiert deklarativ eine kleine, aber vollständige Entwicklungsumgebung bestehend aus:
*   Einem **Frontend-Webserver** (simuliert mit Nginx, der statische Dateien ausliefert).
*   Einem **Backend-API-Dienst** (eine einfache Node.js/Express-Anwendung).
*   Einer **PostgreSQL-Datenbank** zur Datenspeicherung.
*   Einem **Nginx Reverse Proxy**, der als zentraler Eingangspunkt dient und Anfragen an das Frontend und Backend weiterleitet.

Alle diese Dienste laufen als Docker-Container in einem dedizierten Docker-Netzwerk, wobei die Datenbankdaten in einem Docker-Volume persistiert werden.

## Warum Terraform für diese Aufgabe?

Obwohl man eine solche lokale Umgebung auch mit Tools wie Docker Compose erstellen könnte, wurde Terraform gewählt, um dessen Kernkonzepte im Kontext von IaC zu erlernen und anzuwenden:

*   **Deklarative Konfiguration:** Man beschreibt den *gewünschten Zustand* der Infrastruktur, nicht die einzelnen Schritte dorthin.
*   **Reproduzierbarkeit & Konsistenz:** Die Umgebung kann zuverlässig und identisch immer wieder erstellt werden.
*   **Automatisierung:** Das Erstellen, Ändern und Zerstören der Infrastruktur erfolgt über einfache Befehle.
*   **Versionierung:** Die gesamte Infrastrukturdefinition liegt als Code vor und kann versioniert werden (z.B. mit Git).
*   **Zustandsmanagement:** Terraform behält den Überblick über die erstellten Ressourcen.
*   **Modularität:** Komplexe Setups können in wiederverwendbare Module aufgeteilt werden.
*   **Lernziel:** Die Prinzipien sind direkt auf die Verwaltung komplexer Cloud-Infrastrukturen übertragbar.

## Architektur der Lösung

Die Umgebung besteht aus folgenden Hauptkomponenten, die als Docker-Container in einem gemeinsamen Netzwerk (`app_network`) laufen:

```
[Endbenutzer] ---> [Host Port z.B. 8080] ---> [Nginx Reverse Proxy Container]
                                                    |
                                                    +-- (Port 80) --> [Frontend (statische Dateien im Nginx)]
                                                    |
                                                    +-- (/api/*) ----> [Backend API Container (Node.js)]
                                                                            |
                                                                            +--> [PostgreSQL DB Container]
                                                                                      |
                                                                                      +--> [Docker Volume (Persistenz)]
```

## Terraform-Bausteine im Einsatz

Um diese Infrastruktur zu definieren, habe ich alle wesentlichen Terraform-Konzepte genutzt:

### Provider
*   **`kreuzwerker/docker`**: Wird verwendet, um Docker-Ressourcen wie Container, Netzwerke, Images und Volumes auf dem lokalen System zu verwalten.
*   **`hashicorp/random`**: Dient hier zur optionalen Generierung eines sicheren Passworts für die Datenbank, falls keines explizit angegeben wird.

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

## Der Terraform Workflow in Aktion

Der komplette Standard-Workflow wurde durchlaufen:

### Initialisierung (`terraform init`)
Hiermit werden die benötigten Provider heruntergeladen und das Backend initialisiert.


### Planung (`terraform plan`)
Zeigt eine Vorschau der Änderungen, die Terraform an der Infrastruktur vornehmen wird. Man kann genau sehen, welche Ressourcen erstellt, geändert oder gelöscht werden.


### Anwendung (`terraform apply`)
Erstellt oder aktualisiert die Infrastruktur gemäß der Konfiguration. Nach Bestätigung mit `yes` werden die Ressourcen angelegt. Die Outputs werden am Ende angezeigt.
 

### Überprüfung der Infrastruktur
Nach dem `apply` kann man manuell prüfen, ob alles wie erwartet läuft:
*   Die `application_url` im Browser öffnen und die Webanwendung testen.
*   Mit `docker ps` die laufenden Container auflisten.

### Aktualisierung der Infrastruktur
Eine kleine Änderung in der Konfiguration (z.B. Anpassung eines Variablenwertes wie `external_nginx_port` oder Aktivierung des `deploy_monitoring_dummy`) demonstriert, wie Terraform gezielt nur die notwendigen Modifikationen vornimmt.
*   Plan für das Update:
    
*   Apply für das Update:
    

### Zerstörung der Infrastruktur (`terraform destroy`)
Entfernt alle von Terraform in diesem Projekt erstellten Ressourcen sauber wieder vom System.


## Reflexion und Erkenntnisse

### Herausforderungen und Lösungen
*   **Korrekte Label-Syntax für Docker-Ressourcen:** Die Syntax für Labels unterschied sich zwischen `docker_container`/`docker_image` (Map-Zuweisung) und `docker_network`/`docker_volume` (wiederholbarer `labels`-Block mit `label`- und `value`-Argumenten). Die dynamische Erzeugung mit `dynamic "labels"` war hier der Schlüssel.
*   **Dynamische Nginx-Konfiguration:** Die Nginx-Konfig musste den internen Hostnamen des Backends kennen. Dies wurde mit `templatefile` und einem `local-exec` Provisioner gelöst, der die Konfig temporär schreibt und per Volume mountet.
*   **Abhängigkeiten zwischen Ressourcen:** `depends_on` wurde genutzt, um sicherzustellen, dass z.B. das Backend erst startet, wenn die Datenbank bereit ist (oder zumindest der Container gestartet wurde).

### Warum "nicht-trivial"?
Diese Aufgabe geht über eine einfache Ressourcendefinition hinaus, weil:
*   **Mehrere voneinander abhängige Dienste** (Frontend, Backend, DB, Proxy) konfiguriert und vernetzt werden müssen.
*   Ein **benutzerdefiniertes Docker-Image** für das Backend gebaut wird.
*   **Dynamische Konfigurationen** (Nginx) zum Einsatz kommen.
*   **Datenpersistenz** für die Datenbank berücksichtigt wird.
*   Eine klare **Strukturierung durch ein eigenes Modul** erfolgt.
*   Die sinnvolle **Kombination aller gelernten Terraform-Bausteine** (Variablen, Locals, Outputs, Ressourcen, Modul) erforderlich ist, um ein funktionierendes Gesamtsystem zu schaffen.

### Vergleich zu manuellen Ansätzen
Die manuelle Erstellung dieser Umgebung wäre deutlich aufwendiger, fehleranfälliger und schwerer reproduzierbar gewesen. Auch im Vergleich zu reinen Shell-Skripten mit Docker-Befehlen bietet Terraform durch sein Zustandsmanagement und die Planungsphase deutliche Vorteile in Bezug auf Nachvollziehbarkeit und Sicherheit bei Änderungen.


## Screenshots des Workflows

[Hier klicken, um die Screenshots anzusehen](./assets/)

## Setup und Ausführung

1.  Stelle sicher, dass Terraform (Version >= 1.0) und Docker Desktop installiert sind und Docker läuft.
2.  Klone dieses Repository.
3.  Navigiere im Terminal in das Projektverzeichnis (wo sich die `.tf`-Dateien befinden).
4.  Führe `terraform init` aus.
5.  Führe `terraform plan` aus, um die geplanten Änderungen zu sehen.
6.  Führe `terraform apply` aus und bestätige mit `yes`.
7.  Öffne die in den Outputs angezeigte `application_url` im Browser.
8.  Um die Umgebung wieder abzubauen, führe `terraform destroy` aus.

---
````

