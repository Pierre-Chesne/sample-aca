# Introduction "Azure Container Apps"
<img width='800' src='./Images/welcome.png'/><br>
# Introduction

Azure Container Apps est un service d’Azure qui a été officiellement annoncé lors de l'événement __Microsoft Ignite 2021__ et est devenu GA en mai 2022.<br><br>
__Azure Container Apps__ est un service de plateforme d'applications « Serverless » qui permet de déployer et d'exécuter des applications conteneurisées de manière simplifiée, __sans gérer l'infrastructure sous-jacente__ qui n’es ni plus ni moins que les services Azure Kubernetes Services (pas besoin d’être un expert en orchestrateur de containeurs).<br><br>
Microsoft propose ce service pour les scenarios suivant :
* Applications web et API
* Traitement de tâches en arrière-plan
* Microservices
* Applications basées sur des événements

Azure Container Apps est packagé avec __KEDA__ (Autoscaler) et __ENVOY__ (edge HTTP proxy)<br>
Les applications construites sur Azure Container Apps peuvent évoluer dynamiquement en fonction des caractéristiques suivantes :
* HTTP traffic
* Event-driven processing
* CPU or memory load
* Any KEDA-supported scaler

Ce service interressant évolue assez vite, Microsoft publie ici la Roadmap : https://github.com/orgs/microsoft/projects/540

# Quelques concepts
__Plans__
Azure Container Apps propose deux types de plans :<br>
Plan « Dedicated »<br>
Le plan dédié consiste en une série de profils de charge de travail qui vont du profil de consommation par défaut à des profils qui disposent d'un matériel dédié personnalisé pour des besoins de calcul spécialisés.