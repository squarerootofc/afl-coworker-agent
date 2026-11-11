[Index](README.md) · [← Previous: Production readiness](14-production-readiness.md) · [Next: Teardown →](16-teardown.md)

# 15. Next steps

**When:** 3:45, end of the session  
**Who:** The customer lead, the customer's architect, the seller champion, the account team  
**Output:** Owners and dates filled in, pilot metrics agreed, the next build chosen

---

## Owners and dates

Fill in the owners before everyone leaves.

| # | Task | Owner | Due (after the session) | Status |
|---|---|---|---|---|
| 1 | Map the real priority source to each field ([page 14](14-production-readiness.md#data-mapping-seed-fields-to-the-real-priority-source)) | _____ | Week 1 | ☐ |
| 2 | Decide how priority data reaches Salesforce (feed into `Account_Priority__c`, or read from Data Cloud) | _____ | Week 1 | ☐ |
| 3 | Write the Testing Center spec `code/specs/Priority_Followthrough-testSpec.yaml` from the 13 tests | _____ | Week 1 | ☐ |
| 4 | Load real (or realistic) account priorities into the customer's sandbox | _____ | Week 2 | ☐ |
| 5 | Pick 3 to 5 pilot sellers and give them access | _____ | Week 2 | ☐ |
| 6 | Pilot: sellers use the agent on their own book | _____ | Weeks 2 to 3 | ☐ |
| 7 | Confirm Coworker routing to the agent, or agree the Agentforce panel as the front door | _____ | Week 2 | ☐ |
| 8 | Build the follow-through reports ([page 14](14-production-readiness.md#monitoring)) | _____ | Week 3 | ☐ |
| 9 | Pilot review: metrics below, seller feedback, fixes | _____ | Week 4 | ☐ |
| 10 | Harden: sharing model, lookup field for reporting, rollback plan, pipeline | _____ | Week 4 | ☐ |
| 11 | Enable the next group of sellers | _____ | Week 5 | ☐ |
| 12 | Results readout: follow-through and opportunities created | _____ | Within 3 months | ☐ |

---

## Pilot metrics

Measure these from the first day of the pilot. Most come straight from `Account_Priority__c`.

| Metric | How to calculate | Source |
|---|---|---|
| Follow-through rate, per seller | Actioned ÷ (Open + Actioned), for priorities on the seller's accounts | `Status__c`, grouped by account owner |
| Follow-through by signal | The same rate, per `Signal_Type__c` | `Status__c`, `Signal_Type__c` |
| Opportunities created from priorities | Opportunities whose Id is in `Action_Record_Id__c` | `Action_Record_Id__c`, Opportunity |
| How those opportunities progress | Stage, amount and win rate of the opportunities above, over time | Opportunity |
| Time from refresh to action | `Actioned_On__c` minus `Refreshed_On__c`, average per seller and per signal | `Account_Priority__c` |
| Credits per conversation | Flex Credits consumed ÷ agent conversations | The consumption view from the account team |
| Seller feedback | A short survey: was the proposal right, was anything confusing | Pilot sellers |

Agree a baseline before the pilot starts: the follow-through rate on account-priority recommendations today, without the agent.

---

## What to build next

Use the same rule from [page 4](04-architecture-coworker-first.md):

1. **Default to Coworker.** Search, summaries and single record writes with review are built in.
2. **Add a skill** for read-and-format with one grounded action.
3. **Build an agent** only when the job needs at least two of: state across turns, a sequence or gate that must hold every time, writes that follow business rules, its own access control, a regression test suite.

### Next Best Action as a Coworker skill

**The ask:** "What should I focus on at Lakeshore?"

| Agent need | Present? |
|---|---|
| State across turns | No. One question, one answer |
| A sequence or gate that must hold | No |
| Writes that follow business rules | No. It's read-only |
| Its own access control | No. The seller's normal access is enough |
| A regression test suite | Helpful, not required |

**Skill or agent?** **Skill.** It's read-and-format. It can reuse the Account Brief's Apex action, and it reads the same `Account_Priority__c` records this agent acts on. When the seller says "act on that", the Priority Follow-Through agent takes over. The design is in the Account Brief demo: [Next Best Action skill](https://github.com/squarerootofc/afl-coworker-skills/blob/main/10-next-best-action-skill.md).

### Meeting follow-up

**The ask:** "I just met Lakeshore. Log the meeting, create the follow-up tasks, and update the opportunity."

| Agent need | Present? |
|---|---|
| State across turns | Yes. Review a list of proposed records, edit, confirm |
| A sequence or gate that must hold | Yes. Nothing is written until the seller approves the set |
| Writes that follow business rules | Yes. Several records, linked to the right account and opportunity |
| Its own access control | Maybe |
| A regression test suite | Yes |

**Skill or agent?** **Probably an agent,** with the same pattern as this one: propose, confirm, then a fixed `run` of one Apex action that writes everything in one transaction. Check first whether Coworker's built-in record updates cover the simple case ("log a call with Lakeshore"). If they do, build only the multi-record part.

### Your list

Bring the next three seller asks and run them through the rule:

| Seller ask | Coworker, skill or agent | Which agent needs it has | Owner |
|---|---|---|---|
| _____ | _____ | _____ | _____ |
| _____ | _____ | _____ | _____ |
| _____ | _____ | _____ | _____ |

---

## Design questions for the architect

Decide these before the pilot.

1. **Where does the agent read priority data?** From `Account_Priority__c` in Salesforce (as today), or from Data Cloud directly? Reading from Data Cloud means changing `AccountPriorityService`.
   ☐ Salesforce object ☐ Data Cloud ☐ Both

2. **What happens to stale priorities?** Today the agent shows every Open priority, whatever its `Refreshed_On__c`.
   ☐ Show all ☐ Hide after ___ days ☐ Show with the refresh date

3. **Who can dismiss a priority, and how?** The agent only sets Actioned. `Dismissed` exists but nothing sets it.
   ☐ The feed ☐ The seller, through the agent (a new gated action) ☐ The seller, on the record

4. **Should "my book" include team accounts?** Today it's accounts the seller owns.
   ☐ Owned only ☐ Owned plus account team ☐ Territory

5. **Is a Task or an Opportunity the right default?** Today the agent proposes a Task unless the seller asks otherwise.
   ☐ Task ☐ By signal type (for example Renewal and Expansion default to Opportunity)

6. **How should a priority link to its outcome for reporting?** `Action_Record_Id__c` is text.
   ☐ Keep text ☐ Add a lookup to Opportunity ☐ Add lookups to both

7. **Sharing on `Account_Priority__c`?** The demo uses Read/Write.
   ☐ Controlled by Parent (follows the account) ☐ Private ☐ Keep

---

## Golden rules

Keep these on screen for the next build.

1. **Coworker first.**  
   Build a skill or an agent only for what Coworker can't do on its own.

2. **Data and rules in code, conversation in AI.**  
   Apex finds the priorities and writes the records. Agent Script holds the gate. The AI talks to the seller.

3. **The write is never an AI tool.**  
   It runs as a fixed step after a recorded "yes", once.

4. **Test as a seller.**  
   Admins see everything. Sellers find the permission and sharing problems.

5. **Read the trace, not the reply.**  
   The reply can say "created" when nothing ran. The trace shows what actually happened.

---

## Contacts

| Role | Name | Email | Slack |
|---|---|---|---|
| Customer lead | _____ | _____ | _____ |
| Customer architect | _____ | _____ | _____ |
| Customer engineer (driver) | _____ | _____ | _____ |
| Customer seller champion | _____ | _____ | _____ |
| Salesforce facilitator | _____ | _____ | _____ |
| Salesforce account team | _____ | _____ | _____ |

---

## Keep these

- [ ] This repo, including `code/`, in your Git
- [ ] The approved Agent Spec and pseudocode from [Exercise 1](07-exercise-design-agent.md)
- [ ] A few trace files that show the gate (from [page 10](10-exercise-preview-and-debug.md))
- [ ] The test summary table from [page 12](12-exercise-test.md), with notes
- [ ] The completed data mapping

---

## After the engagement

This demo never needs a reset between runs. Use the top-up. If you want to remove everything at the end of the engagement, see [16. Teardown](16-teardown.md).

---

[Index](README.md) · [← Previous: Production readiness](14-production-readiness.md) · [Next: Teardown →](16-teardown.md)
