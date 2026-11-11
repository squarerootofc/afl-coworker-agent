[Index](README.md) · [Next: Before the session →](01-before-the-session.md)

# 0. Quick start

**For the driver on build day**

---

## Before you start (pre-work)

Full checklist: [1. Before the session](01-before-the-session.md) and [2. Org setup](02-org-setup.md).

✅ Org is a **sandbox or Developer Edition**, not production  
✅ **Coworker** and **Agentforce** are on  
✅ **Test seller** exists (standard sales profile) and has Coworker access  
✅ `sf org display --target-org <alias>` shows the right org  
✅ `sf agent --help` works (agent plugin installed)  
✅ 50 DEMO accounts loaded: `./code/validate.sh <alias> <seller>` shows all OK under **Data**  
✅ If the Account Brief demo shares the org, it was deployed **first**

---

## Order of the day

### 1. The line (20 min): [page 4](04-architecture-coworker-first.md)
Sort your real seller asks into Coworker, skill or agent. Agree on the decision rule.

### 2. Data and Coworker first (25 min): [pages 5](05-exercise-data-setup.md) and [6](06-demo-coworker-default.md)
Tour the 50-account book. Show Coworker and the Account Brief skill working.

### 3. Design the agent (45 min): [page 7](07-exercise-design-agent.md)
The customer lead writes the Agent Spec and pseudocode. **No code until the spec is approved.**

### 4. Build the actions (50 min): [page 8](08-exercise-build-actions.md)
Paste **Prompts 8A to 8D**. Verify: both test classes pass.

### 5. Write the Agent Script (40 min): [page 9](09-exercise-write-agent-script.md)
Generate the bundle, write the `.agent` with **Prompts 9A and 9B**, and validate.

### 6. Preview and debug (30 min): [page 10](10-exercise-preview-and-debug.md)
Live preview with real actions. Read the trace: **the write happens only after "yes"**.

### 7. Publish, connect, test (30 min): [pages 11](11-exercise-publish-and-connect.md) and [12](12-exercise-test.md)
Publish, activate, give the seller access, and run the 13 tests as the seller.

### 8. The whole path in Coworker (15 min): [page 12a](12a-test-in-coworker.md)
One Coworker conversation: "Brief me on…" (skill), "What should I focus on…" (skill), "Act on…" (agent). Good for the 3:00 showcase.

---

## If something breaks

See [13. Troubleshooting](13-troubleshooting.md). The most common problems:

- **Publish says "Internal Error":** an action is missing its `outputs:` block, or `default_agent_user` was set on this employee agent.
- **Seller can't see the agent:** `Priority_Agent_Access` isn't assigned, or the agent isn't activated.
- **Action returns nothing:** the seller is missing `Priority_Agent_User`, or doesn't own the accounts.

**Running out of time?** Deploy the matching piece from `code/` and keep going:

```bash
cd code
./deploy.sh <alias> <seller-username>
```

---

## Between rehearsals

The agent writes data, so each run uses up open priorities. **Top up; don't reset:**

```bash
./code/deploy.sh <alias> --top-up
```

This adds new Open priorities to any account below its starting count, and it never deletes anything.

---

## Time budget

| Block | Time |
|---|---|
| The line + data + Coworker first | 45 min |
| Design | 45 min |
| Actions | 50 min |
| Agent Script | 40 min |
| Preview and debug | 30 min |
| Publish, connect, test | 30 min |
| **Hands-on total** | **4 hours** |

---

[Index](README.md) · [Next: Before the session →](01-before-the-session.md)
