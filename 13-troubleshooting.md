[Index](README.md) · [← Previous: Test the whole path in Coworker](12a-test-in-coworker.md) · [Next: Production readiness →](14-production-readiness.md)

# 13. Troubleshooting

Common problems during the build, grouped by where they show up. If you're stuck and short on time, jump to [Fallback: deploy the pre-tested version](#fallback-deploy-the-pre-tested-version).

---

## Compile errors

These come from `sf agent validate authoring-bundle`. The details are in the `message` field of the JSON, usually with a line and column. Paste the JSON into [Prompt 9B](09-exercise-write-agent-script.md#prompt-9b-fix-validation-errors).

| Symptom | Cause | Fix |
|---|---|---|
| Unexpected indent, or a block "not found" that is clearly there | A tab, or a level indented by 2, 3 or 5 spaces | 4 spaces per level, no tabs. Turn on "render whitespace" in VS Code to see them |
| Error at `else` | `else if` | Agent Script has no `else if` and no nested `if`. Use flat `if` lines, or one `if` with `and` |
| Error inside an `if` inside another `if` | Nested `if` | Combine: `if @variables.report_pending == True and @variables.result_success == True:` |
| Error at `true` or `false` | Lowercase booleans | `True` and `False` |
| Unknown output, or an `@outputs.x` that doesn't resolve | `x` isn't declared under the action's `outputs:`, or the name doesn't match the Apex | Declare it with the exact Apex `@InvocableVariable` name and type, for example `priorityCount: integer` |
| Error at a `set` line under `choose_priority` or `confirm_follow_up` | `set` on `@utils.setVariables` | Utility actions take only `with variable = ...`. Only `@actions` can have `set` lines |
| Error at `transition to` under `actions:` | Bare transition where a tool is expected | Under `actions:`, use `@utils.transition to @subagent.x` |
| Error at `@utils.transition to` in `after_reasoning` or a `->` block | Tool form where a statement is expected | Use bare `transition to @subagent.x` |
| Error at a variable default of `...` | `...` used as a default | `...` is for the AI to fill an input. Defaults are literal values, such as `""`, `0`, `False` |
| Mutable variable has no default | Missing `= value` | Every `mutable` variable needs one |
| Error mentioning `model`, `description` or `label` from an action's inputs or outputs | Reserved word used as an Apex `@InvocableVariable` name | Not an issue for these two classes. If you add fields later, don't use those names |

## Publish errors

### "Internal Error, try again later"

The message doesn't say what failed. `validate` can pass and publish still fail. Walk the list in order, and don't stop at the first item.

1. **`default_agent_user` on this employee agent.** Open `config`. If there's a `default_agent_user` line, delete it. Employee agents run as the logged-in user.
2. **An action with no `outputs:` block.** Both `get_account_priorities` and `log_priority_action` must have one. Declaring only some outputs is fine; declaring none is not.
3. **Structural drift.** Compare your file with the reference file in `code/` block by block: block order, a keyword the reference doesn't use, a missing `label` or `description`. If another Agent Script agent already publishes in this org, retrieve its bundle and compare against it too.
4. **A real transient error.** If 1 to 3 are clean, wait 60 seconds and publish once more. If it fails again, stop and deploy the pre-tested version.

### Other publish problems

| Symptom | Cause | Fix |
|---|---|---|
| The invocable action doesn't exist | An Apex class isn't deployed, or has no `@InvocableMethod` | Deploy both classes ([Exercise 2](08-exercise-build-actions.md)) and publish again |
| `Required fields missing: [BundleType]` on deploy | Extra elements in `bundle-meta.xml` | Keep only `<bundleType>AGENT</bundleType>` |
| Publish succeeds but the old behavior is still live | The new version isn't activated | `sf agent activate --json --api-name Priority_Followthrough --target-org <alias>` |
| The change doesn't publish, or the activate fails | The live version is active while you republish | Deactivate, publish, activate ([page 11](11-exercise-publish-and-connect.md#changing-the-agent-after-publishing)) |
| Version numbers keep climbing | Every publish creates a new version, even with no change | Expected. Publish only after the checklist on page 11 |

## Preview errors

| Symptom | Cause | Fix |
|---|---|---|
| `sf agent preview` hangs | You ran the interactive form | Use `preview start`, then `send` and `end`, each with `--json` |
| `send` or `end` rejects `--use-live-actions` | The flag is only for `start` | Remove it from `send` and `end` |
| `--use-live-actions` rejected with `--api-name` | Published agents always run real actions | Leave the flag out when you preview with `--api-name` |
| `--api-name` preview fails with no valid version | Not published, or no version active | Publish and activate. To test the draft, use `--authoring-bundle` |
| `send` fails, or answers from a different session | Wrong or missing session id | Use the `sessionId` from your `start`, plus the same `--authoring-bundle` or `--api-name` |
| Preview doesn't reflect your last edit | The draft in the org is old | Validate, `sf project deploy start --json --metadata AiAuthoringBundle:Priority_Followthrough --target-org <alias>`, start a **new** session |
| Actions return made-up data | Preview without `--use-live-actions` simulates outputs | Start again with `--use-live-actions` |
| "Unable to access Salesforce Agent APIs", or a 503 | The driver lacks Agentforce admin access, or a network hiccup | Check the driver's Agentforce permissions ([2. Org setup](02-org-setup.md)); retry once |
| No trace files | You're looking in the wrong folder | `.sfdx/agents/Priority_Followthrough/sessions/<SESSION_ID>/traces/` under the project root |

## Behavior issues

The full fix loop is on [page 10](10-exercise-preview-and-debug.md#the-fix-loop). Always check the trace, not just the reply.

| Symptom | Cause | Fix |
|---|---|---|
| Seller says "yes" and the agent re-lists priorities or goes off topic | The router isn't routing on `priority_id` and `confirmed`. The AI classified "yes" with no context | `agent_router` must start with the two `if` lines from [page 9](09-exercise-write-agent-script.md#22-the-customer-lead-writes-the-router), before any prompt text |
| Lists accounts that don't exist (for example "Acme Manufacturing"), and the trace has no `FunctionStep` for `get_account_priorities` | The lookup was an AI tool with only optional inputs. The AI skipped it and made up the data | Fetch the data with `run` before the AI answers, as `my_book` does. Check the router sends "what needs attention" to `my_book`. Stronger instructions alone didn't fix it in preview |
| Lists priorities but won't move on | `choose_priority` wasn't called | Check it's in `EnabledToolsStep` and that the ids are in the prompt |
| A record is created before "yes" | `log_priority_action` is a tool, or the `propose_turns` guard is missing | Remove it from every `reasoning: actions:`; restore `available when @variables.propose_turns > 1` |
| Two records from one "yes" | `confirmed` not cleared after the write | `set @variables.confirmed = False` right after the `run` |
| Says "created" but nothing was created | No `FunctionStep` for `log_priority_action` | The turn didn't reach `create_follow_up`. Check `confirmed` in the trace |
| Asks "which account?" on a record page | No record Id reached the agent | Name the account. Page context in the panel is **(to confirm)** |
| A `show_command` tool call or an empty reply | The AI picked a platform tool | Keep the "Do NOT use the show_command tool" line in every subagent |
| Wrong date | `today` blank or stale | Check the `today` variable and the `dueDate` input in the trace |
| "Sorry, something went wrong" | Grounding failed twice, or an action errored | Look for two `UNGROUNDED` steps, or an error in a `FunctionStep` |

## Coworker routing

| Symptom | Cause | Fix |
|---|---|---|
| Coworker answers "Act on Lakeshore's top account priority" itself | Coworker didn't route to the agent. What makes a custom employee agent eligible is **(to confirm)** | Check the agent is active and the seller has `Priority_Agent_Access`. Use the Agentforce panel and log test 10 as open ([page 11](11-exercise-publish-and-connect.md#fallback-open-the-agent-from-the-agentforce-panel)) |
| The agent answers briefs or call logs (tests 8, 9 fail) | Routing too broad | Check the router sends briefs to `off_topic`. Tighten the `config` description to acting on account priorities **(to confirm the description affects Coworker routing)** |

## Permission issues

| Symptom | Cause | Fix |
|---|---|---|
| The seller can't see the agent | `Priority_Agent_Access` not assigned, or the agent isn't active | Assign it; activate; the seller logs out and in |
| Coworker says the agent "doesn't appear in the available agent catalog", even though it's active | Coworker only lists agents the user can access. Seen in rehearsal before `Priority_Agent_Access` was assigned | Assign `Priority_Agent_Access`, reload the page, start a **new** conversation. See [12a](12a-test-in-coworker.md#if-coworker-doesnt-hand-off-at-3a) |
| `Priority_Agent_Access` deploy fails | The agent isn't published yet | Publish first, then deploy it |
| No Agentforce entry point for the seller | No Coworker or Agentforce access | [2. Org setup](02-org-setup.md) |
| Agent visible, but errors when it starts | No published, active version | `./code/validate.sh <alias>`: check the *Agent* section |
| The agent fails as soon as it starts, for every request | The user can't run one of the agent's actions, in any subagent | The seller needs `Priority_Agent_User` (class access to both classes) |
| `SAVE_FAILED` on create | No create on Task or Opportunity, or a validation rule in the org | `Priority_Agent_User` grants both. Read the message for the rule name |

### "It works for me but not for the seller"

This is almost always access. Check, in order:

1. The seller has `Priority_Agent_User` (Apex classes, priority read and status-field edit, Task and Opportunity create)
2. The seller has `Priority_Agent_Access` (agent visibility)
3. The seller owns the DEMO accounts in their book: `./code/validate.sh <alias> <seller-username>` shows 20 or more. Run `./code/deploy.sh <alias> <seller-username>` to set ownership
4. The seller has Coworker access
5. The agent is published and active
6. You're testing as the seller, not as an admin who can see everything

`./code/validate.sh <alias> <seller-username>` checks 1, 2, 3 and 5 in one run, without changing anything.

## Data issues

| Symptom | Cause | Fix |
|---|---|---|
| No open priorities, or fewer than the tests expect | Earlier runs actioned them | `./code/deploy.sh <alias> --top-up`. Names change; counts come back |
| Priority names differ from the test page | A top-up added new ones | Expected. Tests check counts and behavior, plus the fixed Lakeshore rank 1 to 3 values on a fresh seed |
| The Account Brief shows 4 Lakeshore priorities, not 2 | Both demos share the org. The brief lists every Lakeshore priority, including the Actioned one | Expected. Update the sister test, or filter that brief on `Status__c = 'Open'` |
| The Account Brief seed fails with `DELETE_FAILED`, or mentions a Restrict lookup | It deletes every DEMO account first, and `Account_Priority__c.Account__c` blocks deleting an account that has priorities | **Don't re-run the sister seed** after this demo is deployed. Use the top-up. Deploy order is skill demo first, this demo second |
| Seed fails on the price book | The standard price book is inactive | Seed 01 and 03 turn it on. If they can't, activate it in Setup and run again. `validate.sh` checks it |
| Seed 03 hits the CPU limit | Order automation in the org | Set `Integer BATCH = 1;` in `seed-03-orders.apex`, run it, then `BATCH = 2`, run again |
| A seed fails on a validation rule or a required field | Existing org rules on Account, Opportunity, Task or Order | Note the rule. Load into a clean org, or ask the admin about a temporary bypass |
| "SELLER_USERNAME not found or inactive" | Wrong username passed to `deploy.sh` | Use the full username of an active user |
| Seller owns fewer than 20 DEMO accounts | `deploy.sh` ran without the seller | `./code/deploy.sh <alias> <seller-username>` (add-only; reassigns the 20 book accounts) |

## Apex errors

`PriorityActionService` (`Log Priority Action`) returns `isSuccess` false with one of these codes. The agent reports `message` and doesn't retry.

| `errorType` | Message | Meaning | What to do |
|---|---|---|---|
| `INVALID_ACTION_TYPE` | Action type must be Task or Opportunity. | `actionType` wasn't Task, Opportunity or Opp. Blank means Task | Check `action_type` in the trace |
| `INVALID_DATE` | The date must be in YYYY-MM-DD format. | `dueDate` isn't a date | The AI passed "Friday" or similar. Check `today` was set |
| `INVALID_DATE` | The date can't be in the past. | The date is before today | Re-propose with a future date |
| `PRIORITY_NOT_FOUND` | That priority doesn't exist or you don't have access to it. | Bad id, deleted priority, or the user can't see it | Pick again from a fresh list. Check sharing |
| `PRIORITY_NOT_OPEN` | That priority is already Actioned. (or Dismissed) | Someone already acted on it | Working as designed: no duplicate. Pick another or top up |
| `SAVE_FAILED` | The database error text | The insert or update failed, and both were rolled back | Read the text: missing create access, a validation rule, or a required field |

`AccountPriorityService` (`Get Account Priorities`):

| `errorType` | Meaning | What the agent does |
|---|---|---|
| `ACCOUNT_NOT_FOUND` | No account matches, the record Id isn't an Account, Contact or Opportunity, or the user can't see it | Asks the seller to check the name |
| `ACCOUNT_AMBIGUOUS` | More than one account matches the name. `prioritiesJson` holds the candidates with their cities | Lists the candidates and asks which one |
| (none, `priorityCount` 0) | The account has no open priority | Says so and suggests the account brief |

Blank `recordId` and blank `accountName` mean the seller's book. `ACCOUNT_REQUIRED` from the shared error contract never occurs in this class.

---

## Fallback: deploy the pre-tested version

If the live build is stuck, deploy the finished, tested code from `code/`. It adds and updates only; it never deletes.

```bash
cd code
./deploy.sh <alias> <seller-username>
```

It runs, in order:

| Step | What |
|---|---|
| 1 | Checks the org; asks before continuing if it isn't a sandbox or Developer Edition |
| 2 | Deploys `Account_Priority__c` and its 11 fields |
| 3 | Deploys `Priority_Admin` and assigns it to you, the driver |
| 4 | Deploys both Apex classes and runs their tests |
| 5 | Deploys `Priority_Agent_User` and assigns it to the seller |
| 6 | Runs seeds 01 to 04 (add-only) |
| 7 | Validates and deploys the agent bundle as a **draft** |

Then publish, activate and give access from [page 11](11-exercise-publish-and-connect.md).

To replace only the agent file, copy the reference `.agent` into your project ([page 9](09-exercise-write-agent-script.md#fallback-copy-the-reference-file)), validate and deploy the draft.

To check the org at any point without changing anything:

```bash
./validate.sh <alias> <seller-username>
```

---

[Index](README.md) · [← Previous: Test the whole path in Coworker](12a-test-in-coworker.md) · [Next: Production readiness →](14-production-readiness.md)
