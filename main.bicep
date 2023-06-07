/* This deplate will deploy following resources into a single resource group
Virtual Networks with two subnets once used by web app and another used by Private Endpoint
AppServicePlan S1 SKU
WebApp
Application isnights and Log Analytics Workspace 
Azure Monitor Private Link Scope
priavte Endpoint with Private DNS Zone Integration
Adds scoped resources AI and LAW to the AMPLS
This is for testing/recreate a environement that uses AMPLS, once test is completed you can delete the newly created resource group.
*/

@description(' This is Prefix of all resources. for e.g webapp will be baseName-webapp')
param baseName string

@description('Location where the resources will be deployed.')
param location string = resourceGroup().location

var vnetName = '${baseName}-vnet'
var subnetName = '${vnetName}-subnet'
var privateLinkScopeName = '${baseName}-private-link-scope'
var privateEndpointName = '${baseName}-private-endpoint'
var pvtEndpointDnsGroupName = '${privateEndpointName}/default'
var appName = '${baseName}-WebApp${uniqueString(resourceGroup().id)}'
var appServicePlanName = '${appName}-ASP'
var appServicePlanSku = 'S1'
var appInsightName = '${baseName}-AI'
var logAnalyticsName = '${baseName}-LAW'

// Creating Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
       '10.0.0.0/16'
      ]
    }
  }
}
//Creating Subnet for AppService
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: '10.0.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    delegations: [
      {
      name: 'Microsoft.Web.serverFarms'
      properties: {
        serviceName: 'Microsoft.Web/serverFarms'
      }
      }
    ]
  }
}

//Creating Subnet for PrivateEndpoint
resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: vnet
  name: '${subnetName}-pe'
  properties: {
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
  dependsOn:[
    subnet
  ]
}

//creating App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  kind: 'app'
}

//Creating WebApp
resource webApp 'Microsoft.Web/sites@2021-01-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: subnet.id
    httpsOnly: true
    siteConfig: {
      vnetRouteAllEnabled: true
      http20Enabled: true
    }
  }
  dependsOn:[
    vnet
  ]
}

//creating Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightName
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
    ProjectName: appName
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
//Creating Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsName
  location: location
  tags: {
    displayName: 'Log Analytics'
    ProjectName: appName
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
 }
}

//Enabling Application Insights Auto Instrumentation 
resource appServiceLogging 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    ApplicationInsightsAgent_EXTENSION_VERSION : '~2'
    XDT_MicrosoftApplicationInsights_Mode: 'recommended'
    InstrumentationEngine_EXTENSION_VERSION: '~1'
  }
 }

// Creating AMPLS with access mode open
resource privateLink 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: privateLinkScopeName
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'Open'
      queryAccessMode: 'Open'
    }
  }
}

//Creating Private Endpoint 
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLink.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
}

//Creating Private DNS Zones
resource privatelink_monitor_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.monitor.azure.com'
  location: 'global'
  tags: {}
  properties: {}
}
resource privatelink_oms_opinsights_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.oms.opinsights.azure.com'
  location: 'global'
  tags: {}
  properties: {}
}
resource privatelink_ods_opinsights_azure_com 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.ods.opinsights.azure.com'
  location: 'global'
  tags: {}
  properties: {}
}
resource privatelink_agentsvc_azure_automation_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.agentsvc.azure-automation.net'
  location: 'global'
  tags: {}
  properties: {}
}
resource privatelink_blob_core_windows_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: {}
  properties: {}
}

//Creating Virtual Network links with the Private DNS Zones
resource privatelink_monitor_azure_com_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_monitor_azure_com
  name: 'privatelink_monitor_azure_com-vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}
resource privatelink_oms_opinsights_azure_com_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_oms_opinsights_azure_com
  name: 'privatelink_oms_opinsights_azure_com-vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}
resource privatelink_ods_opinsights_azure_com_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_ods_opinsights_azure_com
  name: 'privatelink_ods_opinsights_azure_com-vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}
resource privatelink_agentsvc_azure_automation_net_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_agentsvc_azure_automation_net
  name: 'privatelink_agentsvc_azure_automation_net-vnetlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}
resource privatelink_blob_core_windows_net_vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_blob_core_windows_net
  name: 'privatelink_blob_core_windows_net-ventlink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

// Creating Private DNS Zone Group
resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupName
   properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-monitor-azure-com'
        properties: {
          privateDnsZoneId: privatelink_monitor_azure_com.id
        }
      }
      {
        name: 'privatelink-oms-opinsights-azure-com'
        properties: {
          privateDnsZoneId: privatelink_oms_opinsights_azure_com.id
        }
      }
      {
        name: 'privatelink-ods-opinsights-azure-com'
        properties: {
          privateDnsZoneId: privatelink_ods_opinsights_azure_com.id
        }
      }
      {
        name: 'privatelink-agentsvc-azure-automation-net'
        properties: {
          privateDnsZoneId: privatelink_agentsvc_azure_automation_net.id
        }
      }
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privatelink_blob_core_windows_net.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

//Adding Application insights and LAW to AMPLS
resource logAnalyticsPrivateLink 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: 'logAnalyticsPrivateLink'
  parent: privateLink
  properties: {
    linkedResourceId: logAnalyticsWorkspace.id
  }
  dependsOn:[
    privateEndpoint
  ]
}
resource appInsightsPrivateLink 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: 'appInsightsPrivateLink'
  parent: privateLink
  properties: {
    linkedResourceId: appInsights.id
  }
  dependsOn:[
    privateEndpoint
  ]
}

