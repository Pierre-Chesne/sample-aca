RESOURCE_GROUP_NAME="rg-aca-az-cli"
LOCATION="francecentral"
CONTAINERAPPS_ENVIRONMENT="env-aca"
CONTAINERAPP_NAME="aca-quickstart"

echo "Creating the resource group..."
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --tags "env=test"


echo "Creating the environment for Azure Container Apps..."
az containerapp env create \
   --name $CONTAINERAPPS_ENVIRONMENT \
   --resource-group $RESOURCE_GROUP_NAME \
   --logs-destination none \
   --internal-only false \
   --location $LOCATION

   
echo "Creating the Azure Container App..."
az containerapp create \
   --name $CONTAINERAPP_NAME \
   --resource-group $RESOURCE_GROUP_NAME \
   --environment $CONTAINERAPPS_ENVIRONMENT \
   --image mcr.microsoft.com/k8se/quickstart:latest \
   --target-port 80 \
   --ingress external \
   --min-replicas 1 \
   --max-replicas 3 \
   --memory 1.5Gi \
   --cpu 0.75 \
   --query properties.configuration.ingress.fqdn
