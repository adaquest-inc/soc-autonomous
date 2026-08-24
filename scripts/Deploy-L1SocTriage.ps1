[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$TemplateFile = ".\azuredeploy.json",

    [Parameter(Mandatory = $false)]
    [string]$ParametersFile = ".\azuredeploy.parameters.json",

    [Parameter(Mandatory = $false)]
    [string]$DeploymentName = "adaquest-l1-soc-triage"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId

az deployment group validate `
    --name "$DeploymentName-validate" `
    --resource-group $ResourceGroupName `
    --template-file $TemplateFile `
    --parameters "@$ParametersFile"

az deployment group create `
    --name $DeploymentName `
    --resource-group $ResourceGroupName `
    --template-file $TemplateFile `
    --parameters "@$ParametersFile"
