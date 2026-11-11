[Index](README.md) · [← Previous: Exercise 4: Preview and debug](10-exercise-preview-and-debug.md) · [Next: Exercise 6: Test as a seller →](12-exercise-test.md)

# 11. Exercise 5: Publish and connect

**Time:** 10 to 15 minutes  
**Tool:** Salesforce CLI, then the seller's browser  
**Output:** The agent is published, active, visible to the test seller, and answers when the seller asks Coworker

Until now the agent has been a draft that only builders can preview. Publishing turns it into a running agent. Activating makes that version live. The access permission set lets the seller see it.

---

## Pre-publish checklist

Don't publish until every box is ticked.

- [ ] `sf agent validate authoring-bundle --json --api-name Priority_Followthrough --target-org <alias>` shows `"success": true`
- [ ] The draft in the org matches your file (you deployed it after the last change)
- [ ] Live preview covered every branch on [page 10](10-exercise-preview-and-debug.md#step-5-cover-every-branch-as-time-allows): list, pick, edit, Opportunity, "yes" too early, ambiguous, no priorities, off topic, my book
- [ ] The traces show `log_priority_action` only on a "yes" turn, once, and never in `EnabledToolsStep`
- [ ] `config` has no `default_agent_user`, and the file has no `connection` block or `@utils.escalate`
- [ ] Both action definitions have an `outputs:` block
- [ ] **The customer lead approves publishing**

> **Every publish creates a permanent version number** (v1, v2, v3...). Old versions stay in the org, inactive. Only publish when the checklist passes.

---

## Step 1: Publish (3 min)

```bash
sf agent publish authoring-bundle --json --api-name Priority_Followthrough --target-org <alias>
```

This compiles the file on the server and creates a new version. **It does not activate it.**

**If it fails with "Internal Error, try again later":** this message doesn't say what's wrong. Work through the [Internal Error checklist](13-troubleshooting.md#publish-errors) in order. The usual causes are a `default_agent_user` line on this employee agent, or an action with no `outputs:` block.

To see which version you created:

```bash
sf data query --target-org <alias> -q "SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName = 'Priority_Followthrough' ORDER BY VersionNumber DESC"
```

---

## Step 2: Activate (1 min)

```bash
sf agent activate --json --api-name Priority_Followthrough --target-org <alias>
```

Only one version can be active. Activating a new one deactivates the old one.

Run the `BotVersion` query again: the newest version shows `Active`.

---

## Step 3: Check the published agent (2 min)

Preview the **published** agent, not your local file. Use `--api-name` instead of `--authoring-bundle`, and don't add `--use-live-actions` (a published agent always runs real actions).

```bash
sf agent preview start --json --api-name Priority_Followthrough --target-org <alias>
sf agent preview send --json --api-name Priority_Followthrough --session-id <ID> -u "What account priorities are open on DEMO Pinecrest School District?" --target-org <alias>
sf agent preview end --json --api-name Priority_Followthrough --session-id <ID> --target-org <alias>
```

Expected: one priority, "Only one contact on file", with recommended action "Identify a second decision maker in facilities". Don't confirm it; test 7 on [page 12](12-exercise-test.md) uses it.

If this preview fails with no valid version, Step 2 didn't run or didn't succeed.

---

## Step 4: Give the seller access (3 min)

The seller needs two permission sets:

| Permission set | What it gives | When it's deployed |
|---|---|---|
| `Priority_Agent_User` | The two Apex classes, read on account priorities and edit on their 3 status fields, Task and Opportunity create | Exercise 2 (or `deploy.sh`) |
| `Priority_Agent_Access` | Makes this agent visible to the user | **Now.** Its deploy fails until the agent is published |

### Prompt 11A: Deploy and assign access

```
ROLE
You are a Salesforce admin giving one seller access to a published
employee agent.

TASK
1. Confirm the agent Priority_Followthrough has an Active version:
   sf data query --target-org <alias> -q "SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName = 'Priority_Followthrough'"
2. Check which of Priority_Agent_User and Priority_Agent_Access the
   seller <seller-username> already has.
3. Show me the plan: what you will deploy, and which permission sets you
   will assign to which user. Wait for me to type "yes".
4. After "yes":
   sf project deploy start --json --metadata PermissionSet:Priority_Agent_Access --target-org <alias>
   sf org assign permset --target-org <alias> --name Priority_Agent_Access --on-behalf-of <seller-username>
   and, only if step 2 showed it missing:
   sf org assign permset --target-org <alias> --name Priority_Agent_User --on-behalf-of <seller-username>
5. Run the read-only check: ./code/validate.sh <alias> <seller-username>

EXPECTED OUTPUT
1. The plan, then a pause for "yes"
2. A table: step, command, result
3. The "Test seller" and "Agent" sections of validate.sh

RULES
- Deploy only PermissionSet:Priority_Agent_Access. Never run a bare
  sf project deploy start.
- Never assign Priority_Admin to the seller. It is for admins only.
- If no version is Active, stop and say so. Don't deploy.
- Every command uses --target-org <alias>.

EXAMPLE OUTPUT
Plan: deploy Priority_Agent_Access. Assign it to seller@example.com.
Priority_Agent_User is already assigned. Type "yes" to proceed.
[After yes]
| Step | Command | Result |
| Deploy | PermissionSet:Priority_Agent_Access | Succeeded |
| Assign | Priority_Agent_Access → seller@example.com | Succeeded |
validate.sh: [OK] Priority_Agent_User assigned, [OK] Priority_Agent_Access assigned
```

**What to check:**
- `validate.sh` shows OK for both permission sets under *Test seller*
- *Agent* shows the newest version as `Active`

The seller also needs Coworker access, from [2. Org setup](02-org-setup.md). The permission sets don't grant it.

---

## Step 5: The seller asks Coworker (3 min)

1. Log in as the test seller (Setup > Users > **Login** next to the user).
2. Open the Sales app and open Coworker.
3. Start a new conversation and type:

```
Act on DEMO Lakeshore Medical Group's top account priority
```

**Expected:** the Priority Follow-Through agent answers. It lists Lakeshore's open priorities by rank, or proposes a follow-up for rank 1. The seller can stop here; the full run is [Exercise 6](12-exercise-test.md).

**How to tell it was the agent and not Coworker answering:** the reply uses the agent's wording ("open account priorities", numbered with reason, recommended action and estimated value) and ends with a pick or "Create this?". Coworker's reasoning panel may show the hand-off **(to confirm: what it shows in this release)**.

### Be clear about routing

The Coworker documentation says Coworker "automatically routes your requests to the right Agentforce agent". **What makes a custom employee agent eligible for that routing in this org is (to confirm).** It may depend on the agent being active, the user having agent access, the agent's description, or a setting we haven't found.

| What happens | What it means | What to do |
|---|---|---|
| Coworker says the agent "doesn't appear in the available agent catalog" | The user doesn't have `Priority_Agent_Access` yet, or the page hasn't picked it up | Step 4, then reload and start a **new** conversation |
| The agent answers inside Coworker | Routing works in this org | Continue to [Exercise 6](12-exercise-test.md). Test 10 passes |
| Coworker answers itself (searches the account, offers to create a Task) | Coworker didn't route to the agent | Use the fallback below. Log test 10 as an open item for the account team |

### Fallback: open the agent from the Agentforce panel

1. Still logged in as the seller, open the Agentforce panel in Lightning Experience **(to confirm the entry point in this release, for example the Agentforce icon in the header)**.
2. Pick **Priority Follow-Through** from the agent list **(to confirm how the panel lists agents when more than one is available)**.
3. Ask the same question.

The agent, its actions, its gate and its consumption are the same either way. Only the front door changes. If the agent isn't in the list, check [Permission issues](13-troubleshooting.md#permission-issues).

---

## Changing the agent after publishing

The published version doesn't change when you edit the file. To ship a change:

1. Edit the file, validate, deploy the draft, and preview with `--use-live-actions` as on [page 10](10-exercise-preview-and-debug.md).
2. Deactivate the live version:
   ```bash
   sf agent deactivate --json --api-name Priority_Followthrough --target-org <alias>
   ```
3. Publish again. This creates the next version number.
4. Activate, then check with an `--api-name` preview.

While the agent is deactivated, sellers can't use it. Make changes between sessions, not while a seller is testing.

---

## What you have now

- A published, active version of Priority Follow-Through
- The test seller has `Priority_Agent_User` and `Priority_Agent_Access`
- The seller reached the agent from Coworker, or from the Agentforce panel with the routing gap logged

**Next:** [Exercise 6: Test as a seller](12-exercise-test.md)

---

[Index](README.md) · [← Previous: Exercise 4: Preview and debug](10-exercise-preview-and-debug.md) · [Next: Exercise 6: Test as a seller →](12-exercise-test.md)
