# adaQuest Autonomous SOC — L1 Triage

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fadaquest-inc%2Fsoc-autonomous%2Fmain%2Fazuredeploy.json)

Version: **0.3.1 (deployment MVP)**

This public deployment package installs the Azure automation layer used by the
adaQuest L1 SOC Triage Security Copilot agent. Select **Deploy to Azure**, sign
in to the customer tenant and complete the parameters shown by Azure Portal.

This package deploys:

- `la-adaquest-l1-soc-triage-launcher`
- `la-adaquest-l1-soc-triage-actions`
- Azure Monitor Logs managed-identity connection for the actions workflow
- Microsoft Sentinel managed-identity connections for both workflows
- Security Copilot connection for the launcher
- Connection access policies for both Logic App managed identities
- Microsoft Sentinel automation rule: incident created → run the launcher
- Optional Microsoft Sentinel Automation Contributor role assignment
- Existing incident owner protection: a manual owner is never replaced by the configured escalation UPN

It does **not** modify the existing Logic Apps used in the adaQuest development tenant.

## Files

- `azuredeploy.json`: combined ARM template.
- `azuredeploy.parameters.example.json`: customer-specific parameter example.
- `scripts/Deploy-L1SocTriage.ps1`: optional Azure CLI deployment helper in the GitHub repository.

## Before selecting Deploy to Azure

Have the following customer values available:

1. Target Azure subscription and resource group for the package. Create the
   resource group first if it does not exist.
2. Microsoft Sentinel workspace subscription ID.
3. Sentinel workspace resource group and workspace name.
4. Security Copilot agent ID installed in the customer tenant.
5. Optional Microsoft Entra UPN that will receive escalated incidents.
6. Microsoft Sentinel Automation enterprise application Object ID, if the role assignment will be automated.
7. Regions where the managed connectors are available. Defaults: `eastus2` for actions and `eastus` for launcher.

## One-click Azure Portal deployment

1. Select the **Deploy to Azure** button at the top of this page.
2. Select the customer subscription and target resource group.
3. Enter the Microsoft Sentinel workspace and Security Copilot agent values.
4. Enter an escalation owner UPN only when unassigned escalated incidents should
   receive a default owner. An owner already present on the incident is preserved.
5. Keep the automation rule enabled unless the customer wants a controlled test
   before automatic execution.
6. Select **Review + create**, wait for validation, and then select **Create**.
7. Complete every post-deployment step below before testing a new incident.

The template source used by the button is the public root-level
`azuredeploy.json` on the `main` branch.

### Azure CLI

1. Copy `azuredeploy.parameters.example.json` to `azuredeploy.parameters.json`.
2. Replace every placeholder with the customer values.
3. Run:

```powershell
.\scripts\Deploy-L1SocTriage.ps1 `
  -SubscriptionId '<TARGET-SUBSCRIPTION-ID>' `
  -ResourceGroupName '<TARGET-RESOURCE-GROUP>' `
  -ParametersFile '.\azuredeploy.parameters.json'
```

## Required post-deployment steps

The ARM template creates the resources, but Azure security boundaries require the following customer-side steps:

1. In the deployment resource group, open the Security Copilot API connection
   named `conn-<launcher-name>-securitycopilot` and select **Authorize**.
2. Grant the actions Logic App managed identity the least-privilege Sentinel/Log Analytics roles needed to query and update incidents. For the MVP, validate **Microsoft Sentinel Responder** plus the required workspace query access.
3. Grant the launcher Logic App managed identity permission to use the Sentinel incident trigger.
4. Connect the installed Security Copilot agent to the deployed `ReceiveL1TriageResult` trigger in `la-adaquest-l1-soc-triage-actions`.
5. In Microsoft Sentinel, confirm that the automation rule
   `[AQ-Autonomous] L1 SOC Triage Agent` was created and is enabled.
6. Confirm the `escalationAssigneeUPN` supplied during deployment. The actions Logic App uses this deployment parameter as the escalation owner.
7. Run one escalation test and one safe auto-close test, confirming comment, tag, status and owner.

For the escalation test, include one incident that already has an owner. The expected result is `SUCCESS_ESCALATED_EXISTING_OWNER_PRESERVED`, and the original owner must remain unchanged.

If `sentinelAutomationServicePrincipalObjectId` is empty, grant the Microsoft Sentinel Automation Contributor role manually to the Microsoft Sentinel Automation service account on the resource group containing the playbooks. The person granting this role must have Owner or User Access Administrator permission.

OAuth authorization and tenant role consent cannot be silently completed by an ARM template. These remain explicit post-deployment actions.

## Expected resources

After a successful deployment, the target resource group contains two Logic
Apps and four API connections. The Sentinel workspace contains one incident-
created automation rule. The actions Logic App preserves any owner that was
already assigned manually.

## Planned extension

Email notification will be introduced as a later module. It is intentionally
not included in version 0.3.1, so this deployment remains aligned
with the tested MVP.
