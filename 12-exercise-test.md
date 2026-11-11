[Index](README.md) · [← Previous: Exercise 5: Publish and connect](11-exercise-publish-and-connect.md) · [Next: Test the whole path in Coworker →](12a-test-in-coworker.md)

# 12. Exercise 6: Test as a seller

**Time:** 30 to 40 minutes  
**Who:** The test seller types. The driver checks traces and data.  
**Output:** 13 tests run, results recorded in the summary table

Run every test **as the test seller**, not as an admin. Admin tests miss sharing and permission problems, and "my book" only means something for the seller.

---

## Setup

1. **Top up first.** In the driver's terminal:
   ```bash
   ./code/deploy.sh <alias> --top-up
   ./code/validate.sh <alias> <seller-username>
   ```
   Under *Test accounts (exact)*, all five rows show OK: Lakeshore 3, Pinecrest 1, Harbor Seattle 1, Harbor Tacoma 1, Ridgeway 0. Under *Test seller*, the seller owns at least 20 DEMO accounts and has both permission sets.
2. **Log in as the test seller:** Setup > Users > **Login** next to the user.
3. **Open the Sales app and Coworker.** If Coworker didn't route to the agent on [page 11](11-exercise-publish-and-connect.md#step-5-the-seller-asks-coworker-3-min), run tests 1 to 7 and 11 to 13 from the Agentforce panel instead.
4. **Start a new conversation for each test**, unless the test says otherwise.
5. **Check the Account org-wide default** (Setup > Sharing Settings). Test 13 runs only if Account is Private.

### How to check the trace

The seller's chat doesn't show a trace. You already proved the gate in traces on [page 10](10-exercise-preview-and-debug.md#step-4-read-the-trace-10-min), so on this page **check the data** after each test.

For a pass criterion marked **Trace**, the driver can repeat the same conversation in a CLI preview of the published agent and read the trace as on page 10:

```bash
sf agent preview start --json --api-name Priority_Followthrough --target-org <alias>
```

- The CLI preview runs as the driver and **writes real data** on every "yes". Replay write tests on an account the driver owns, for example DEMO Beacon Hill Orthopedics, so the seller's test priorities aren't used up. Tests that don't write (4, 5) can be replayed as they are.
- "My book" (tests 11 and 12) and test 13 depend on who is asking, so a driver replay doesn't show the seller's result. Check the data for those.
- Traces of the seller's own conversations may be available through Agentforce session tracing, if it's turned on in this org **(to confirm)**.

> **The data changes as you test.** Each "yes" turns an Open priority into Actioned. Run the tests in order. After a top-up, the new priorities have **different names and reasons**, but each test account gets back to the same **count**.

### The test data

| Account | Open priorities (rank: reason / recommended action / estimated value) | Other |
|---|---|---|
| DEMO Lakeshore Medical Group (Chicago) | 1: Declining furniture spend at 3 sites / Offer site-level furniture review / $36,000<br>2: Print volume flat / Propose managed print review / $8,600<br>3: Open delivery-delay case before renewal / Resolve the case, then book the renewal review / $120,000 | 1 Actioned: "Buys furniture and print but not office supplies". Must never appear |
| DEMO Pinecrest School District (Portland) | 1: Only one contact on file / Identify a second decision maker in facilities / $0 | New account, little else on file |
| DEMO Harbor Supply Co (Seattle) | 1: No order in 104 days / Check-in call to confirm the next order / $5,400 | Same name as Tacoma |
| DEMO Harbor Supply Co (Tacoma) | 1: New warehouse opening next quarter / Propose a warehouse supplies starter kit / $9,500 | Same name as Seattle |
| DEMO Ridgeway Logistics (Dallas) | None | |

**"My book"** returns up to 10 open priorities, highest `Propensity_Score__c` first, only on accounts the seller owns.

---

## Test 1: Act on the top priority (Lakeshore)

**Where:** Coworker  
**Prompts, in one conversation:**
```
Act on the top account priority for DEMO Lakeshore Medical Group
```
```
Number 1
```
```
Yes
```

**Expected:**
- First reply lists the 3 open priorities in rank order with the exact reasons, actions and values above. The Actioned "office supplies" priority isn't listed. If the agent goes straight to a proposal for rank 1 instead, that's fine ("top" is clear): skip "Number 1" and answer "Yes".
- After the pick: one proposed Task, subject based on "Offer site-level furniture review", due 7 days from today, ending with "Create this?". **Nothing created yet.**
- After "Yes": the reply names the Task, says it was created on DEMO Lakeshore Medical Group, and says the priority is now Actioned.

**Check the data (driver):**
```bash
sf data query --target-org <alias> -q "SELECT Name, Priority_Rank__c, Status__c, Actioned_On__c, Action_Record_Id__c FROM Account_Priority__c WHERE Account__r.Name = 'DEMO Lakeshore Medical Group' ORDER BY Priority_Rank__c"
sf data query --target-org <alias> -q "SELECT Subject, ActivityDate, What.Name, Owner.Name, Description FROM Task WHERE Id = '<Action_Record_Id__c>'"
```

**Pass criteria:**
- ✅ 3 priorities listed, none Actioned
- ✅ No record before "Yes" (**Trace:** no `FunctionStep` for `log_priority_action` until the "Yes" turn)
- ✅ The rank 1 priority (Lakeshore Priority 1) is Actioned, `Actioned_On__c` is today, `Action_Record_Id__c` is the Task
- ✅ The Task is on Lakeshore, owned by the seller, due today + 7, Description starts "From account priority Lakeshore Priority 1"

---

## Test 2: Make it an Opportunity (Lakeshore, Managed Print)

**Where:** Coworker, new conversation  
**Prompts:**
```
Show me the open account priorities on DEMO Lakeshore Medical Group
```
```
The print volume one
```
```
Make it an opportunity
```
```
Yes
```

**Expected:**
- 2 priorities listed (furniture is gone after test 1)
- First proposal is a Task. After "Make it an opportunity": an Opportunity with a name, a close date 30 days out and an amount of **$8,600**
- After "Yes": the Opportunity is created and the priority is Actioned

**Check the data:**
```bash
sf data query --target-org <alias> -q "SELECT Status__c, Action_Record_Id__c FROM Account_Priority__c WHERE Account__r.Name = 'DEMO Lakeshore Medical Group' AND Priority_Rank__c = 2"
sf data query --target-org <alias> -q "SELECT Name, StageName, Amount, CloseDate, Account.Name, Description FROM Opportunity WHERE Id = '<Action_Record_Id__c>'"
```

**Pass criteria:**
- ✅ Amount = 8,600, from `Estimated_Value__c`
- ✅ Stage is the org's first open stage (Prospecting in a standard org; the Apex reads it from the org rather than hard-coding it)
- ✅ Close date = today + 30
- ✅ Priority 2 is Actioned and linked to the Opportunity

---

## Test 3: Don't act twice (Lakeshore, no top-up)

**Where:** Coworker. Part A continues the test 1 conversation; part B is a new one.

**Part A prompts** (in the test 1 conversation):
```
Act on the furniture review one again
```
If the agent proposes it, answer:
```
Yes
```

**Part B prompt** (new conversation):
```
Act on the top account priority for DEMO Lakeshore Medical Group
```

**Expected:**
- Part A: no new Task. Either the agent says that priority is no longer open, or it tries and reports "the follow-up was not created: That priority is already Actioned."
- Part B: only open priorities are listed. Neither furniture nor print appears.

**Check the data:** exactly one Task created by the seller on Lakeshore today:
```bash
sf data query --target-org <alias> -q "SELECT Id, Subject FROM Task WHERE What.Name = 'DEMO Lakeshore Medical Group' AND CreatedBy.Username = '<seller-username>' AND CreatedDate = TODAY"
```

**Pass criteria:**
- ✅ One Task, not two
- ✅ **Trace** (part A): if `log_priority_action` ran, its output is `isSuccess` false, `errorType` `PRIORITY_NOT_OPEN`. That's Apex refusing the duplicate, the last line of defense
- ✅ Part B lists no Actioned priority

---

## Test 4: Two accounts, one name (Harbor Supply)

**Where:** Coworker, new conversation  
**Prompts:**
```
Follow up on DEMO Harbor Supply Co's priorities
```
```
The Seattle one
```

**Expected:**
- First reply: two candidates, DEMO Harbor Supply Co in Seattle and in Tacoma, and a question asking which one. No priorities yet.
- After "The Seattle one": only Seattle's priority: "No order in 104 days" / "Check-in call to confirm the next order" / $5,400. Tacoma's warehouse priority does not appear.
- If the agent proposes a follow-up, don't confirm it.

**Pass criteria:**
- ✅ Asks which account before showing any priority
- ✅ Shows only the chosen account's priority
- ✅ No write (**Trace:** the first `get_account_priorities` output is `ACCOUNT_AMBIGUOUS`; the second lookup resolves one account; no `log_priority_action`)

---

## Test 5: No priorities (Ridgeway)

**Where:** Coworker, new conversation  
**Prompt:**
```
Act on DEMO Ridgeway Logistics' top priority
```

**Expected:** "There is no open account priority on file", and a suggestion to ask Coworker for an account brief. No proposal.

**Pass criteria:**
- ✅ Says no open priority, doesn't invent one
- ✅ Suggests the account brief
- ✅ No write (**Trace:** `priorityCount` 0)

---

## Test 6: Edit before confirming (Lakeshore, Service Risk)

**Where:** Coworker, new conversation  
**Prompts:**
```
Show me the open account priorities on DEMO Lakeshore Medical Group
```
```
The delivery-delay case one
```
```
Change the due date to Friday
```
```
Yes
```

**Expected:**
- The proposal is a Task for "Resolve the case, then book the renewal review", due 7 days out
- After "Change the due date to Friday": a new proposal with Friday's date as YYYY-MM-DD (run on a Thursday, that's the next day), and "Create this?" again. **Nothing created.**
- After "Yes": the Task is created, due Friday

**Pass criteria:**
- ✅ The edit turn creates nothing (**Trace:** no `log_priority_action` on that turn)
- ✅ The Task's `ActivityDate` is Friday
- ✅ Lakeshore Priority 3 is Actioned

---

## Test 7: A new account (Pinecrest)

**Where:** Coworker, new conversation  
**Prompts:**
```
What's the account priority for DEMO Pinecrest School District? Act on it.
```
```
Yes
```

**Expected:**
- One priority: "Only one contact on file" / "Identify a second decision maker in facilities" / $0 estimated value
- A proposed Task, then "Create this?". The first reply never creates anything, even though the message said "act on it".
- After "Yes": the Task is created on DEMO Pinecrest School District. If the agent first asks you to confirm the pick, say yes; it then proposes, and only the second "yes" creates the Task.

**Pass criteria:**
- ✅ Works on an account with little else on file
- ✅ Nothing created on the first turn (**Trace:** `confirm_follow_up` isn't enabled while `propose_turns` is 1)
- ✅ Pinecrest Priority 1 is Actioned and linked to the Task

---

## Test 8: A brief stays with Coworker

**Where:** Coworker, new conversation  
**Prompt:**
```
Brief me on DEMO Lakeshore Medical Group
```

**Expected:**
- If the Account Brief demo is in this org: the **Account Brief** skill runs
- If not: Coworker answers with its built-in search and summary
- Either way, **the priority agent doesn't answer**: no numbered priority list from it, no "Create this?"

> If the Account Brief demo shares this org, its brief lists every Lakeshore priority, including Actioned ones, and includes the Tasks and Opportunities you just created. That's expected.

**Pass criteria:**
- ✅ The skill or Coworker answers, not the agent
- ✅ No account priority changes status

---

## Test 9: One record write stays with Coworker

**Where:** Coworker, new conversation  
**Prompt:**
```
Log a call with Lakeshore for today
```

**Expected:** Coworker proposes the call log itself, for the seller to review. The agent doesn't answer. If Coworker says it can't create records, record create and update access isn't on for this user in Coworker **(to confirm the setting name in this release)**.

**Pass criteria:**
- ✅ Coworker handles it, not the agent
- ✅ No account priority changes status

---

## Test 10: Coworker routes to the agent

**Where:** Coworker, new conversation  
**Prompt:**
```
Act on DEMO Lakeshore Medical Group's top account priority
```

**Expected:** the Priority Follow-Through agent answers. Don't confirm anything. This test is only about routing. If tests 1, 2 and 6 used up all three Lakeshore priorities, "no open account priority on file" also passes: that reply comes from the agent.

**Pass criteria:**
- ✅ The agent answers inside Coworker
- If Coworker answers itself instead, record test 10 as **open: Coworker routing** for the account team, and confirm the agent works from the Agentforce panel ([page 11](11-exercise-publish-and-connect.md#fallback-open-the-agent-from-the-agentforce-panel))

---

## Test 11: My book

**Where:** Coworker, new conversation  
**Prompt:**
```
Which of my accounts need attention this week?
```

**Expected:** up to 10 open priorities, highest propensity score first. Each line starts with the account name, then the reason, recommended action and estimated value. No proposal and no write.

Get the exact expected list (driver):
```bash
sf data query --target-org <alias> -q "SELECT Account__r.Name, Priority_Reason__c, Estimated_Value__c, Propensity_Score__c FROM Account_Priority__c WHERE Account__r.Owner.Username = '<seller-username>' AND Status__c = 'Open' ORDER BY Propensity_Score__c DESC NULLS LAST, Priority_Rank__c ASC NULLS LAST LIMIT 10"
```

On a fresh seed, unless someone has acted on it, the first line is DEMO Kessler Tool & Die: "Open high-priority case 34 days before renewal", $180,000 (score 89). This line was seen in a live preview in the build org, not just worked out from the data. The agent listed 10 real priorities with it first. That preview ran as the driver, who owned every account at the time. Kessler is one of the seller's 20 accounts, so it comes first in the seller's book too.

**Pass criteria:**
- ✅ The agent's list has the same 10 priorities, in the same order, as the query
- ✅ Every account on the list is owned by the seller. None of the driver's 30 accounts appear
- ✅ No made-up accounts. Every name on the list is in the query result
- ✅ No write
- ✅ **Trace:** path `agent_router` → `my_book`, and one `FunctionStep` for `get_account_priorities` in `my_book`, before the AI answers

---

## Test 12: Act from the book

**Where:** Continue the test 11 conversation  
**Prompts:**
```
Let's do number 2
```
```
Yes
```

**Expected:** a proposal for item 2 from the test 11 list, then a Task created on **that item's account**, and that priority Actioned. The path goes from `my_book` (test 11) to `propose_follow_up` ("Let's do number 2") to `create_follow_up` ("Yes"). On the pick, the router passes the short reply to `select_priority`, which records it from the list and moves straight on to `propose_follow_up`.

**Check the data:**
```bash
sf data query --target-org <alias> -q "SELECT Name, Account__r.Name, Status__c, Action_Record_Id__c FROM Account_Priority__c WHERE Status__c = 'Actioned' AND Actioned_On__c = TODAY AND Account__r.Owner.Username = '<seller-username>'"
sf data query --target-org <alias> -q "SELECT Subject, What.Name FROM Task WHERE Id = '<Action_Record_Id__c>'"
```

**Pass criteria:**
- ✅ The Task's `WhatId` is the account from item 2, not Lakeshore or any other account
- ✅ That priority is Actioned and linked to the Task
- ✅ No record before "Yes"

---

## Test 13: Someone else's account (only if Account is Private)

**Where:** Coworker, new conversation  
**Run only if** the Account org-wide default is Private.  
**Prompt** (DEMO Magnolia Health System is owned by the driver):
```
Act on the top priority for DEMO Magnolia Health System
```

**Expected:** the agent can't find the account and asks the seller to check the name. No priorities are shown. No write.

**Pass criteria:**
- ✅ Not found (**Trace** can't help here, because the CLI preview runs as the driver, who can see the account. Check the reply and the data)
- ✅ Magnolia's priorities are still Open:
  ```bash
  sf data query --target-org <alias> -q "SELECT Name, Status__c FROM Account_Priority__c WHERE Account__r.Name = 'DEMO Magnolia Health System'"
  ```

---

## Test summary table

| # | Test | Pass | Notes |
|---|---|---|---|
| 1 | Lakeshore top priority → Task after "yes" | ☐ | No write before "yes"; Priority 1 Actioned and linked |
| 2 | Lakeshore Managed Print → Opportunity | ☐ | Amount $8,600, first open stage, close today + 30 |
| 3 | No duplicate | ☐ | One Task; Apex `PRIORITY_NOT_OPEN` if it tried |
| 4 | Harbor Supply, two accounts | ☐ | Asks which; then only that account's priority |
| 5 | Ridgeway, no priorities | ☐ | "No open account priority on file", suggests the brief |
| 6 | Edit to Friday before "yes" | ☐ | Re-proposes; Task due on Friday |
| 7 | Pinecrest, new account | ☐ | One priority; nothing created on the first turn |
| 8 | Brief stays with Coworker | ☐ | Skill or Coworker, not the agent |
| 9 | Call log stays with Coworker | ☐ | Coworker native |
| 10 | Coworker routes to the agent | ☐ | Or logged as an open item |
| 11 | My book | ☐ | Matches the query; seller's accounts only; no made-up accounts |
| 12 | Act from the book | ☐ | `my_book` → `propose_follow_up` → `create_follow_up`; Task on the right account |
| 13 | Someone else's account (Private only) | ☐ | Not found; no write |

Tests 8 to 10 show the line between Coworker, a skill and the agent, inside the product. Tests 11 to 13 show the agent works on a real-sized book and respects ownership.

---

## If a test fails

| Symptom | First check |
|---|---|
| The agent doesn't answer in Coworker | Test 10 routing; use the Agentforce panel and continue |
| "Sorry, something went wrong", or an empty list for the seller but not the driver | The seller is missing `Priority_Agent_User`, or doesn't own the accounts. Run `./code/validate.sh <alias> <seller-username>` |
| A record created before "yes" | Stop testing. Check the trace and [page 10's fix loop](10-exercise-preview-and-debug.md#the-fix-loop) |
| The seller says "yes" and the agent lists priorities again | The router isn't routing on state. See [page 10's fix loop](10-exercise-preview-and-debug.md#the-fix-loop) |
| Fewer priorities than expected | Run the top-up |

Everything else: [13. Troubleshooting](13-troubleshooting.md).

---

## Optional: Testing Center

The same tests can run as a repeatable suite in the Agentforce Testing Center, as a gate before each release.

```bash
sf agent test create --json --spec specs/Priority_Followthrough-testSpec.yaml --api-name Priority_Followthrough_Tests --force-overwrite --target-org <alias>
sf agent test run --json --api-name Priority_Followthrough_Tests --wait 5 --target-org <alias>
```

- The spec would live at `code/specs/Priority_Followthrough-testSpec.yaml`. **It isn't written yet. That's a follow-up** ([15. Next steps](15-next-steps.md)).
- Keep `specs/` at the project root, outside `force-app/`. Test definitions under `force-app/` slow down deploys.
- Tests run only against an **activated** agent.
- They use live actions, so a run that confirms a follow-up writes real records. Top up afterwards.
- Which user the tests run as, and so what "my book" returns, is **(to confirm)**.

---

## What you have now

- 13 seller tests run against the real agent and the 50-account book
- Data checks that prove each write: the record, its account and the linked priority
- The line between Coworker, skill and agent shown in the product (tests 8 to 10)

**Next:** [12a. Test the whole path in Coworker](12a-test-in-coworker.md)

---

[Index](README.md) · [← Previous: Exercise 5: Publish and connect](11-exercise-publish-and-connect.md) · [Next: Test the whole path in Coworker →](12a-test-in-coworker.md)
