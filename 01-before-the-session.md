[Index](README.md) · [← Previous: Quick start](00-quick-start.md) · [Next: Org setup →](02-org-setup.md)

# 1. Before the session

Complete these checks **before build day**. On the day we build. We don't troubleshoot org access, licences or data loads.

**Who:** Customer Salesforce admin and the driver. **Due:** the day before the session.

---

## Checklist

### Org readiness

- [ ] **Org type: sandbox or Developer Edition, not production**
  - Run: `sf data query --target-org <alias> --query "SELECT IsSandbox, OrganizationType FROM Organization"`
  - Pass: `IsSandbox` is `true`, or `OrganizationType` is `Developer Edition`
  - `deploy.sh` runs the same check and asks before it continues in any other org

- [ ] **Agentforce Coworker is on**
  - Setup > Agentforce Coworker shows Coworker as on, with no warnings
  - Steps: [Account Brief demo, page 3](https://github.com/squarerootofc/afl-coworker-skills/blob/main/03-turn-on-agentforce-coworker.md)

- [ ] **Agentforce (Agents) is on, and the driver can open Agentforce Builder**
  - Setup > Quick Find **Agentforce Agents** > **Agentforce** is on
  - The driver opens **Agentforce Studio** from the App Launcher and sees the agent list
  - Steps: [2. Org setup, Step 2](02-org-setup.md#step-2-confirm-agentforce-agents-is-on)

- [ ] **Standard price book is active**
  - Run: `sf data query --target-org <alias> --query "SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true"`
  - Pass: `IsActive` is `true`
  - If it's `false`, `seed-01-accounts.apex` activates it. Note it anyway: the seed changes an org setting, and the admin running it needs edit access to price books

- [ ] **Account org-wide default noted**
  - Setup > Quick Find **Sharing Settings** > Organization-Wide Defaults > **Account**
  - Write down the value: Private, Public Read Only, or Public Read/Write
  - It decides test 13 on [page 12](12-exercise-test.md): if Account is **Private**, the seller sees only their 20 accounts and test 13 runs. Otherwise test 13 is skipped

- [ ] **Existing DEMO data is what you expect**
  - Run: `sf data query --target-org <alias> --query "SELECT COUNT() FROM Account WHERE Name LIKE 'DEMO %'"`
  - Pass: `0` in an empty org, or `5` if the Account Brief demo was deployed first (Lakeshore, Pinecrest, Ridgeway and the two Harbor accounts)
  - Anything else: find out where the DEMO accounts came from before you load the book

- [ ] **If the Account Brief demo shares this org, it was deployed first**
  - Its seed deletes every DEMO account. Once account priorities exist, that delete fails, because the priority's account lookup is **Restrict on delete**
  - Run order: [2. Org setup, Step 4](02-org-setup.md#step-4-if-the-account-brief-demo-shares-the-org-deploy-it-first)

- [ ] **Skills are on** (only needed for the Account Brief show on [page 6](06-demo-coworker-default.md))
  - Test from [Account Brief demo, page 1](https://github.com/squarerootofc/afl-coworker-skills/blob/main/01-before-the-session.md). If Skills is off, page 6 shows Coworker built-ins only. The agent build is not affected

### User access

- [ ] **Driver has the System Administrator profile**, or a custom profile with:
  - Modify All Data
  - Author Apex
  - Customize Application
  - Manage AI Agents (to build, publish and activate agents)
  - Coworker access

- [ ] **Test seller exists**
  - Standard sales profile, for example **Standard User**. **Not** System Administrator
  - Has Coworker access (Agentforce Coworker setup > Manage Users)
  - Can create a **Task** and an **Opportunity**: log in as the seller and open the New Task and New Opportunity forms. A standard sales profile allows both
  - You can log in as them: Setup > Users > **Login** next to the user
  - Write down the **username**. `deploy.sh`, `validate.sh` and the seed need it
  - On the day, the seller also gets `Priority_Agent_User` ([page 8](08-exercise-build-actions.md)) and `Priority_Agent_Access` ([page 11](11-exercise-publish-and-connect.md))

### Tools installed (driver's laptop)

- [ ] **Salesforce CLI 2.x**
  - Run: `sf --version`

- [ ] **Agent commands work**
  - Run: `sf agent generate authoring-bundle --help`
  - Pass: help text prints. If the command isn't found, run `sf update`. If it's still missing, install the agent plugin with `sf plugins install @salesforce/plugin-agent` **(to confirm whether your CLI version already bundles it)**

- [ ] **VS Code with Agentforce Vibes**, or **Claude Code with the Salesforce DX MCP server**
  - Setup: [Account Brief demo, page 4](https://github.com/squarerootofc/afl-coworker-skills/blob/main/04-configure-vibes-in-vs-code.md)

- [ ] **Org authenticated**
  - Run: `sf org login web --alias <alias>`
  - Confirm: `sf org display --target-org <alias>` shows the right username and org ID

- [ ] **This repo is cloned on the driver's laptop**
  - `code/` holds the pre-tested fallback for every build step

### Coworker hand-off

- [ ] **Coworker hand-off to a custom employee agent checked in this org, or the fallback agreed**
  - The Salesforce team checks ahead of the day whether Coworker hands a request to a custom employee agent in this release **(to confirm)**
  - If it doesn't, the seller opens the agent from the Agentforce panel in Lightning Experience. The build and the tests are the same; only test 10 changes

### Data

- [ ] **50-account book loaded** (data only, see [2. Org setup, Step 5](02-org-setup.md#step-5-load-the-50-account-book-data-only))
  - Run from `code/`: `./validate.sh <alias> <seller-username>`
  - Pass: every line under **Data** and **Test accounts** is OK, and **Accounts owned (seller book)** shows 20

---

## What happens if a gate fails

| Gate fails | Impact | Fix |
|---|---|---|
| Not a sandbox or Developer Edition | We don't load fictional data or deploy code there. The session becomes a design workshop | Use a sandbox, or a Salesforce-provided demo org |
| Coworker is off | Page 6 can't run, and Coworker can't hand off to the agent. The agent still runs from the Agentforce panel | Turn Coworker on ([Account Brief demo, page 3](https://github.com/squarerootofc/afl-coworker-skills/blob/main/03-turn-on-agentforce-coworker.md)) |
| Agentforce Agents is off, or the driver can't open Builder | No agent can be built or published. We stop after the Apex actions | Turn on Agentforce; give the driver Manage AI Agents |
| `sf agent` commands missing | Pages 9 to 11 can't run from the CLI | Update the CLI or install the agent plugin before the day |
| Test seller missing | Seed puts all 50 accounts on the driver, so "my book" tests (11 to 13) mean nothing. Tests run as admin and miss permission problems | Create the seller **before** the first data load. If the book is already loaded, re-run seed-01 with `SELLER_USERNAME` set: it moves the 20 accounts to the seller ([page 2 troubleshooting](02-org-setup.md#troubleshooting)) |
| Standard price book inactive and seed-01 can't activate it | seed-03 stops with "Standard price book is inactive". No orders, so priority reasons don't match any history | Activate it (App Launcher > Price Books > Standard Price Book > Active), then re-run seed-01 and seed-03 |
| Account org-wide default not noted | Test 13 is skipped or misread | Check Sharing Settings before the day |
| Account Brief demo deployed after this one | Its seed fails on the Restrict lookup, or the book is wiped | Don't re-run its seed. See [Step 4 on page 2](02-org-setup.md#step-4-if-the-account-brief-demo-shares-the-org-deploy-it-first) |
| Coworker hand-off not available | Test 10 can't pass | Seller uses the Agentforce panel. Log the hand-off as an open item |

---

## On the day

1. **Top up open priorities** (rehearsals use them up). From `code/`: `./deploy.sh <alias> --top-up`
2. **Run the health check:** `./validate.sh <alias> <seller-username>`. Everything under **Data** and **Test accounts** is OK, and the seller owns 20 accounts. Some lines show FAIL before the build, and that's expected: the Apex classes and `Priority_Agent_User` (built on page 8), `Priority_Agent_Access` (page 11), and the agent (not published until page 11)
3. **Driver shares the screen**, logged in as the admin, with VS Code and the org open
4. **Test seller is ready** in a separate browser or browser profile
5. **Facilitator confirms** everyone can see the screen
6. **Customer lead confirms** the agent job and the data scope before page 4 starts

---

[Index](README.md) · [← Previous: Quick start](00-quick-start.md) · [Next: Org setup →](02-org-setup.md)
