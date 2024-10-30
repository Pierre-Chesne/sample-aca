#!/bin/bash

# define variables
RESOURCE_GROUP_NAME="rg-aca-az-cli"
LOCATION="francecentral"

VNET_NAME="vnet-aca"
PREFIX_VNET="10.0.0.0/24"
SUBNET_ACA_NAME="subnet-aca"
PREFIX_SUBNET_ACA="10.0.0.0/27"
SUBNET_MAIN_NAME="subnet-main"
PREFIX_SUBNET_MAIN="10.0.0.32/27"
SUBNET_PE_NAME="subnet-pe"
PREFIX_SUBNET_PE="10.0.0.64/27"

POSTGRESQL_SERVER_NAME="pg-aca"
POSTGRESQL_ADMINUSER="adminDB"
POSTGRESQL_ADMINPASSWORD="Password123$"
POSTGRESQL_SKUNAME="Standard_B1ms"
POSTGRESQL_TIER="Burstable"
POSTGRESQL_VERSION="14"
POSTGRESQL_STORAGESIZE="32"
POSTGRESQL_DBNAME="rugby_api"
CONNECTION_NAME="privatelink"
PRIVATE_ENDPOINT_NANE="pg-pe"
NIC_PRIVATE_ENDPOINT_NANE="pg-pe-nic"

DNS_ZONE_NAME="privatelink.postgres.database.azure.com"
PRIVATE_LINK_ACA_NAME="privatelink-aca"
PRIVATE_LINK_ENV_NAME="privatelink-env"

CONTAINERAPPS_ENVIRONMENT="env-aca"
CONTAINERAPP_NAME="sample-aca"

ACR_NAME="azcliregistry"
PATH_DOCKERFILE="/Users/peterochesne/repos/sample-aca/Src/"
IMAGE_NAME="sampleaca"
IMAGE_NAME_VERSION="1.0.0"

IDENTITY="aca-mi"

###################################################
#                                                 #
#           Resource Group                        #
#                                                 #
###################################################
echo "Creating the resource group..."
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION

###################################################
#                                                 #
#               Network                           #
#                                                 #
###################################################
echo "Creating the virtual network..."
az network vnet create \
    --name $VNET_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --address-prefix $PREFIX_VNET

echo "Creating the subnet with delegation "Microsoft.App/environments"..."
az network vnet subnet create \
    --name $SUBNET_ACA_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --vnet-name $VNET_NAME \
    --address-prefix $PREFIX_SUBNET_ACA \
    --delegations "Microsoft.App/environments"

echo "Creating the subnet main..."
az network vnet subnet create \
    --name $SUBNET_MAIN_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --vnet-name $VNET_NAME \
    --address-prefix $PREFIX_SUBNET_MAIN

echo "Creating the subnet pe (pg)..."
az network vnet subnet create \
    --name $SUBNET_PE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --vnet-name $VNET_NAME \
    --address-prefix $PREFIX_SUBNET_PE


###################################################
#                                                 #
#            PostgreSQL                           #
#                                                 #
###################################################
echo "Creating the PostgreSQL server..."
az postgres flexible-server create \
  --name $POSTGRESQL_SERVER_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --admin-user $POSTGRESQL_ADMINUSER \
  --admin-password $POSTGRESQL_ADMINPASSWORD \
  --sku-name $POSTGRESQL_SKUNAME \
  --tier $POSTGRESQL_TIER \
  --version $POSTGRESQL_VERSION \
  --storage-size $POSTGRESQL_STORAGESIZE \
  --public-access 0.0.0.0-255.255.255.255

az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP_NAME \
  --server-name $POSTGRESQL_SERVER_NAME \
  --name require_secure_transport --value off

echo "Creating the PostgreSQL database..."
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP_NAME \
  --server-name $POSTGRESQL_SERVER_NAME \
  --database-name $POSTGRESQL_DBNAME
az postgres flexible-server execute \
  --admin-password $POSTGRESQL_ADMINPASSWORD \
  --admin-user $POSTGRESQL_ADMINUSER \
  --name $POSTGRESQL_SERVER_NAME \
  --database-name $POSTGRESQL_DBNAME \
  --file-path create_tables.sql
RULE=$(az postgres flexible-server firewall-rule list \
       --name $POSTGRESQL_SERVER_NAME \
       --resource-group $RESOURCE_GROUP_NAME \
       --query "[].name" -o tsv)
az postgres flexible-server firewall-rule delete \
   --name $POSTGRESQL_SERVER_NAME \
   --rule-name $RULE \
   --resource-group $RESOURCE_GROUP_NAME \
   --yes

echo "Creating the private endpoint for PostgreSQL server..."
az network private-endpoint create \
  --name $PRIVATE_ENDPOINT_NANE \
  --connection-name $CONNECTION_NAME \
  --nic-name $NIC_PRIVATE_ENDPOINT_NANE \
  --resource-group $RESOURCE_GROUP_NAME \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_PE_NAME \
  --private-connection-resource-id $(
      az postgres flexible-server show \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $POSTGRESQL_SERVER_NAME \
        --query id -o tsv) \
  --group-id postgresqlServer


echo "Creating the private DNS zone..."
az network private-dns zone create \
   --resource-group $RESOURCE_GROUP_NAME \
   --name $DNS_ZONE_NAME


echo "Creating the link between the private DNS zone and the virtual network..."
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP_NAME \
  --zone-name $DNS_ZONE_NAME \
  --name $PRIVATE_LINK_ACA_NAME \
  --virtual-network $VNET_NAME \
  --registration-enabled false


echo "get the private IP address of the PostgreSQL server..."
PRIVATE_IP=$(az network nic show \
               --name $NIC_PRIVATE_ENDPOINT_NANE \
               --resource-group $RESOURCE_GROUP_NAME \
               --query "ipConfigurations[0].privateIPAddress" \
               -o tsv)


echo "Creating the A record in the private DNS zone..."
az network private-dns record-set a create \
   --name $POSTGRESQL_SERVER_NAME \
   --zone-name $DNS_ZONE_NAME \
   --resource-group $RESOURCE_GROUP_NAME


echo "Adding the A record in the private DNS zone with the private IP address of the PostgreSQL server..."
az network private-dns record-set a add-record \
   --record-set-name $POSTGRESQL_SERVER_NAME \
   --zone-name $DNS_ZONE_NAME \
   --resource-group $RESOURCE_GROUP_NAME \
   -a $PRIVATE_IP


###################################################
#                                                 #
#          Azure Container Apps Environment       #
#                                                 #
###################################################
echo "Creating the Log Analytics workspace law-$CONTAINERAPPS_ENVIRONMENT..."
az monitor log-analytics workspace create \
   --resource-group $RESOURCE_GROUP_NAME \
   --workspace-name "law-$CONTAINERAPPS_ENVIRONMENT" \
   --location $LOCATION


echo "Getting the workspace ID..."
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP_NAME \
  --workspace-name "law-$CONTAINERAPPS_ENVIRONMENT" \
  --query customerId -o tsv)


echo "Getting the workspace key..."
WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
   --resource-group $RESOURCE_GROUP_NAME \
   --workspace-name "law-$CONTAINERAPPS_ENVIRONMENT" \
   --query primarySharedKey -o tsv)


echo "Getting the subnet id subnet-aca..."
SUBNET_ACA_ID=$(az network vnet subnet show \
   --resource-group $RESOURCE_GROUP_NAME \
   --vnet-name $VNET_NAME \
   --name $SUBNET_ACA_NAME \
   --query id -o tsv)


echo "Creating the environment for Azure Container Apps..."
az containerapp env create \
   --name $CONTAINERAPPS_ENVIRONMENT \
   --resource-group $RESOURCE_GROUP_NAME \
   --internal-only true \
   --infrastructure-subnet-resource-id $SUBNET_ACA_ID \
   --logs-workspace-id $WORKSPACE_ID \
   --logs-workspace-key $WORKSPACE_KEY \
   --location $LOCATION

echo "get the default domain of the environment for Azure Container Apps..."
ENVIRONMENT_DEFAULT_DOMAIN=$(az containerapp env show \
   --name $CONTAINERAPPS_ENVIRONMENT \
   --resource-group $RESOURCE_GROUP_NAME \
   --query properties.defaultDomain -o tsv)


echo "get ip address of the environment for Azure Container Apps..."
ENVIRONMENT_IP_ADDRESS=$(az containerapp env show \
   --name $CONTAINERAPPS_ENVIRONMENT \
   --resource-group $RESOURCE_GROUP_NAME \
   --query properties.staticIp -o tsv)


echo "create a private DNS zone for the default domain of the environment for Azure Container Apps..."
az network private-dns zone create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $ENVIRONMENT_DEFAULT_DOMAIN


echo  "link the private DNS zone to the virtual network of the environment for Azure Container Apps..."
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP_NAME \
  --zone-name $ENVIRONMENT_DEFAULT_DOMAIN \
  --name $PRIVATE_LINK_ENV_NAME \
  --virtual-network $VNET_NAME \
  --registration-enabled true


echo "create the A record in the private DNS zone for the environment for Azure Container Apps..."
az network private-dns record-set a add-record \
  --resource-group $RESOURCE_GROUP_NAME \
  --record-set-name "*" \
  --ipv4-address $ENVIRONMENT_IP_ADDRESS \
  --zone-name $ENVIRONMENT_DEFAULT_DOMAIN


###################################################
#                                                 #
#          Azure Container Registry               #
#                                                 #
###################################################
echo "Creating the Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP_NAME \
    --name $ACR_NAME \
    --admin-enabled true \
    --sku Basic

echo build and push image to Azure Container Registry
cd $PATH_DOCKERFILE
az acr build \
  --image $IMAGE_NAME:$IMAGE_NAME_VERSION \
  --registry $ACR_NAME .


echo "Getting the subscription ID..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"


echo "Creating the managed identity..."
az identity create \
    --name $IDENTITY \
    --resource-group $RESOURCE_GROUP_NAME

echo "Assigning the managed identity to the Azure Container Registry..."
az acr identity assign \
   --name $ACR_NAME \
   --identities $IDENTITY \
   --resource-group $RESOURCE_GROUP_NAME

echo "Getting the principal ID of the managed identity..."
PRINCIPAL_ID=$(az identity show --resource-group $RESOURCE_GROUP_NAME --name $IDENTITY --query principalId -o tsv)
echo "Principal ID: $PRINCIPAL_ID"


echo "Getting the ID of the managed identity..."
IDENTITY_ID=$(az identity show --resource-group $RESOURCE_GROUP_NAME --name $IDENTITY --query id -o tsv)
echo "Managed identity ID: $IDENTITY_ID"


echo "Waiting... (30 seconds)"
sleep 30


echo "Assigning the 'AcrPull' role to the managed identity..."
az role assignment create \
   --assignee $PRINCIPAL_ID \
   --role "AcrPull" \
   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME"


###################################################
#                                                 #
#            Azure Container Apps                 #
#                                                 #
###################################################
echo "Creating the Azure Container App..."
az containerapp create \
   --name $CONTAINERAPP_NAME \
   --resource-group $RESOURCE_GROUP_NAME \
   --environment $CONTAINERAPPS_ENVIRONMENT \
   --image $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_NAME_VERSION \
   --registry-server $ACR_NAME.azurecr.io \
   --registry-identity $IDENTITY_ID \
   --target-port 3000 \
   --ingress external \
   --secrets secret-db-host=$POSTGRESQL_SERVER_NAME.postgres.database.azure.com secret-db-user=$POSTGRESQL_ADMINUSER secret-db-password=$POSTGRESQL_ADMINPASSWORD secret-db-database=$POSTGRESQL_DBNAME secret-db-port=5432 \
   --env-vars DB_HOST=secretref:secret-db-host DB_USER=secretref:secret-db-user DB_PASS=secretref:secret-db-password DB_NAME=secretref:secret-db-database DB_PORT=secretref:secret-db-port \
   --min-replicas 1 \
   --max-replicas 3


###################################################
#                                                 #
#             vm rebond test (option)             #
#                                                 #
###################################################

echo "Creating the virtual machine..."
az vm create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name "vm-aca" \
    --image "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest" \
    --public-ip-sku Standard \
    --admin-username "user" \
    --admin-password "Password123$" \
    --public-ip-sku Standard \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_MAIN_NAME