[Index](README.md) · [← Previous: Exercise 6: Test as a seller](12-exercise-test.md) · [Next: Troubleshooting →](13-troubleshooting.md)

# 12a. Test the whole path in Coworker

**Time:** 15 minutes  
**Who:** The test seller types in Coworker. The driver checks the data.  
**Output:** One Coworker conversation that goes from *understand* to *decide* to *act*, each step handled by the right thing

[Page 12](12-exercise-test.md) tests the agent on its own. This page tests the story a seller actually lives, in Coworker, in this order:

| Step | The seller wants to… | Handled by | Writes? |
|---|---|---|---|
| 1 | Understand the account | **Account Brief** skill | No |
| 2 | Decide what to do | **Next Best Action** skill | No |
| 3 | Do it | **Priority Follow-Through** agent | Yes, one record, after "yes" |

If each step lands in the right place, the line from [page 4](04-architecture-coworker-first.md) holds in the product: Coworker is the front door, skills read, and the agent acts.

---

## Before you start

| Check | How | If it fails |
|---|---|---|
| The **Account Brief** skill exists, is toggled on, and its Target Agent is Coworker | Coworker > **Skills** | Build it from the [Account Brief demo](https://github.com/squarerootofc/afl-coworker-skills/blob/main/09-exercise-build-skill.md), or skip step 1 |
| The **Next Best Action** skill exists and is toggled on | Coworker > **Skills** | Build it from the [Account Brief demo's guide](https://github.com/squarerootofc/afl-coworker-skills/blob/main/10-next-best-action-skill.md), or run step 2 anyway to see what Coworker does without it |
| The agent is published and **Active** | `./code/validate.sh <alias> <seller-username>`, *Agent* section | [Page 11](11-exercise-publish-and-connect.md) |
| The seller has **`Priority_Agent_Access`** | `validate.sh`, *Test seller* section | Assign it ([page 11, Step 4](11-exercise-publish-and-connect.md#step-4-give-the-seller-access-3-min)) |
| Lakeshore has 3 open priorities | `validate.sh`, *Test accounts* section | `./code/deploy.sh <alias> --top-up` |

> **Coworker only lists agents the user has access to.** Without `Priority_Agent_Access`, Coworker says the agent "doesn't appear in the available agent catalog", even when the agent is active. We saw exactly that in rehearsal. Assign the permission set, then **reload the page and start a new conversation**. A conversation that's already open doesn't pick up the change.

---

## The conversation

Use **one Coworker conversation** for steps 1 to 3, so the seller experiences it as one flow.

### Step 1: Understand (Account Brief skill)

```
Brief me on DEMO Lakeshore Medical Group
```

**Expect:** the brief in its fixed format (company overview, priorities, opportunities, orders, cases, contract details), on the first turn, with no questions first.

**Pass:**
- ✅ The **skill** answers, not the agent: no numbered priority pick, no "Create this?"
- ✅ Nothing is created

> **Known differences when both demos share the org:** the brief's 12-month order total depends on which demo loaded Lakeshore's orders, and the brief may list every account priority on file, including Actioned ones, plus any Tasks and Opportunities the agent already created. That's expected for a read-only brief.

---

### Step 2: Decide (Next Best Action skill)

```
What should I focus on for DEMO Lakeshore Medical Group?
```

**Expect:** a ranked list of recommended actions, each with why it matters and the evidence behind it.

**Pass:**
- ✅ The **Next Best Action** skill answers (if it's built). If it isn't, Coworker answers on its own; note that
- ✅ Nothing is created. This is still read-only

**Talk track:** this is where most assistants stop. The seller has a recommendation, but turning it into a follow-up still means switching screens and typing. The next step closes that gap.

---

### Step 3: Act (the agent)

**3a.** Ask to act, **without** naming the agent:

```
Act on Lakeshore's top account priority
```

**Expect:** Coworker hands the request to **Priority Follow-Through**. You can tell it's the agent because the reply lists Lakeshore's open account priorities as numbered lines, each with a reason, a recommended action and an estimated value.

**3b.** Pick one:

```
The delivery-delay one
```

**Expect:** one proposed follow-up (a Task with a subject and a due date) and the question **"Create this?"**. **Nothing is created yet.**

**3c.** Try to rush it. This should *not* create anything:

```
What would the due date be?
```

**Expect:** it answers the question and asks again. A question isn't a yes.

**3d.** Confirm:

```
yes
```

**Expect:** the agent says the Task was created and the priority is now marked Actioned, then offers another priority.

**Pass:**
- ✅ The **agent** answered 3a to 3d, inside Coworker
- ✅ Nothing was created at 3a, 3b or 3c
- ✅ Exactly **one** Task after 3d. Check it:

  ```bash
  sf data query --target-org <alias> -q "SELECT Name, Status__c, Action_Record_Id__c FROM Account_Priority__c WHERE Account__r.Name = 'DEMO Lakeshore Medical Group' AND Actioned_On__c = TODAY"
  ```

  The priority you picked shows `Actioned` with an `Action_Record_Id__c`. That Id is the new Task.

---

### Step 4 (optional): The seller's whole book

New conversation:

```
Which of my accounts need attention this week?
```

**Expect:** up to 10 open priorities across the seller's own accounts, highest score first, each starting with a real DEMO account name. Then pick one (`number 2`) and stop at "Create this?" without confirming.

**Pass:**
- ✅ Every account in the list is a real DEMO account the seller owns. **No made-up names.** If you see names like "Acme Manufacturing", the agent answered without looking the data up; see [page 10's fix loop](10-exercise-preview-and-debug.md#the-fix-loop)

---

## If Coworker doesn't hand off at 3a

Work down this list. Start a **new** conversation after each fix.

| What you see | Likely cause | What to do |
|---|---|---|
| "The agent doesn't appear in the available agent catalog" | The user doesn't have `Priority_Agent_Access`, or the agent isn't active | Assign the permission set, check the *Agent* section of `validate.sh`, reload, new conversation |
| Coworker answers itself: searches Lakeshore, offers to create a Task | Coworker didn't choose the agent for that wording | Retry with the agent's name (below). If that works, routing by name works but routing by intent doesn't; log it for the account team |
| Still not listed after the permission set and a reload | Session hasn't picked up the access | Log out and back in |
| Named and still not found | What makes a custom employee agent eligible for Coworker routing is **(to confirm)** in this release | Use the Agentforce panel ([page 11 fallback](11-exercise-publish-and-connect.md#fallback-open-the-agent-from-the-agentforce-panel)) and log it as an open item |

**Retry by name:**

```
Use the Priority Follow-Through agent to act on DEMO Lakeshore Medical Group's top priority
```

---

## Results

| Step | Prompt | Expected handler | Pass | Notes |
|---|---|---|---|---|
| 1 | Brief me on DEMO Lakeshore Medical Group | Account Brief skill | ☐ | No write |
| 2 | What should I focus on for DEMO Lakeshore Medical Group? | Next Best Action skill | ☐ | No write. Skill built? ☐ |
| 3a | Act on Lakeshore's top account priority | **Agent**, routed by Coworker | ☐ | Routed by intent ☐ / by name only ☐ / panel only ☐ |
| 3b–3c | The delivery-delay one / What would the due date be? | Agent | ☐ | Nothing created |
| 3d | yes | Agent | ☐ | One Task; priority Actioned and linked |
| 4 | Which of my accounts need attention this week? | Agent | ☐ | Real accounts only |

---

## After the test

Step 3d used up one Lakeshore priority. Put the count back before the next run:

```bash
./code/deploy.sh <alias> --top-up
```

This adds a new Open priority. It doesn't undo the Task, which stays as follow-through history.

---

## What you have now

- One Coworker conversation that shows the whole seller journey: brief (skill), recommendation (skill), action (agent)
- Proof that the two skills only read and the agent only writes after "yes"
- A clear answer on Coworker routing in this org: by intent, by name, or panel only

**Next:** [13. Troubleshooting](13-troubleshooting.md)

---

[Index](README.md) · [← Previous: Exercise 6: Test as a seller](12-exercise-test.md) · [Next: Troubleshooting →](13-troubleshooting.md)
