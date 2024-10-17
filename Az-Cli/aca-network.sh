#!/bin/bash

# define variables
RESOURCE_GROUP_NAME="rg-aca-az-cli"
LOCATION="francecentral"

VNET_NAME="vnet-aca"
PREFIX_VNET="10.0.0.0/16"
SUBNET_ACA_NAME="subnet-aca"
PREFIX_SUBNET="10.0.0.0/27"
SUBNET_MAIN_NAME="subnet-main"
PREFIX_SUBNET_MAIN="10.0.0.32/27"
SUBNET_PE_NAME="subnet-pe"
PREFIX_SUBNET_PE="10.0.0.64/27"

CONTAINERAPPS_ENVIRONMENT="env-aca"

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
PRIVATE_LINK_NAME="privatelink-aca"


## Create the resource group
#echo "Creating the resource group..."
#az group create \
#    --name $RESOURCE_GROUP_NAME \
#    --location $LOCATION
#
#
## Create the virtual network
#echo "Creating the virtual network..."
#az network vnet create \
#    --name $VNET_NAME \
#    --resource-group $RESOURCE_GROUP_NAME \
#    --location $LOCATION \
#    --address-prefix $PREFIX_VNET
#
## Create the subnet with delegation "Microsoft.App/environments"
#echo "Creating the subnet with delegation "Microsoft.App/environments"..."
#az network vnet subnet create \
#    --name $SUBNET_ACA_NAME \
#    --resource-group $RESOURCE_GROUP_NAME \
#    --vnet-name $VNET_NAME \
#    --address-prefix $PREFIX_SUBNET \
#    --delegations "Microsoft.App/environments"
#
## Create the subnet main"
#echo "Creating the subnet main..."
#az network vnet subnet create \
#    --name $SUBNET_MAIN_NAME \
#    --resource-group $RESOURCE_GROUP_NAME \
#    --vnet-name $VNET_NAME \
#    --address-prefix $PREFIX_SUBNET_MAIN
#
## Create the subnet pe
#echo "Creating the subnet pe (pg)..."
#az network vnet subnet create \
#    --name $SUBNET_PE_NAME \
#    --resource-group $RESOURCE_GROUP_NAME \
#    --vnet-name $VNET_NAME \
#    --address-prefix $PREFIX_SUBNET_PE
#
#
## Create the postgresql server
#echo "Creating the PostgreSQL server..."
#az postgres flexible-server create \
#  --name $POSTGRESQL_SERVER_NAME \
#  --resource-group $RESOURCE_GROUP_NAME \
#  --location $LOCATION \
#  --admin-user $POSTGRESQL_ADMINUSER \
#  --admin-password $POSTGRESQL_ADMINPASSWORD \
#  --sku-name $POSTGRESQL_SKUNAME \
#  --tier $POSTGRESQL_TIER \
#  --version $POSTGRESQL_VERSION \
#  --storage-size $POSTGRESQL_STORAGESIZE \
#  --public-access 'None'
#
## Create the private endpoint
#echo "Creating the private endpoint for PostgreSQL server..."
#az network private-endpoint create \
#  --name $PRIVATE_ENDPOINT_NANE \
#  --connection-name $CONNECTION_NAME \
#  --nic-name $NIC_PRIVATE_ENDPOINT_NANE \
#  --resource-group $RESOURCE_GROUP_NAME \
#  --vnet-name $VNET_NAME \
#  --subnet $SUBNET_PE_NAME \
#  --private-connection-resource-id $(az postgres flexible-server show \
#                                       --resource-group $RESOURCE_GROUP_NAME \
#                                       --name $POSTGRESQL_SERVER_NAME \
#                                       --query id -o tsv) \
#  --group-id postgresqlServer
#
## Creare the private DNS zone
#echo "Creating the private DNS zone..."
#az network private-dns zone create \
#   --resource-group $RESOURCE_GROUP_NAME \
#   --name $DNS_ZONE_NAME
#
## Create the link between the private DNS zone and the virtual network
#echo "Creating the link between the private DNS zone and the virtual network..."
#az network private-dns link vnet create \
#  --resource-group $RESOURCE_GROUP_NAME \
#  --zone-name $DNS_ZONE_NAME \
#  --name $PRIVATE_LINK_NAME \
#  --virtual-network $VNET_NAME \
#  --registration-enabled false
#
#
#PRIVATE_IP=$(az network nic show \
#               --name $NIC_PRIVATE_ENDPOINT_NANE \
#               --resource-group $RESOURCE_GROUP_NAME \
#               --query "ipConfigurations[0].privateIPAddress" \
#               -o tsv)
#
## Create the A record in the private DNS zone
#echo "Creating the A record in the private DNS zone..."
#az network private-dns record-set a create \
#   --name $POSTGRESQL_SERVER_NAME \
#   --zone-name $DNS_ZONE_NAME \
#   --resource-group $RESOURCE_GROUP_NAME
#
## Add the A record in the private DNS zone with the private IP address of the PostgreSQL server
#echo "Adding the A record in the private DNS zone with the private IP address of the PostgreSQL server..."
#az network private-dns record-set a add-record \
#   --record-set-name $POSTGRESQL_SERVER_NAME \
#   --zone-name $DNS_ZONE_NAME \
#   --resource-group $RESOURCE_GROUP_NAME \
#   -a $PRIVATE_IP

# create log analytics workspace
#echo "Creating the Log Analytics workspace law-$CONTAINERAPPS_ENVIRONMENT..."
#az monitor log-analytics workspace create \
#   --resource-group $RESOURCE_GROUP_NAME \
#   --workspace-name "law-$CONTAINERAPPS_ENVIRONMENT" \
#   --location $LOCATION

# get the workspace ID
echo "Getting the workspace ID..."
WORKSPACE_ID=$(az monitor log-analytics workspace show \
   --resource-group $RESOURCE_GROUP_NAME \
   --workspace-name "law-$CONTAINERAPPS_ENVIRONMENT" \
   --query customerId -o tsv)

# get the workspace key
echo "Getting the workspace key..."
WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
   --resource-group $RESOURCE_GROUP_NAME \
   --workspace-name "law-$CONTAINERAPPS_ENVIRONMENT" \
   --query primarySharedKey -o tsv)

# get subnet id subnet-aca
echo "Getting the subnet id subnet-aca..."
SUBNET_ACA_ID=$(az network vnet subnet show \
   --resource-group $RESOURCE_GROUP_NAME \
   --vnet-name $VNET_NAME \
   --name $SUBNET_ACA_NAME \
   --query id -o tsv)

# create an environment for Azure Container Apps
echo "Creating the environment for Azure Container Apps..."
az containerapp env create \
   --name $CONTAINERAPPS_ENVIRONMENT \
   --resource-group $RESOURCE_GROUP_NAME \
   --internal-only true \
   --infrastructure-subnet-resource-id $SUBNET_ACA_ID \
   --logs-workspace-id $WORKSPACE_ID \
   --logs-workspace-key $WORKSPACE_KEY \
   --location $LOCATION
