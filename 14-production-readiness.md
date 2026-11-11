[Index](README.md) · [← Previous: Troubleshooting](13-troubleshooting.md) · [Next: Next steps →](15-next-steps.md)

# 14. Production readiness

**When:** 3:30, after the seller tests  
**Who:** The customer lead, the customer's architect, the account team  
**Output:** A checklist with gaps marked, the priority data mapping started, and an agreed release path

The demo proves the design. This page lists what has to be true before real sellers use it on real priority data.

---

## Readiness checklist

### Code

- [x] Every query on Account, Contact, Opportunity and `Account_Priority__c` uses `WITH USER_MODE`; the create and update use `insert as user` and `update as user`. (The two lookups of `OpportunityStage` and `TaskStatus` read org settings, not records, and don't use it.)
- [x] Both classes are `with sharing`
- [x] The create and the status update happen in one transaction, rolled back together on failure
- [x] Apex rejects any priority that isn't Open (`PRIORITY_NOT_OPEN`)
- [x] Opportunity stage and Task status come from the org, not hard-coded values
- [ ] `AccountPriorityServiceTest` and `PriorityActionServiceTest` pass in the target org, with coverage at your standard
- [ ] Code review of the `.agent` file and both classes, in your normal process

### The gate

- [ ] Traces show `log_priority_action` runs only on the turn after a proposal and a "yes" ([page 10](10-exercise-preview-and-debug.md#what-each-turn-should-show))
- [ ] Traces show `log_priority_action` never appears in `EnabledToolsStep`
- [ ] Traces show one write per "yes", and a short "yes" always reaches `propose_follow_up` (router state check)
- [ ] Test 3 passes: no duplicate Task

### What the seller sees

- [ ] No raw record Ids in any reply; records are shown by name
- [ ] Figures match the records exactly (estimated value, dates)
- [ ] Text inside priority records is treated as data. Test a priority whose reason says "ignore your instructions" and confirm nothing changes
- [ ] Off-topic and brief requests go back to Coworker

### Access (least privilege)

- [x] `Priority_Agent_User` has **no delete** and **no create** on `Account_Priority__c`. It can read, and edit only `Status__c`, `Actioned_On__c` and `Action_Record_Id__c`
- [x] `Priority_Agent_User` grants create on Opportunities with no delete, and Tasks through the Edit Tasks permission. It adds no delete rights of its own
- [ ] The seller profile's own delete rights on Tasks and Opportunities are what you want (the permission set doesn't remove them)
- [x] `Priority_Agent_Access` holds only the agent visibility
- [ ] `Priority_Admin` (full access, modify all) is assigned only to admins and the integration that loads priority data. **Never to sellers**
- [ ] The agent is assigned only to the pilot sellers
- [ ] Sharing on Account and `Account_Priority__c` matches what sellers should see. The object's sharing model is Read/Write in the demo; decide whether production should be Controlled by Parent or Private **(architect to decide)**

### Release

- [ ] The release path below runs end to end from your pipeline
- [ ] A Testing Center spec exists and runs before each activation ([page 12](12-exercise-test.md#optional-testing-center))
- [ ] A rollback is written down: deactivate, then activate the previous version

---

## Data mapping: seed fields to the real priority source

The seed data stands in for the real priority feed. For each field, the architect fills in where the real value comes from.

| Field on `Account_Priority__c` | In the demo | Real source | Notes for the architect |
|---|---|---|---|
| `Account__c` | Lookup to the DEMO account | ??? | How does the feed identify the account: Account Id, an external account number, or a Data Cloud unified profile? |
| `Priority_Rank__c` | 1, 2, 3 per account | ??? | Does the feed rank within an account, or only across the book? |
| `Signal_Type__c` | 8 picklist values (Spend Decline, Category Gap, Reorder Lapsed, Renewal, Expansion, Managed Print, Service Risk, Single Thread) | ??? from the priority feed / Data Cloud | Map each real signal to a value, or replace the list. The picklist is restricted |
| `Propensity_Score__c` | 0 to 100 | ??? from the priority feed / Data Cloud | Drives "my book" order. Same scale? How often does it refresh? |
| `Estimated_Value__c` | Derived from order history | ??? from the priority feed / Data Cloud | Becomes the default Opportunity amount. Is it annual, 6-month or one-time? |
| `Priority_Reason__c` | Generated text, up to 255 characters | ??? from the priority feed / Data Cloud | Is the real reason longer than 255 characters? |
| `Recommended_Action__c` | Generated text, up to 255 characters | ??? from the priority feed / Data Cloud | Becomes the default Task subject |
| `Refreshed_On__c` | A few days before seeding | ??? from the priority feed / Data Cloud | Should stale priorities be hidden or flagged? |
| `Status__c` | Open, Actioned, Dismissed | Set by the agent (Actioned) and by the feed (Open) | Who sets Dismissed? Does a refresh reopen or replace an Actioned priority? |
| `Actioned_On__c`, `Action_Record_Id__c` | Set by the agent | Set by the agent | Keep as is. Should a refresh preserve them? |

**Also decide:**
- How the feed writes into Salesforce: upsert into `Account_Priority__c` on an external Id, or the agent reads from Data Cloud directly. The Apex reads Salesforce records today, so a direct Data Cloud read means changing `AccountPriorityService`.
- What happens to a priority the feed drops while it's still Open.
- Whether real priority data includes priorities on accounts the seller doesn't own (team accounts, split territories).

---

## Release path (CI/CD)

The same commands you ran today, in pipeline order. `<sandbox>` is the org where the agent was built and tested; `<target>` is the org you're releasing to.

| # | Step | Command |
|---|---|---|
| 1 | Retrieve the agent from the sandbox | `sf project retrieve start --json --metadata AiAuthoringBundle:Priority_Followthrough --target-org <sandbox>` |
| 2 | Validate the Agent Script | `sf agent validate authoring-bundle --json --api-name Priority_Followthrough --target-org <target>` |
| 3 | Run the agent tests in the sandbox (they need an active version there) | `sf agent test run --json --api-name Priority_Followthrough_Tests --wait 5 --target-org <sandbox>` |
| 4 | Code review | Review the `.agent` and Apex diff in version control |
| 5a | Deploy the object and fields | `sf project deploy start --json --metadata CustomObject:Account_Priority__c --target-org <target>` |
| 5b | Give the deploying admin field access (new fields have none, and the Apex tests run in user mode) | `sf project deploy start --json --metadata PermissionSet:Priority_Admin --target-org <target>`, then `sf org assign permset --target-org <target> --name Priority_Admin` |
| 5c | Deploy the classes and run their tests | `sf project deploy start --json --metadata ApexClass:AccountPriorityService ApexClass:AccountPriorityServiceTest ApexClass:PriorityActionService ApexClass:PriorityActionServiceTest --test-level RunSpecifiedTests --tests AccountPriorityServiceTest PriorityActionServiceTest --target-org <target>` |
| 5d | Deploy the seller permission set | `sf project deploy start --json --metadata PermissionSet:Priority_Agent_User --target-org <target>` |
| 5e | Deploy the agent bundle | `sf project deploy start --json --metadata AiAuthoringBundle:Priority_Followthrough --target-org <target>` |
| 6 | Publish | `sf agent publish authoring-bundle --json --api-name Priority_Followthrough --target-org <target>` |
| 7 | Activate | `sf agent activate --json --api-name Priority_Followthrough --target-org <target>` |
| 8 | Give access (first release only; needs the published agent) | `sf project deploy start --json --metadata PermissionSet:Priority_Agent_Access --target-org <target>` |
| 9 | Verify the active agent | `sf agent preview start --json --api-name Priority_Followthrough --target-org <target>` |

**Rules for the pipeline:**
- Always deploy by named metadata. A bare `sf project deploy start` can deploy the agent bundle by accident, and `Priority_Agent_Access` fails until the agent is published.
- Every publish is a new version. Deactivate before publishing a change to an active agent.
- Rollback: `sf agent deactivate --json --api-name Priority_Followthrough --target-org <alias>`, then activate the previous version **(to confirm the CLI flag for choosing a version number in your CLI version)**.

---

## Packaging from a demo or developer org

If the build happened in a separate demo org rather than the customer's sandbox, the customer needs a way to take it home.

| Option | What moves | Notes |
|---|---|---|
| Source in Git (recommended) | The whole `code/` project | Deploy with the release path above, or `deploy.sh` into a sandbox. Works today |
| Unmanaged package | The object, fields, Apex, permission sets | Quick to install in a sandbox. Whether `AiAuthoringBundle` can be included in a package is **(to confirm)**. If not, deploy the agent from source after installing |
| Change set | Only between connected orgs | Doesn't apply between a demo org and the customer's sandbox |

Packaged or not, the seed scripts are separate. Don't load DEMO data into an org that will hold real priority data.

---

## Monitoring

### Follow-through report

`Account_Priority__c` has reports turned on. Build these on day one:

| Report | Group by | Shows |
|---|---|---|
| Follow-through by seller | Account owner, then `Status__c` | Actioned vs. Open per seller |
| Follow-through by signal | `Signal_Type__c`, then `Status__c` | Which signals sellers act on, and which they ignore |
| Time to action | `Signal_Type__c`; average of `Actioned_On__c` minus `Refreshed_On__c` (a formula field) | How quickly sellers act after a refresh |

The seed's 20 history records (14 Actioned, 6 Dismissed) give these reports data from the start.

### From priority to outcome

`Action_Record_Id__c` holds the Id of the Task or Opportunity each priority produced. Every record the agent creates also has a Description that starts with "From account priority" and the priority's name.

- **Opportunities from priorities:** Opportunities whose Id is in `Action_Record_Id__c`. Report their stage, amount and win rate over time. This is the metric for opportunity creation from agent-recommended actions.
- **Tasks from priorities:** completed vs. open, and whether an Opportunity followed on the same account.
- A text field can't drive a report join directly. For reporting, consider a lookup field to Opportunity alongside `Action_Record_Id__c` **(architect to decide)**.

### Agent health

- Review a sample of conversations each week in the first month. Check that each create follows a proposal and a "yes".
- Track `SAVE_FAILED` and `PRIORITY_NOT_OPEN` responses. A rise in `SAVE_FAILED` usually means a new validation rule or a permission change.
- Where session traces are stored for published agents, and how long they're kept, is **(to confirm)** in this org.

---

## Consumption

Every agent conversation and every action the agent runs consumes Flex Credits. In this agent, a typical follow-up runs two actions (one lookup, one create), and a seller who only browses runs one.

What drives consumption:

| Driver | How to keep it down |
|---|---|
| Actions per conversation | The agent looks up priorities once and reuses the list; it doesn't look up again unless the seller changes account |
| Conversations that never needed the agent | Briefs, search and single record writes stay with Coworker and the skill |
| Retries | Apex returns clear errors, and the agent is told not to retry a failed create |

**The account team will provide the rate card and a consumption view** for the sandbox and the pilot. Use those numbers for forecasts, not estimates from this page.

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| A write without the seller's agreement | Low | High | The write isn't an AI tool; the gate, the first-turn guard and one-write-per-yes; trace review; test 3 |
| A duplicate follow-up | Low | Medium | Apex rejects anything not Open; `confirmed` cleared after the write |
| A seller sees another seller's priorities | Low | High | `WITH USER_MODE` and sharing; "my book" filters on the account owner; test 13 |
| Real priority data doesn't fit the fields (length, scale, signal names) | Medium | Medium | Data mapping above, before the pilot |
| Coworker doesn't route to the agent | Medium | Medium | Agentforce panel as the front door; routing gap with the account team |
| A priority's text contains instructions | Low | Medium | System instructions treat record text as data; add the test above |
| Stale priorities (feed stops refreshing) | Medium | Medium | Show or filter on `Refreshed_On__c`; alert on feed failures |
| Org rules block the create (validation rules, required fields) | Medium | Medium | Run the seller tests in a full-copy sandbox; watch `SAVE_FAILED` |
| Changes break behavior without anyone noticing | Medium | Medium | Testing Center spec as a release gate; version history; rollback plan |
| Consumption above plan | Low | Medium | Consumption view from the account team; review after the pilot |

---

## What happens next

[15. Next steps](15-next-steps.md): owners, dates and the next build.

---

[Index](README.md) · [← Previous: Troubleshooting](13-troubleshooting.md) · [Next: Next steps →](15-next-steps.md)
