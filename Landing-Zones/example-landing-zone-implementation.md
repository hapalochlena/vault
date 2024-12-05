
Wie wird die Landing Zone, die Cloud-Plattformen bereitstellt, in einem spezifischen Projekt implementiert?

**=> Connecting project-specific infrastructure with landing zone pre-provisioned resources using a "connector" module**

Beispiel Projekt JAKI:

Die LZ wird implementiert im Repo jaki-infra. 
Dieses hat die zwei Directories infra und pipelines.
infra hat folgende Directories für einzelne Cloud-Ressourcen:
- app
- certificates
- cosmosdb
- dns
- gateway

Jedes davon hat folgende Files:
- main.tf
- backend.tf
- variables.tf
(plus teilweise einige andere)

Hier exemplarisch die main.tf files:

