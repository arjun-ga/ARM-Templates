# bicep-templates
This deplate will deploy following resources into a single resource group
Virtual Networks with two subnets once used by web app and another used by Private Endpoint
AppServicePlan
WebApp
Application isnights and Log Analytics Workspace 
Azure Monitor Private Link Scope
priavte Endpoint with Private DNS Zone Integration
Adds scoped resources AI and LAW to the AMPLS
This is for testing/recreate a environement that uses AMPLS, once test is completed you can delete the newly created resource group.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Farjun-ga%2Ftemplates%2Fmain%2Fazuredeploy.json)
