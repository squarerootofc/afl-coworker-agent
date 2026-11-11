[Index](README.md) · [← Previous: Org setup](02-org-setup.md) · [Next: Coworker, skill or agent →](04-architecture-coworker-first.md)

# 3. Session plan

## The day on one page

| Time | Block | Page | Output |
|---|---|---|---|
| 9:00–9:50 | Welcome and event program | | |
| 10:00 | **The line:** sort your real seller asks into Coworker, skill or agent | [04](04-architecture-coworker-first.md) | Decision rule agreed, agent job chosen |
| 10:20 | **The data:** tour the 50-account book, check the counts | [05](05-exercise-data-setup.md) | The group knows the data |
| 10:30 | **Coworker first:** Coworker built-ins and the Account Brief skill | [06](06-demo-coworker-default.md) | The group has seen the default path |
| 10:45 | **Exercise 1: Design the agent.** Spec, pseudocode, subagent map. The customer lead drives | [07](07-exercise-design-agent.md) | Approved Agent Spec |
| 11:30 | **Exercise 2: Build the actions.** Fields and `Get_Account_Priorities` | [08](08-exercise-build-actions.md) | First class deployed, tests pass |
| 12:00 | Lunch | | |
| 1:00 | **Exercise 2, continued.** `Log_Priority_Action` and the permission set | [08](08-exercise-build-actions.md) | Both classes deployed, tests pass |
| 1:20 | **Exercise 3: Write the Agent Script**, validate | [09](09-exercise-write-agent-script.md) | `.agent` compiles |
| 2:00 | **Exercise 4: Preview and debug.** Live actions, read traces, fix | [10](10-exercise-preview-and-debug.md) | Tests 1–7 and 11–12 pass in preview |
| 2:30 | **Exercise 5: Publish and connect.** Publish, activate, give access, call from Coworker | [11](11-exercise-publish-and-connect.md) | The agent runs for the seller |
| 2:40 | **Exercise 6: Test as a seller** | [12](12-exercise-test.md) | Test results recorded |
| 3:00 | **Showcase:** the whole path in one Coworker conversation: brief, next best action, act | [12a](12a-test-in-coworker.md) | Routing result recorded |
| 3:30 | Production path, owners, dates | [14](14-production-readiness.md), [15](15-next-steps.md) | Next steps table filled in |

[Troubleshooting](13-troubleshooting.md) is open all day.

---

## Roles

| Role | Who | Does |
|---|---|---|
| **Driver** | Customer engineer | Shares the screen, runs the prompts and commands, builds live |
| **Customer lead** | Customer engineering lead | Owns the design. Writes the Agent Spec in Exercise 1, approves scope and design choices |
| **Architect** | Customer architect | Challenges the design, owns the production path |
| **Seller champion** | Customer seller | Brings real seller asks to page 4. Runs the tests as the seller and judges whether the agent helps |
| **Facilitator** | Salesforce technical architect | Runs the agenda, unblocks, keeps time. Navigates; doesn't drive |
| **Account team** | Salesforce account team | Licensing, consumption and sandbox support |

---

## How we work

1. **Build live.** The driver builds from prompts so the group sees how it's done. `code/` is the fallback, not the plan.
2. **Coworker first.** Coworker handles search, summaries and single record writes. Skills handle read-and-format jobs. We build an agent only for the job that passes the rule on [page 4](04-architecture-coworker-first.md).
3. **Predictable where it matters.** Apex reads the priorities and does the write, with the business rules. Agent Script makes the write unreachable until the seller confirms. The AI handles the conversation.
4. **Test as a seller.** Admin tests miss permission and sharing problems. The seller champion runs the tests on [page 12](12-exercise-test.md).
5. **Measure, don't argue.** The trace shows when the write happened. The test results show what works. Consumption is read from the org, not estimated.

---

## Success checks for the day

- [ ] The line is agreed and written down, with the agent job justified against the rule
- [ ] The Account Brief skill is shown working in Coworker (if it's deployed in this org)
- [ ] The customer lead approves the Agent Spec before any code is written
- [ ] Both Apex actions are deployed, their tests pass, and every record query and write runs in user mode
- [ ] The `.agent` file validates. The trace shows the write only after the seller confirms
- [ ] The agent is published and active, and the seller has agent access
- [ ] Tests 1–9 and 11–12 pass. Test 10 passes, or is logged as an open item if Coworker hand-off isn't available. Test 13 runs if the Account org-wide default is Private
- [ ] Agent consumption shows in the sandbox
- [ ] Production path owners and dates are recorded

---

## Backup plans

| If this fails | We do this |
|---|---|
| Coworker doesn't hand off to the custom agent | The seller opens the agent from the Agentforce panel in Lightning Experience. The build, tests and consumption are the same. Test 10 is logged as an open item |
| Skills isn't on, or the Account Brief demo isn't in the org | Page 6 shows Coworker built-ins only. The agent build isn't affected |
| No sandbox available | Build in a Salesforce-provided demo org and take the code home as an unmanaged package |
| A seed script fails in the sandbox (validation rule, trigger, CPU limit) | Data is loaded the day before, not live. The scripts are add-only and re-runnable. If a rule blocks the load, note it and use a demo org |
| Apex doesn't compile or tests fail | The driver fixes it with the prompt. If it takes more than 10 minutes, deploy the class from `code/` ([page 8 fallback](08-exercise-build-actions.md#fallback)) |
| Agent Script won't validate or publish | Check [Troubleshooting](13-troubleshooting.md). Most "Internal Error" publishes come from a missing `outputs:` block, or `default_agent_user` set on an employee agent. If stuck, deploy the `.agent` from `code/` |
| The seller can't see the agent | Check `Priority_Agent_Access` is assigned and the agent is active |
| Someone asks how we know the agent won't write without asking | Show the gate in the Agent Script ([page 4](04-architecture-coworker-first.md#the-gate-explained-honestly)), the Apex rules, and the trace. Run the test suite as the evidence |

### If time runs short

Cut in this order:

1. Drop the Opportunity path and ship Task only.
2. Drop "my book" mode and keep the single-account path.
3. Deploy the pre-built actions from `code/` and spend the keyboard time on the Agent Script.
4. Deploy the pre-built `.agent` and spend the time on traces and tests.
5. If the team is new to Agentforce, stop at Coworker and walk through the agent build instead of typing it.

---

[Index](README.md) · [← Previous: Org setup](02-org-setup.md) · [Next: Coworker, skill or agent →](04-architecture-coworker-first.md)
