[Index](README.md) · [← Previous: Exercise 3: Write the Agent Script](09-exercise-write-agent-script.md) · [Next: Exercise 5: Publish and connect →](11-exercise-publish-and-connect.md)

# 10. Exercise 4: Preview and debug

**Time:** 30 minutes  
**Tool:** Salesforce CLI in the VS Code terminal  
**Output:** A live preview of every branch, and traces that show the write happens only after "yes"

Preview runs the agent before it's published. With `--use-live-actions`, the two Apex actions really run, so the agent creates real Tasks and Opportunities and marks real priorities Actioned.

> **Never trust the text reply alone.** The AI can say "Done, I created the Task" when no action ran. The trace shows what actually happened. Read it on every turn that matters.

---

## Before you start

- [ ] `sf agent validate authoring-bundle --json --api-name Priority_Followthrough --target-org <alias>` shows `"success": true`
- [ ] Lakeshore has 3 open priorities: `./code/validate.sh <alias>` shows OK for *DEMO Lakeshore Medical Group (Chicago) open priorities*. If not, top up: `./code/deploy.sh <alias> --top-up`
- [ ] `jq` is installed (optional, for the trace checks)

> **Live preview writes real data.** Every "yes" uses up one open priority. Top up when you finish this page, before [Exercise 6](12-exercise-test.md).

> **Who the actions run as:** this is an employee agent with no agent user, so in preview live actions run as the user the CLI is logged in as: the driver. That matters for "my book": in preview it returns priorities on accounts the **driver** owns. The seller's book is tested on [page 12](12-exercise-test.md).

---

## Step 1: Deploy the draft (2 min)

Deploy again after every change to the file, so the draft in the org matches your project:

```bash
sf project deploy start --json --metadata AiAuthoringBundle:Priority_Followthrough --target-org <alias>
```

The agent stays a draft. Sellers can't see it.

---

## Step 2: Start a live preview (1 min)

```bash
sf agent preview start --json --use-live-actions --authoring-bundle Priority_Followthrough --target-org <alias>
```

Copy the `sessionId` from the JSON. Every `send` and `end` needs it.

**Rules:**
- `--use-live-actions` goes on `start` only. `send` and `end` reject it.
- Use `start`, `send` and `end`. A bare `sf agent preview` opens an interactive session you can't script.
- Preview can't pass page context. The agent has no record page here, so always name the account.

---

## Step 3: Run the scripted conversation (10 min)

Send these one at a time, in the same session. Read each reply before you send the next.

**Turn 1: list**
```bash
sf agent preview send --json --authoring-bundle Priority_Followthrough --session-id <ID> -u "What account priorities are open on DEMO Lakeshore Medical Group?" --target-org <alias>
```
Expected: three numbered priorities, in rank order, with the exact values:

| # | Reason | Recommended action | Estimated value |
|---|---|---|---|
| 1 | Declining furniture spend at 3 sites | Offer site-level furniture review | $36,000 |
| 2 | Print volume flat | Propose managed print review | $8,600 |
| 3 | Open delivery-delay case before renewal | Resolve the case, then book the renewal review | $120,000 |

The Actioned priority ("Buys furniture and print but not office supplies") must not appear.

**Turn 2: pick one**
```bash
sf agent preview send --json --authoring-bundle Priority_Followthrough --session-id <ID> -u "Let's act on number 1" --target-org <alias>
```
Expected: one proposed Task (a subject based on "Offer site-level furniture review", due 7 days from today), ending with "Create this?". **Nothing is created yet.**

**Turn 3: confirm**
```bash
sf agent preview send --json --authoring-bundle Priority_Followthrough --session-id <ID> -u "Yes, create it" --target-org <alias>
```
Expected: the Task is created on DEMO Lakeshore Medical Group, the reply names it, says the priority is now Actioned, and asks about another priority.

**End the session** when you're done with it. The response gives the path to the trace files.
```bash
sf agent preview end --json --authoring-bundle Priority_Followthrough --session-id <ID> --target-org <alias>
```

---

## Step 4: Read the trace (10 min)

### Where the files are

From the project root:

```
.sfdx/agents/Priority_Followthrough/sessions/<SESSION_ID>/
├── metadata.json        ← session info; mockMode should be "Live Test"
├── transcript.jsonl     ← one line per message, seller and agent
└── traces/
    └── <PLAN_ID>.json   ← one file per turn
```

Traces are written after each `send`. You don't need to end the session to read them. To find the file for a turn, open `transcript.jsonl`, find the agent's reply, and read `planId` from its `raw` array. That `planId` is the trace file name.

### Steps to look for

Each trace file has a `plan` array: one entry per step, with its `type`.

| Step | What it tells you |
|---|---|
| `NodeEntryStateStep` | Which subagent is running (`data.agent_name`), and the variable values |
| `TransitionStep` | A move from one subagent to another |
| `EnabledToolsStep` | The tools the AI could call on this pass (`data.enabled_tools`) |
| `LLMStep` | Which subagent called the AI (`data.agent_name`), what it saw (`data.prompt_content`) and what it chose (`data.prompt_response`) |
| `FunctionStep` | An action ran: its inputs and outputs |
| `VariableUpdateStep` | A variable changed: `data.variable_updates[].variable_name` and `variable_new_value` |
| `ReasoningStep` | Grounding check: `GROUNDED` or `UNGROUNDED` |
| `PlannerResponseStep` | What the seller received |

### What each turn should show

Every turn starts at `agent_router`. That is how Agent Script works: each seller message begins at the `start_agent` block.

| Turn | Path | Must see | Must **not** see |
|---|---|---|---|
| 1. List | `agent_router` → `select_priority` | The router has no priority chosen, so the AI picks `to_select_priority`. `FunctionStep` for `get_account_priorities` with `accountName` set to the Lakeshore name; output `isSuccess` true, `priorityCount` 3. `VariableUpdateStep` for `priorities_json` and `today` | Any `FunctionStep` for `log_priority_action` |
| 2. Pick | `agent_router` → `select_priority` → `propose_follow_up` | The AI calls `choose_priority`; `priority_id` is set. `after_reasoning` moves to `propose_follow_up`. `propose_turns` is 1 | `confirm_follow_up` in `EnabledToolsStep` (it is hidden on the first proposal turn). Any `FunctionStep` for `log_priority_action` |
| 3. Yes | `agent_router` → `propose_follow_up` → `create_follow_up` | The router moves straight to `propose_follow_up` because `priority_id` is set; no AI choice. `propose_turns` is 2, so `confirm_follow_up` is enabled and the AI calls it. `confirmed` becomes True. `after_reasoning` moves to `create_follow_up`. **Then one `FunctionStep` for `log_priority_action`**, with inputs from the variables and output `isSuccess` true. Then `confirmed` back to False and `priority_id` to "" | A second `FunctionStep` for `log_priority_action` |

On **every** turn, `log_priority_action` never appears in `EnabledToolsStep`. It isn't a tool; only the gate runs it.

If the create shows up on the seller's **next** message instead (`agent_router` → `create_follow_up`, because `confirmed` was still True), the router's safety net caught it. The write still came after the "yes". Note it and check that the "yes" turn moved on through `after_reasoning`.

### Quick checks with jq

Set `TRACE` to a trace file, then:

```bash
# Which subagents ran on this turn?
jq '[.plan[] | select(.type == "NodeEntryStateStep") | .data.agent_name]' "$TRACE"

# Which actions ran?
jq '[.plan[] | select(.type == "FunctionStep") | .function.name]' "$TRACE"

# Which tools could the AI call?
jq '[.plan[] | select(.type == "EnabledToolsStep") | .data.enabled_tools]' "$TRACE"

# Which variables changed, and to what?
jq '[.plan[] | select(.type == "VariableUpdateStep") | .data.variable_updates[] | {variable_name, variable_new_value}]' "$TRACE"

# Did every response pass grounding?
jq '[.plan[] | select(.type == "ReasoningStep") | .data.groundingAssessment]' "$TRACE"
```

The steps are in the `plan` array. If a command returns nothing, open the file and search for the step name, for example `FunctionStep`.

### Check the data too

The trace shows the action ran. The org shows it worked. As the driver:

```bash
sf data query --target-org <alias> -q "SELECT Name, Status__c, Actioned_On__c, Action_Record_Id__c FROM Account_Priority__c WHERE Account__r.Name = 'DEMO Lakeshore Medical Group' ORDER BY Priority_Rank__c"
```

Expected: Lakeshore Priority 1 is Actioned, dated today, with an `Action_Record_Id__c`. Look up that record:

```bash
sf data query --target-org <alias> -q "SELECT Id, Subject, ActivityDate, What.Name, Description FROM Task WHERE Id = '<Action_Record_Id__c>'"
```

Expected: the Task is on DEMO Lakeshore Medical Group, and its Description starts with "From account priority Lakeshore Priority 1". (Description is a long text field, so you can't filter on it in a query. Look records up by Id.)

---

## Step 5: Cover every branch (as time allows)

Start a new session for each line, or keep one session and pick another account. Check the trace for each. Each "yes" uses up a priority: if Lakeshore runs out, top up (`./code/deploy.sh <alias> --top-up`) or use another account you own.

| Branch | Message to send | Expected | Trace check |
|---|---|---|---|
| Edit before yes | Pick Lakeshore "Open delivery-delay case before renewal", then "Change the due date to Friday" | Re-proposes with Friday as YYYY-MM-DD. No write | No `log_priority_action` until a later "yes" |
| Opportunity | Pick Lakeshore "Print volume flat", then "Make it an opportunity", then "yes" | Opportunity proposed with amount $8,600 and a close date 30 days out | `log_priority_action` input `actionType` is `Opportunity` |
| "Yes" too early | New session: "Act on DEMO Lakeshore Medical Group's top priority and create the task, yes" | Lists or proposes, but creates nothing | No `confirm_follow_up` while `propose_turns` is 1; no `log_priority_action` |
| "Yes" again | Right after a create: "Create it again" | No second record | No second `log_priority_action` |
| Two accounts, one name | "Follow up on DEMO Harbor Supply Co's priorities" | Lists Seattle and Tacoma, asks which | `get_account_priorities` output `errorType` `ACCOUNT_AMBIGUOUS` |
| No priorities | "Act on DEMO Ridgeway Logistics' top priority" | "No open account priority on file", suggests a Coworker account brief | `priorityCount` 0; no write |
| Not found | "Act on DEMO Nowhere Industries" | Says it can't find the account | `errorType` `ACCOUNT_NOT_FOUND` |
| Off topic | "Brief me on DEMO Lakeshore Medical Group" | Says it acts on account priorities and sends briefs to Coworker | Transition to `off_topic`; no `FunctionStep` |
| My book | "Which of my accounts need attention this week?" | Up to 10 priorities, highest score first, each with its account name. Only the driver's accounts | Path `agent_router` → `my_book`. One `FunctionStep` for `get_account_priorities` in `my_book`, inputs both `""`, output `scope` `BOOK`. It comes before the `LLMStep` in `my_book` |
| Pick from the book | Right after "My book": "number 2" | A proposal for the 2nd item on the list | Path `agent_router` → `select_priority` → `propose_follow_up`. `priority_id` and `account_name` set to the 2nd item |

---

## The fix loop

1. Find the turn that went wrong in `transcript.jsonl`.
2. Open its trace. Find where it differs from the table in Step 4.
3. Change the `.agent` file.
4. Validate, deploy the draft, start a **new** preview session, and send the same messages.
5. Compare the new trace with the old one. A different error usually means progress.

| What you see | Likely cause | Fix |
|---|---|---|
| Seller says "yes" and the agent re-lists priorities or goes off topic | The router isn't routing on state. The AI classified "yes" without context | `agent_router` must start with `if @variables.confirmed == True:` and `if @variables.priority_id != "":` before any `\|` text. Check `NodeEntryStateStep`: if `priority_id` is blank on the "yes" turn, something cleared it (only `select_priority`, `my_book` and the gate should) |
| The agent lists accounts that don't exist, and there's no `FunctionStep` for `get_account_priorities` | The lookup was an optional AI tool, and the AI skipped it and made up the data. In preview this happened in book mode, with "Acme Manufacturing" and "Beta Logistics" | Fetch it with `run` before the AI answers, as `my_book` does. Stronger instructions alone didn't fix it here. Check the router sends "what needs attention" to `my_book` (`to_my_book`) |
| Lists priorities but won't move on after the seller picks one | `choose_priority` wasn't called | In `LLMStep`, see what the AI did instead. Check `choose_priority` is in `EnabledToolsStep`, and that `priorities_json` appears in the prompt so the AI has the ids. Have the seller pick by number |
| A record is created before the seller says yes | The write is exposed as a tool, or the first-turn guard is missing | `log_priority_action` must not be under any `reasoning: actions:`. `confirm_follow_up` needs `available when @variables.propose_turns > 1` |
| The reply says "created" but there's no `FunctionStep` for `log_priority_action` | The AI described a write that didn't happen | Check `confirmed` became True and the turn reached `create_follow_up`. Query the org; no record means no write |
| Two records from one "yes" | `confirmed` isn't cleared after the `run` | The gate must end with `set @variables.confirmed = False` |
| Asks "which account?" on a record page | No record Id reached the agent. Preview never has page context; in Lightning, whether the panel passes the record is **(to confirm)** | Name the account. If it's needed on record pages, raise it as a design point |
| A `show_command` tool call instead of text, or an empty reply after a lookup | The AI chose a platform tool | Each subagent's instructions already say "Do NOT use the show_command tool". Check that line is in the subagent that misbehaved |
| Wrong date, or the create fails with `INVALID_DATE` | `today` is blank or stale, or the date isn't YYYY-MM-DD, or it's in the past | Check `today` was set from the lookup's output (`VariableUpdateStep`). Check the `dueDate` input in the `FunctionStep` |
| Lists the Actioned priority | The Apex filter is wrong, or the priority has no Status | `AccountPriorityService` filters on `Status__c = 'Open'`. Check the record's Status |
| "Sorry, something went wrong" | Grounding failed twice, or an action errored | Look for two `UNGROUNDED` `ReasoningStep`s, or a `FunctionStep` with an error output |
| Figures differ from the record | The AI paraphrased or rounded | Instructions already say "using the exact values returned". Check `ReasoningStep` for the reason |

More in [13. Troubleshooting](13-troubleshooting.md).

---

## When you finish this page

Top up the priorities you used:

```bash
./code/deploy.sh <alias> --top-up
```

The top-up adds new Open priorities, with new names, to any account below its starting count. It never deletes or edits anything.

---

## What you have now

- A live preview of the full flow: list, pick, propose, confirm, create
- Traces showing `log_priority_action` runs once, only on the "yes" turn, and is never offered to the AI as a tool
- The org confirms the write: the Task exists and the priority is Actioned
- Every branch tried, and a fix loop for anything that broke

**Next:** [Exercise 5: Publish and connect](11-exercise-publish-and-connect.md)

---

[Index](README.md) · [← Previous: Exercise 3: Write the Agent Script](09-exercise-write-agent-script.md) · [Next: Exercise 5: Publish and connect →](11-exercise-publish-and-connect.md)
