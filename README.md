
# Übersicht
Dieses Repository enthält die IaC-Definition für das Hosting einer hochverfügbaren, skalierbaren Unternehmenswebsite auf Microsoft Azure mit Terraform.

## Architektur-Komponenten:
1. Azure Blob Storage
2. Azure Functions 
3. Azure Front Door

## Repository-Struktur
```text
├── README.md                # Projektdokumentation
├── frontend/
│   ├── index.html           # Webanwendung mit dynamischem Backend-Aufruf
│   └── 404.html             # Benutzerdefiniertes Fehlerdokument
└── terraform/
    ├── versions.tf          # Provider- und Terraform-Versionierung
    ├── variables.tf         # Parametrisierung (Region, Naming)
    ├── main.tf              # Definition aller Azure-Ressourcen
    └── outputs.tf           # Ausgabe generierter Endpunkt-URLs
