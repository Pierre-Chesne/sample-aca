targetScope = 'subscription'

param location string
param rgName string
param environmentName string
param containerAppName string

// create resource group
module rgModule 'rg.bicep' = {
  name: 'deployRgModule'  
  params: {
    location: location
    rgName: rgName 
  }
}

// create control plan
module controlPlanModule 'plan.bicep' = {
  scope: resourceGroup(rgName)
  name: 'deploycontrolPlanModule'
  params: {
    environmentName: environmentName
    location: location
    //containerAppName: containerAppName
  }
  dependsOn: [
    rgModule
  ]
}


// create app
module appModule 'app.bicep' = {
  scope: resourceGroup(rgName)
  name: 'deployappModule'
  params: {
    containerAppName: containerAppName
    location: location
    envId: controlPlanModule.outputs.environment
    
    
  }
  dependsOn: [
    controlPlanModule
  ]
}
