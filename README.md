# Deploy WebApp with Vnet-Integration, Application Insights, LAW, AMPLS and Private Link Connection
This deplate will deploy following resources into a existing single resource group
- Virtual Networks with two subnets one used by web app and another used by Private Endpoint
- AppServicePlan
- WebApp
- Application isnights and Log Analytics Workspace 
- Azure Monitor Private Link Scope
- priavte Endpoint with Private DNS Zone Integration
- Adds scoped resources AI and LAW to the AMPLS

This is for testing/recreating an environement that uses AMPLS. Once test is completed resource group can be deleted to remove all the deployed resources.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Farjun-ga%2Ftemplates%2Fmain%2Fazuredeploy.json)
