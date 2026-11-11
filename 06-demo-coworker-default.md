[Index](README.md) · [← Previous: The data](05-exercise-data-setup.md) · [Next: Exercise 1: Design the agent →](07-exercise-design-agent.md)

# 6. Coworker first

**Time:** 15 minutes  
**Format:** a show, not a build. The driver runs it as the **test seller**  
**Output:** the group has seen what Coworker already does, so the agent only covers what's left

Before building anything, see the default path working. Everything on this page already exists in the org.

---

## Setup

1. Log in as the test seller: Setup > Users > **Login** next to the seller.
2. Open the Sales app.
3. Open Coworker: click **Ask** next to the global search bar. (Pressing Enter in the search bar gives search results; **Ask** gives answers and can propose record changes.)

> Coworker searches through its own index. If it can't find DEMO records that you know exist, the index may not have caught up with the data load yet **(to confirm how long this takes in the org)**. This is one reason the data is loaded the day before.

---

## Part A: Coworker built-ins (5 minutes)

Run these three prompts. Nothing here was built for this demo.

**1. Search**

```
Who are my contacts at DEMO Lakeshore Medical Group?
```

**Expect:** a list of Lakeshore contacts with names and titles. In an org with only this demo there are 6; if the Account Brief demo shares the org, Lakeshore has that demo's 7.

**2. Search with a filter**

```
Show my open opportunities closing this quarter
```

**Expect:** open opportunities on the seller's own accounts with a close date in the current quarter. Only the seller's records, because Coworker runs as the logged-in user.

**3. A single record write**

```
Log a call with DEMO Lakeshore Medical Group for today
```

**Expect:** Coworker proposes a Task for the call, related to Lakeshore and dated today, and shows it for review before anything is saved.

> This one needs the **Agent Actions** toggle: Agentforce Coworker setup > **Add Existing Data** table > Salesforce data source row > **Agent Actions** column on. Without it, Coworker can't create or update records. See [Give users access to create and update records](https://developer.salesforce.com/docs/data/agentforce-coworker/guide/agentforce-coworker-allow-coworker-update-records.html).

**Cancel the proposal** rather than saving it, so the data stays as the tests expect. Point out: Coworker already does one write, with review. That's not a reason to build an agent.

---

## Part B: the Account Brief skill (5 minutes)

**Only if the Account Brief demo is deployed in this org.** If it isn't, skip to Part C.

```
Brief me on DEMO Lakeshore Medical Group
```

**Expect:** a brief in a fixed format: company overview, account priorities, open opportunities, orders, cases and more, with exact figures.

Point out:
- **It's a skill**, not an agent. Coworker picked it because the request matched the skill's description.
- **It's read-only.** It calls one Apex action (`Get_Account_Context`) and formats what comes back.
- **It passes only one agent test** (a fixed format with exact figures). That's why it's a skill. See the rule on [page 4](04-architecture-coworker-first.md).
- Depending on the version deployed, the brief may list every account priority on file, including the one already actioned. That's fine for a read-only brief. The agent we build offers only Open priorities.

---

## Part C: where Coworker stops (5 minutes)

Now ask the question we build the agent for:

```
Act on Lakeshore's top account priority
```

**Watch what happens.** Coworker may find the priority and propose a Task. **Don't confirm it.** Cancel.

Then ask the group what's missing:

| What the job needs | Coworker alone |
|---|---|
| Choose from the seller's open priorities, ranked, across several turns | Nothing holds the chosen priority and the agreed details as state that later steps depend on |
| Never write before the seller agrees to a full proposal | Reviews each write, but nothing fixes the order of the steps |
| Only act on Open priorities, never twice | No rule; it would create a second Task |
| Mark the priority Actioned and link it to the new record, in the same transaction | Writes one record only |
| A repeatable test suite | Nothing to point a test suite at |

That gap is the agent. Coworker stays the front door. When a seller asks to act on a priority, Coworker hands the job to the **Priority Follow-Through** agent, which we design next.

---

## What you have now

- The group has seen Coworker search and propose a write, with nothing built
- The Account Brief skill shown as the read-only default (if deployed)
- A clear list of what Coworker can't do alone for priority follow-through: that's the agent's job

**Next:** [Exercise 1: Design the agent](07-exercise-design-agent.md)

---

[Index](README.md) · [← Previous: The data](05-exercise-data-setup.md) · [Next: Exercise 1: Design the agent →](07-exercise-design-agent.md)
