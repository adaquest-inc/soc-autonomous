# Microsoft Teams notification upgrade

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fadaquest-inc%2Fsoc-autonomous%2Fmain%2Fazuredeploy.teams-upgrade.json)

Version: **0.4.1**

Use this incremental template only when the L1 SOC Triage launcher, actions
workflow, connections, and Sentinel Automation Rule are already deployed from
the adaQuest package.

## What the upgrade changes

- Creates `la-adaquest-l1-soc-triage-notifications`.
- Creates one Microsoft Teams API connection.
- Updates the existing actions Logic App to call the notifications workflow
  after a confirmed automatic close or verified L2/L3 escalation.
- Adds four deployment parameters for the two Teams destinations.

## What the upgrade preserves

- The Security Copilot agent manifest and installed agent.
- The launcher Logic App.
- The Security Copilot connection.
- Existing Microsoft Sentinel and Azure Monitor Logs connections.
- The Microsoft Sentinel Automation Rule.
- The current actions HTTP trigger name, `ReceiveL1TriageResult`.
- The existing owner-preservation behavior.

## Before deployment

1. Export the current actions Logic App as a backup.
2. Confirm that its resource name follows the deployed package, normally
   `la-adaquest-l1-soc-triage-actions`.
3. Confirm that its existing connection names are:
   `conn-<actions-name>-logs` and `conn-<actions-name>-sentinel`.
4. Record the current escalation UPN, Sentinel subscription, resource group,
   workspace, and actions region.
5. Obtain the Team ID and Channel ID for the closed-incidents destination.
6. Obtain the Team ID and Channel ID for the L2/L3 escalation destination.
7. Ensure the Microsoft 365 account that will authorize the Teams connection
   can post in both channels.

### Extract Team and Channel IDs

For each destination, use Microsoft Teams desktop or web:

1. Open the channel menu (`...`).
2. Select **Copy link** or **Get link to channel**.
3. Run the helper and paste the complete copied link:

```powershell
.\scripts\Get-TeamsChannelIds.ps1
```

The helper accepts a raw Teams URL and the Markdown form `[URL](URL)`. It also
decodes values such as `%3A` to `:` and `%40` to `@`.

Example direct invocation:

```powershell
.\scripts\Get-TeamsChannelIds.ps1 -ChannelLink '<COPIED-TEAMS-CHANNEL-LINK>'
```

If the actions Logic App was manually changed after the v0.3.1 deployment,
compare/export those changes first. This upgrade intentionally replaces the
actions workflow definition with the v0.4.1 definition.

## Deployment

1. Select **Deploy to Azure**.
2. Select the same subscription and resource group that contain the existing
   actions Logic App.
3. Keep `actionsLogicAppName`, `actionsLocation`, Sentinel values, and
   `escalationAssigneeUPN` identical to the current deployment.
4. Enter the new notifications Logic App name and both Team/Channel pairs.
5. Deploy in **Incremental** mode. Never use Complete mode for this upgrade.
6. Wait for the ARM deployment to finish.

## Required authorization

Open the new API connection:

`conn-<notifications-name>-teams`

Select **Authorize** and sign in with an account that can post in both target
channels. The ARM template cannot silently complete delegated Microsoft Teams
OAuth authorization.

## Validation

1. Run one safe auto-close test. Confirm the Sentinel incident is closed and
   the message appears only in the closed-incidents channel.
2. Run one escalation test. Confirm the incident remains active, the owner is
   preserved or assigned correctly, and the message appears only in the L2/L3
   channel.
3. Temporarily test a delivery failure, if desired. Sentinel actions must remain
   completed and the actions Logic App must record a `WARNING_TEAMS_*` result.

No Security Copilot agent manifest change is required for this upgrade.
