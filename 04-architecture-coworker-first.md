[Index](README.md) · [← Previous: Session plan](03-session-plan.md) · [Next: The data →](05-exercise-data-setup.md)

# 4. Coworker, skill or agent

**Time:** 20 minutes, at the whiteboard  
**Output:** a decision rule the group agrees on, and the one job we build an agent for today

Most seller requests don't need a new agent. Coworker already does a lot, and each agent you build is something to test, secure and maintain. This page draws the line.

---

## The decision rule

1. **Default to Coworker.** Search, summaries, and single record creates or updates with review are built in.
2. **Add a skill** when the job is read-and-format with one grounded action. Example: a brief in a fixed shape that must quote exact figures.
3. **Build an agent** only when the job needs **at least two** of these:
   - state across turns
   - a sequence or gate that must hold every time
   - writes that follow business rules
   - its own access control
   - a regression test suite

If a job passes only one test, it's a skill or Coworker with a good prompt.

---

## Where the line sits

| Seller asks | Handled by | Why |
|---|---|---|
| "Who's my contact at Lakeshore?" / "Show my open opps" | Coworker, built in | CRM search is native |
| "Log a call with Lakeshore for today" | Coworker, built in | One record write, proposed for the seller to review. Needs the Agent Actions toggle in Coworker setup |
| "Brief me on Lakeshore" | Coworker skill: Account Brief | Read-only, one Apex action, fixed format |
| "What should I focus on at Lakeshore?" | Coworker skill: Next Best Action ([Account Brief demo, page 10](https://github.com/squarerootofc/afl-coworker-skills/blob/main/10-next-best-action-skill.md)) | Read-only, same Apex action |
| "Which of my accounts need attention?" then "Act on that one" | **Agent: Priority Follow-Through** | Several turns, a confirmation gate before the write, a write with rules and a link back, testable |

---

## Exercise: bring 5 real seller asks and sort them

> **10 minutes. The seller champion leads.**
>
> 1. Write down 5 things your sellers ask for today, in their own words.
> 2. For each one, tick the agent tests it needs.
> 3. Put it in a column: Coworker, skill, or agent. Two or more ticks means agent.
> 4. Compare with the follow-through job below. If one of your asks scores higher, consider building that instead. The build steps on pages 7 to 12 stay the same.
>
> | # | Seller ask | State | Gate | Rule-bound write | Own access | Test suite | Handled by |
> |---|---|---|---|---|---|---|---|
> | 1 | | ☐ | ☐ | ☐ | ☐ | ☐ | |
> | 2 | | ☐ | ☐ | ☐ | ☐ | ☐ | |
> | 3 | | ☐ | ☐ | ☐ | ☐ | ☐ | |
> | 4 | | ☐ | ☐ | ☐ | ☐ | ☐ | |
> | 5 | | ☐ | ☐ | ☐ | ☐ | ☐ | |

---

## Why an agent for priority follow-through

The goal is for sellers to follow through on account-priority recommendations, and for more opportunities to come from them. Recommending is read-only, so it stays a skill. **Acting** on a priority passes all five tests:

| Test | How the follow-through job needs it |
|---|---|
| State across turns | The seller picks a priority, sees a proposal, maybe changes the date, then says yes. The agent has to remember the chosen priority and the agreed details across those turns |
| A gate that must hold | The Task or Opportunity must never be created before the seller says yes. Not most of the time: every time |
| Writes with business rules | Only Open priorities can be acted on. One follow-up per priority. The priority is marked Actioned and linked to the new record in the same transaction, so follow-through can be reported |
| Its own access | Sellers get the agent through its own permission sets. The agent runs as the seller, so it only sees and writes what the seller can |
| A test suite | Apex unit tests for the rules, plus 13 seller tests on [page 12](12-exercise-test.md) that can run again before every change |

---

## The architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Seller in Salesforce                                            │
│  "Which of my accounts need attention?"  "Act on Lakeshore's #1" │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  Agentforce Coworker  (the front door, built in)                 │
│  Search, summaries, single record writes with review             │
│  "Account Brief" skill (Account Brief demo, shown only)          │
└───────────────────────────────┬──────────────────────────────────┘
                                │  hands off "act on a priority"
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  Priority Follow-Through  (employee agent, Agent Script)         │
│                                                                  │
│  agent_router ─┬─> select_priority ─────┬─> propose_follow_up    │
│                │     (one account)      │      │                 │
│                │ get_account_priorities │      │ seller says yes │
│                │     (AI may call)      │      ▼                 │
│                ├─> my_book ─────────────┘ create_follow_up       │
│                │   (all accounts)              │                 │
│                │ get_account_priorities        │                 │
│                │ (script runs it first)        │                 │
│                └─> off_topic          log_priority_action        │
│                                     (runs from script only)      │
└───────────────────┬───────────────────────────┬──────────────────┘
                    ▼                           ▼
┌───────────────────────────────┐ ┌────────────────────────────────┐
│  Apex: AccountPriorityService │ │  Apex: PriorityActionService   │
│  "Get Account Priorities"     │ │  "Log Priority Action"         │
│  read: one account, or my book│ │  write: Task or Opportunity,   │
│                               │ │  priority marked Actioned      │
└───────────────────────────────┘ └────────────────────────────────┘
```

Every seller message enters at `agent_router`. While a follow-up is in progress, the router skips the AI and goes straight to `propose_follow_up`, or to `create_follow_up` once the seller has confirmed. Control 5 below explains why.

There are two ways to find a priority. `select_priority` handles one account: the AI calls `get_account_priorities` with the account the seller named. `my_book` handles "what needs attention" across all the seller's accounts: the script runs `get_account_priorities` first, and the AI only lists what came back. Control 6 below explains why.

### What each layer does

| Layer | Owns | Doesn't own |
|---|---|---|
| **Coworker** | Routing the seller's request. Built-in search, summaries and single record writes. The Account Brief skill | Multi-turn follow-through, the confirmation gate, priority business rules |
| **Agent Script** (`Priority_Followthrough`) | The conversation: which subagent runs, what the AI is told in each step. State in variables (`priority_id`, `confirmed` and the agreed follow-up details). **The gate**: when the write can run. Which lookups run before the AI answers (`my_book`) | Reading or writing Salesforce data itself. Business rules |
| **Apex** (`AccountPriorityService`, `PriorityActionService`) | Reads and writes. The rules: open priorities only; one follow-up per priority (a second try returns `PRIORITY_NOT_OPEN`); every record query and write in user mode (`WITH USER_MODE`, `insert as user`, `update as user`), so sharing and field access apply; reads the org's first open Opportunity stage and default Task status instead of hard-coding them | Talking to the seller. Deciding whether the seller agreed |

---

## The gate, explained honestly

The write is the part reviewers ask about first. Here is exactly what holds it in place.

**What doesn't work today.** Agent Script has a `require_user_confirmation` setting on actions. It **does not enforce confirmation** at run time in Agent Script today. We don't rely on it.

**What we do instead.** The write action is **never given to the AI as a tool**. The AI can't decide to call it. Five controls hold the write, all in the `.agent` file or the Apex:

| # | Control | Where | What it guarantees |
|---|---|---|---|
| 1 | `log_priority_action` runs only from `create_follow_up`, with `run`, inside `if @variables.confirmed == True`. Both ways into `create_follow_up` (the end of a `propose_follow_up` turn, and the router's state check) need `confirmed == True`, and only the confirm tool in `propose_follow_up` sets it | Agent Script | No write unless the confirm step happened |
| 2 | The confirm tool (`confirm_follow_up`) is hidden on the first turn of `propose_follow_up` (`available when @variables.propose_turns > 1`) | Agent Script | The seller always sees a proposal before anything can be confirmed. "Act on it, yes" in one message can't skip the proposal |
| 3 | `create_follow_up` sets `confirmed` back to False right after the run | Agent Script | The write happens once per confirmation |
| 4 | `PriorityActionService` rejects any priority that isn't Open, and locks the row while it checks (`FOR UPDATE`) | Apex | No duplicate follow-ups, even if the agent tried twice |
| 5 | Every seller message starts at `agent_router`. Before the AI classifies anything, the router checks state: if `confirmed` is True it goes to `create_follow_up`; if a priority is chosen it goes to `propose_follow_up` | Agent Script | A short reply like "yes" or "make it Friday" goes back to the proposal. It isn't re-classified and the proposal isn't lost |

**What stays with the AI.** The AI decides whether the seller's reply means yes. It calls `confirm_follow_up` when it does. The controls guarantee that the write **can't come before** that step, that it happens **once**, and that Apex rules hold no matter what the AI does.

**One more control, for a read.** The same idea applies when the agent must have data before it answers.

| # | Control | Where | What it guarantees |
|---|---|---|---|
| 6 | `my_book` runs `get_account_priorities` with `run` (both inputs blank) before the AI writes anything. The results are put in the prompt, and only then does the AI list them and ask which one | Agent Script | "Which of my accounts need attention?" always gets real priorities. In preview, when the lookup was an AI tool with two optional inputs, the AI skipped it and made up accounts |

**The lesson: if the agent must have data before it answers, fetch it with `run`. Don't offer it as an optional tool.** An AI tool whose inputs are all optional is easy for the AI to skip. When it skips it, it fills the gap by inventing. It's the same rule as the write gate: anything that must happen is in the script, not left to the AI.

**The evidence.** On [page 10](10-exercise-preview-and-debug.md) you read the trace. It shows the proposal turn, then the confirm tool call, then `log_priority_action`, in that order. Show it to anyone who asks.

---

## What we are NOT building

- ❌ A replacement for Coworker. Coworker stays the front door and the default
- ❌ Briefs, research or recommendations inside the agent. Those stay in Coworker and skills
- ❌ A write the AI can call as a tool
- ❌ Editing or deleting existing records, or bulk actions across many priorities
- ❌ Dismissing priorities. The `Dismissed` status exists for reporting; the agent doesn't set it
- ❌ A connection to the real priority feed. The seed data stands in for it; [page 14](14-production-readiness.md) maps the fields
- ❌ A custom UI. The seller uses Coworker or the Agentforce panel

---

[Index](README.md) · [← Previous: Session plan](03-session-plan.md) · [Next: The data →](05-exercise-data-setup.md)
