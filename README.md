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
__1/ Plans__<br>
Azure Container Apps propose deux types de plans :<br><br>
Plan « Dedicated »:<br>
Le plan dédié consiste en une série de profils de charge de travail qui vont du profil de consommation par défaut à des profils qui disposent d'un matériel dédié personnalisé pour des besoins de calcul spécialisés.<br><br>
Plan « Consumption »:<br>
Le plan Consommation propose une architecture « serverless » qui permet à vos applications d'évoluer à la demande. Les applications peuvent évoluer jusqu'à zéro, et vous ne payez que pour les applications en cours d'exécution. Utilisez le plan de consommation lorsque vous n'avez pas d'exigences matérielles spécifiques pour votre application de conteneur.<br><br>
__2/ Environnement__<br>
Un environnement Container Apps est un périmètre sécurisé autour d'une ou plusieurs applications et tâches conteneurisées.<br>
Un réseau virtuel prend en charge chaque environnement. Lorsque que l’on créer un environnement Azure Container Apps créée un Vnet ( qui n’est pas visible dans la console), on peut également venir également avec son propre Vnet/Subnet pour des configurations plus complexes ( bastion, Private End Point , ….)<br>
Lorsque plusieurs applications conteneurisées se trouvent dans le même environnement, elles partagent le même réseau virtuel et écrivent les journaux vers la même destination.<br>
Il faut comprendre qu'un "Container Apps Environment" est l'environnement (AKS) sur lequel on déplpoie les applications conteneurisées (uniquement sous linux)
Quand on déploie un "Container Apps Environment", on paramètre : - La "zone reduncy"(uniquement s'il y a une intégration avec un vNet) - les Workload profiles (plans) - Monitoring pour les Logs (Azure Log Analytics / Azure Monitor / Pas de stockage de Logs). - Networking, s'il on souhaite utiliser l'intégration d'un Virtual Network, s'il on souhaite exposer la "Virtual IP" à l'extérieur ou pas. (Internal/External)<br>
Voici les propriétés d'un "Container Apps Environment":
```
az containerapp env show \
   --name $CONTAINERAPPS_ENVIRONMENT \
   --resource-group $RESOURCE_GROUP_NAME
```

