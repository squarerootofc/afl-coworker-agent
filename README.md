# Priority Follow-Through: Build an Agent that Coworker Calls

**Audience:** Customer engineering team (builders), plus a seller champion for testing  
**Session:** Hands-on build workshop  
**Format:** Live build. One driver shares the screen and the group follows along.  
**Goal:** Build an employee agent in Agent Script that turns an account priority into a confirmed follow-up in Salesforce, and learn when to build an agent rather than use Coworker or a skill.

> **This is a live build.** Org setup and access checks happen before the session. On the day we design the agent, build two Apex actions, write the Agent Script, and test it as a seller.

> **All data is fictional.** Every account, contact, order and priority starts with "DEMO". Don't use real customer data.

**▶ Start here: [0. Quick start](00-quick-start.md)**, the driver's one-page cheat sheet. Admins and builders do the pre-work on pages 1 and 2 before build day.

---

## Why this design

- **Coworker first.** Coworker already handles search, summaries and single record updates. Skills cover read-and-format jobs such as an account brief. We build an agent only for the job that needs state, a confirmation gate and business rules.
- **Acting on a priority is that job.** A common sales goal is seller follow-through on account-priority recommendations, and more opportunities from them. Recommending is read-only. Acting writes to Salesforce, spans several turns, and must never happen without the seller saying yes.
- **Predictable where it matters.** Apex finds the priorities and does the write. Agent Script makes the write impossible until the seller confirms. The AI handles the conversation.

## What we build

The **Priority Follow-Through** agent, which:
- finds open account priorities on one account, or the top 10 across the seller's book
- proposes one Task or Opportunity for the priority the seller picks
- creates it only after the seller confirms, and marks the priority Actioned
- won't act on the same priority twice

```
Seller (Salesforce)
        |
   Agentforce Coworker  ── built in: search, summaries, single record updates
        |
        ├── "Account Brief" skill                (sister demo, shown not built)
        |
        └── Priority Follow-Through agent        ← built today in Agent Script
              ├── Get_Account_Priorities  (Apex, read)
              └── Log_Priority_Action     (Apex, write, gated on confirmation)
                        |
          Task or Opportunity created, priority marked Actioned
```

## Guide index

| # | Page | What's in it | Time |
|---|---|---|---|
| 0 | **[Quick start](00-quick-start.md)** ← start here | Driver's cheat sheet: gates, order of steps, time budget | build day |
| 1 | [Before the session](01-before-the-session.md) | Org, users, tools, licences | pre-work |
| 2 | [Org setup](02-org-setup.md) | Coworker, Agentforce, test seller, the 50-account data | pre-work |
| 3 | [Session plan](03-session-plan.md) | Agenda, roles, success checks, backup plans | 9:00 |
| 4 | [Coworker, skill or agent](04-architecture-coworker-first.md) | The decision rule and where the line sits | 10:00 |
| 5 | [The data](05-exercise-data-setup.md) | Tour the 50-account book | 10:20 |
| 6 | [Coworker first](06-demo-coworker-default.md) | Show Coworker and the Account Brief skill | 10:30 |
| 7 | [Exercise 1: Design the agent](07-exercise-design-agent.md) | Agent Spec, pseudocode, subagent map | 10:45 |
| 8 | [Exercise 2: Build the actions](08-exercise-build-actions.md) | New fields, two Apex classes, tests, permission sets | 11:30 |
| 9 | [Exercise 3: Write the Agent Script](09-exercise-write-agent-script.md) | Generate the bundle, write the `.agent`, validate | 1:20 |
| 10 | [Exercise 4: Preview and debug](10-exercise-preview-and-debug.md) | Live preview, read the traces, fix | 2:00 |
| 11 | [Exercise 5: Publish and connect](11-exercise-publish-and-connect.md) | Publish, activate, give access, call from Coworker | 2:30 |
| 12 | [Exercise 6: Test as a seller](12-exercise-test.md) | 13 test cases | 2:40 |
| 12a | [Test the whole path in Coworker](12a-test-in-coworker.md) | One conversation: brief (skill), next best action (skill), act (agent) | 3:00 showcase |
| 13 | [Troubleshooting](13-troubleshooting.md) | Common errors and fixes | as needed |
| 14 | [Production readiness](14-production-readiness.md) | CI/CD path, real priority data, consumption | 3:30 |
| 15 | [Next steps](15-next-steps.md) | Owners, dates, what to build next | 3:45 |
| 16 | [Teardown](16-teardown.md) | Optional, end of engagement only | after |

---

## Folder structure

```
afl-coworker-agent/
├── README.md                       ← you are here
├── 00-quick-start.md … 16-teardown.md   (plus 12a-test-in-coworker.md)
└── code/                           ← pre-tested fallback SFDX project
    ├── deploy.sh                   ← one-command deploy (add-only, re-runnable)
    ├── validate.sh                 ← read-only health check
    ├── sfdx-project.json
    ├── force-app/main/default/
    │   ├── objects/Account_Priority__c/        object + 11 fields
    │   ├── classes/                            AccountPriorityService, PriorityActionService (+ tests)
    │   ├── permissionsets/                     Priority_Admin, Priority_Agent_User, Priority_Agent_Access
    │   └── aiAuthoringBundles/Priority_Followthrough/    the agent
    └── scripts/apex/
        ├── seed-01-accounts.apex     50 accounts, contacts, products
        ├── seed-02-activity.apex     opportunities, tasks, cases
        ├── seed-03-orders.apex       12 months of orders
        └── seed-04-priorities.apex   account priorities and history; also the top-up
```

On the day we **build** from prompts. `code/` is the fallback if a step fails or time runs short.

---

## Relationship to the Account Brief demo

[afl-coworker-skills](https://github.com/squarerootofc/afl-coworker-skills) builds the Coworker skill. The two demos are separate: each deploys, seeds and tests on its own, and each works in an empty org.

They share the 5 DEMO test account names and the `Account_Priority__c` object, so both can live in one org. **When they share an org, deploy the skill demo first.** Its seed deletes every DEMO account, and that delete fails once account priorities exist.

---

## How the prompts are written

Every prompt uses the **ROLE / TASK / EXPECTED OUTPUT / RULES / EXAMPLE** structure, so you can paste it as-is into Agentforce Vibes or Claude Code. Use the same structure for the next agent you build.

---

## Assumptions

1. The org is a **sandbox or Developer Edition**, not production.
2. **Agentforce Coworker** and **Agentforce (Agents)** are enabled.
3. A **test seller** exists with a standard sales profile.
4. The driver has **Salesforce CLI** with the agent plugin, and **Agentforce Vibes** or **Claude Code** connected to the org.
