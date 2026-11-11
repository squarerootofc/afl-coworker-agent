[Index](README.md) · [← Previous: Before the session](01-before-the-session.md) · [Next: Session plan →](03-session-plan.md)

# 2. Org setup

One-time admin pre-work in the sandbox. When you finish, the org has Coworker and Agentforce on, a test seller, and the 50-account book of business loaded. **No Apex and no agent yet**: the group builds those on the day.

**Who:** Customer Salesforce admin, with the driver for Step 5. **Time:** about 1 hour, plus Coworker's own setup time. **Due:** the day before the session.

---

## Step 1: Do the shared org setup

The org-level setup is the same as for the Account Brief demo. Follow those pages, then come back here.

| Page | What it covers | Needed for this demo? |
|---|---|---|
| [Configure Agentforce Vibes in the org](https://github.com/squarerootofc/afl-coworker-skills/blob/main/02-configure-agentforce-vibes-in-org.md) | Einstein on, Vibes licence, builder permission set | Yes, if the driver uses Vibes |
| [Turn on Agentforce Coworker](https://github.com/squarerootofc/afl-coworker-skills/blob/main/03-turn-on-agentforce-coworker.md) | Coworker on, user access, licences, Skills | Yes. Skills only matters for the Account Brief show on page 6 |
| [Configure Agentforce Vibes in VS Code](https://github.com/squarerootofc/afl-coworker-skills/blob/main/04-configure-vibes-in-vs-code.md) | VS Code, project, org connection | Yes, on the driver's laptop. In its Step 3, name the project `priority-agent` instead (see below) |

**Use a new, empty project for the live build.** On the driver's laptop:

```bash
sf project generate --name priority-agent
cd priority-agent
sf config set target-org <alias>
```

Open `priority-agent` in VS Code. The group builds everything there on the day. Keep this repo's `code/` separate: it holds the finished fallback, and the AI assistant shouldn't read it while the group builds.

> Skip the parts of those pages that build or test the Account Brief skill. Only the setup steps apply here.

---

## Step 2: Confirm Agentforce Agents is on

Coworker being on doesn't mean the org can build agents. Check it separately.

1. Setup > Quick Find **Einstein Setup**. **Turn on Einstein** is on.
2. Setup > Quick Find **Agentforce Agents**. Turn on **Agentforce**. Refresh the page if the agent list doesn't appear.
3. Give the driver the **Manage AI Agents** permission (System Administrators usually have it). It lets them build, publish and activate agents.
4. As the driver, open the App Launcher > **Agentforce Studio**. The agent list opens without a permission error.

> You don't need to create an agent here. The group generates it from the CLI on [page 9](09-exercise-write-agent-script.md).

---

## Step 3: Create the test seller

The tests on [page 12](12-exercise-test.md) run as a real seller, not as an admin, so sharing and permissions behave as they will in production.

1. Setup > Users > **New User**.
2. Profile: a standard sales profile, for example **Standard User**. **Not** System Administrator.
3. Give them Coworker access: Agentforce Coworker setup > **Manage Users** > *Manage Access to Agentforce Coworker* > **Manage** > select the seller > **Assign** > **Done**. (Same as [Account Brief demo, page 3, Step 2](https://github.com/squarerootofc/afl-coworker-skills/blob/main/03-turn-on-agentforce-coworker.md#step-2-give-builders-and-the-test-seller-access).)
4. If the org's Agentforce access is seat-based, also assign the licence in [Account Brief demo, page 3, Step 4](https://github.com/squarerootofc/afl-coworker-skills/blob/main/03-turn-on-agentforce-coworker.md#step-4-only-if-seat-based-assign-the-unmetered-license).
5. Confirm you can log in as them: Setup > Users > **Login** next to the user. If the link is missing, turn on Setup > Login Access Policies > *Administrators Can Log in as Any User*.
6. As the seller, open **New Task** and **New Opportunity**. Both forms open. Cancel them.
7. Write down the seller's **username**. You need it in Step 5.

Don't assign any demo permission sets yet. The seller gets `Priority_Agent_User` on [page 8](08-exercise-build-actions.md) and `Priority_Agent_Access` on [page 11](11-exercise-publish-and-connect.md).

---

## Step 4: If the Account Brief demo shares the org, deploy it first

Skip this step if the Account Brief demo isn't in this org.

The two demos share the 5 DEMO test account names and the `Account_Priority__c` object, so they can live in one org. The order matters:

| Order | Command | Why |
|---|---|---|
| 1 | From `afl-coworker-skills/code`: `./deploy.sh <alias>` | Its seed starts by **deleting every DEMO account** |
| 2 | Step 5 below (this demo's data load) | It adds to what's there and deletes nothing |
| After both | **Never re-run the Account Brief seed** | The account priority's account lookup is **Restrict on delete**. Once priorities exist, that delete fails. If it got through, it would wipe the 50-account book |

Between rehearsals, use this demo's top-up (`./deploy.sh <alias> --top-up`), never the Account Brief seed.

What happens to the shared accounts:
- The book's seed finds the 5 test accounts by **name and billing city** and leaves their contacts, opportunities, orders and cases alone.
- It moves the seller's 20 accounts to the test seller, and fills in a missing billing state.
- If the Account Brief seed created "Lakeshore Priority 1" and "2", seed-04 finds them by name and fills in their new fields (signal type, score, value, status). It doesn't create duplicates.

---

## Step 5: Load the 50-account book (data only)

### Why data only

`code/deploy.sh` is the **fallback**: it deploys everything, including the two Apex actions and the agent. If you run it now, the group has nothing left to build on the day.

So for the live session, load only the **object and the data** now. The group builds the Apex actions, the permission set and the agent on pages 8 to 11. Use the full `deploy.sh` only in a rehearsal org, or on the day if time runs short.

### 5a. Pre-work commands

Run these from `code/`, as the **driver** if you can. The user who runs seed-01 owns the 30 accounts outside the seller's book.

**1. Deploy the priority object and its 11 fields**

```bash
cd code
sf project deploy start --target-org <alias> --metadata CustomObject:Account_Priority__c --wait 10
```

**2. Deploy the admin permission set and assign it**

New fields get no field-level security by default. The seed scripts and the Apex tests need edit access to them, and `Priority_Admin` gives it.

```bash
sf project deploy start --target-org <alias> --metadata PermissionSet:Priority_Admin --wait 10
sf org assign permset --target-org <alias> --name Priority_Admin
```

If the admin running this isn't the driver, assign it to the driver too:

```bash
sf org assign permset --target-org <alias> --name Priority_Admin --on-behalf-of <driver-username>
```

> `Priority_Admin` is for the driver and admins only. Never assign it to sellers.

**3. Set the seller in seed-01**

Open `scripts/apex/seed-01-accounts.apex` and set line 12 to the seller's username:

```apex
String SELLER_USERNAME = 'seller@example.com';
```

The seed then makes the seller the owner of the first 20 accounts (their book, including the 5 test accounts). Only seed-01 reads this value.

**4. Run the 4 seed scripts, in order**

```bash
sf apex run --target-org <alias> --file scripts/apex/seed-01-accounts.apex
sf apex run --target-org <alias> --file scripts/apex/seed-02-activity.apex
sf apex run --target-org <alias> --file scripts/apex/seed-03-orders.apex
sf apex run --target-org <alias> --file scripts/apex/seed-04-priorities.apex
```

| Script | What it adds | Look for in the output |
|---|---|---|
| `seed-01-accounts.apex` | 50 DEMO accounts, their contacts, 6 DEMO products with standard price book entries. Activates the standard price book if it's inactive | `SEED 01 COMPLETE`, `DEMO accounts now: 50` |
| `seed-02-activity.apex` | Open, won and lost opportunities; 3 completed Tasks per account; cases | `SEED 02 COMPLETE`, plus the stage names it used |
| `seed-03-orders.apex` | 12 months of activated orders that follow each account's health | `SEED 03 COMPLETE`, `CPU ms used` |
| `seed-04-priorities.apex` | Open account priorities, plus 20 history records (14 Actioned, 6 Dismissed) | `SEED 04 COMPLETE`, `Open DEMO priorities now: 57` |

Every script is **add-only**. Each one fills only the DEMO accounts that don't have its records yet, so it's safe to run again after a failure.

> **Result:** the 6 new priority fields (`Status__c`, `Actioned_On__c`, `Action_Record_Id__c`, `Signal_Type__c`, `Propensity_Score__c`, `Estimated_Value__c`) already exist before Exercise 2. On the day, Prompt 8A **checks** them against the spec instead of creating them.

### 5b. Check the load

```bash
./validate.sh <alias> <seller-username>
```

`validate.sh` is read-only. It changes nothing in the org.

| Section | Check | Want | After data-only pre-work |
|---|---|---|---|
| Metadata | Apex classes (2 + 2 tests) | ≥ 4 | **FAIL, expected.** Built on page 8 |
| Metadata | Permission sets (Admin, Agent User) | ≥ 2 | **FAIL, expected** (1 of 2). `Priority_Agent_User` is built on page 8 |
| Metadata | Standard price book active | ≥ 1 | OK |
| Data | DEMO accounts | ≥ 50 | OK |
| Data | DEMO contacts | ≥ 150 | OK |
| Data | DEMO opportunities | ≥ 190 | OK |
| Data | DEMO orders | ≥ 480 | OK |
| Data | Open DEMO priorities | ≥ 57 | OK |
| Data | Actioned or Dismissed (history) | ≥ 21 | OK (20 history records, plus Lakeshore's Actioned one) |
| Test accounts | DEMO Lakeshore Medical Group (Chicago) | exactly 3 open | OK |
| Test accounts | DEMO Pinecrest School District (Portland) | exactly 1 | OK |
| Test accounts | DEMO Harbor Supply Co (Seattle) | exactly 1 | OK |
| Test accounts | DEMO Harbor Supply Co (Tacoma) | exactly 1 | OK |
| Test accounts | DEMO Ridgeway Logistics (Dallas) | exactly 0 | OK |
| Test seller | Accounts owned (seller book) | ≥ 20 | OK |
| Test seller | `Priority_Agent_User` assigned | ≥ 1 | **FAIL, expected.** Assigned on page 8 |
| Test seller | `Priority_Agent_Access` assigned | ≥ 1 | **FAIL, expected.** Assigned on page 11 |
| Agent | Published versions | | Empty until page 11 |

### 5c. Reference: what the full `deploy.sh` does

Use it in a rehearsal org, or as the fallback on the day.

```bash
cd code
./deploy.sh <alias> <seller-username>
```

| Step | What it does |
|---|---|
| 1 | Checks the org connection. Reads `IsSandbox` and `OrganizationType`, and asks before it continues in an org that isn't a sandbox or Developer Edition |
| 2 | Deploys the `Account_Priority__c` object and its 11 fields |
| 3 | Deploys `Priority_Admin` and assigns it to you, so the tests and seeds can write the new fields |
| 4 | Deploys `AccountPriorityService`, `PriorityActionService` and their test classes, and runs both test classes |
| 5 | Deploys `Priority_Agent_User`. With a seller username, assigns it to the seller |
| 6 | Runs seed-01 to seed-04. With a seller username, writes it into a temporary copy of seed-01, so the seller owns the first 20 accounts. Your file isn't changed |
| 7 | Validates the agent authoring bundle and deploys it as a **draft**: not published, not active |

It's **add-only** and safe to re-run: no step deletes data. Without a seller username, the driver owns all 50 accounts and no permission set goes to a seller.

Top-up only (runs Step 1, then seed-04):

```bash
./deploy.sh <alias> --top-up
```

---

## Done when

- [ ] Einstein, Coworker and Agentforce Agents are on
- [ ] The driver can open Agentforce Studio and has Manage AI Agents
- [ ] The test seller exists, isn't an admin, has Coworker access, and you can log in as them
- [ ] If the Account Brief demo shares the org, it was deployed **before** the data load
- [ ] `Account_Priority__c` and its 11 fields are deployed
- [ ] `Priority_Admin` is assigned to the driver
- [ ] The 4 seed scripts ran without errors
- [ ] `./validate.sh <alias> <seller-username>`: every **Data** and **Test accounts** line is OK, and the seller owns 20 accounts
- [ ] The Apex classes and `Priority_Agent_User` are **not** in the org yet (the group builds them on page 8)

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| seed-03 stops: `Standard price book is inactive. Run seed-01-accounts.apex first.` | The standard price book is inactive and seed-01 didn't run, or couldn't activate it | Run seed-01 first. If it still fails, activate it by hand: App Launcher > **Price Books** > Standard Price Book > **Active** > Save. Then re-run seed-03 |
| seed-01 stops: `SELLER_USERNAME not found or inactive: ...` | Typo in the username, or the user is inactive | Copy the username from Setup > Users. Check the user is active. Re-run seed-01 |
| A seed stops with `FIELD_CUSTOM_VALIDATION_EXCEPTION`, or an error from a trigger or flow | A validation rule or automation in the sandbox blocks the insert (Account, Contact, Opportunity, Task, Case or Order) | The error names the object and the rule. The whole script rolls back, so nothing half-loads. Ask the org's admin whether the rule can be turned off in the sandbox for the load. If not, load into a separate demo org. Re-run the same script afterwards; it's add-only |
| seed-03 stops: `Apex CPU time limit exceeded` | Order automation in the org uses up the CPU budget | Open `seed-03-orders.apex`, set `Integer BATCH = 1;`, run it, then set `BATCH = 2` and run it again. Set it back to `0` afterwards |
| seed-04 fails with a field access error (`No such column` or insufficient access on an priority field) | `Priority_Admin` isn't assigned to the user running the seed | Run the assign command in 5a, item 2. Re-run seed-04 |
| `Accounts owned (seller book)` shows 0 | seed-01 ran with `SELLER_USERNAME = ''` | Set the username and re-run seed-01. It moves the 20 accounts to the seller. The agent's "my book" mode only looks at the **account** owner. Whether related contacts and opportunities move with the account follows Salesforce's ownership transfer rules **(to confirm in the org)**; the agent doesn't depend on them |
| `Open DEMO priorities` is below 57 | Rehearsals used them up | Run the top-up: `./deploy.sh <alias> --top-up`, or `sf apex run --target-org <alias> --file scripts/apex/seed-04-priorities.apex` |
| The Account Brief seed fails with a delete error | It ran after this demo's data load; the Restrict lookup blocks the delete | Don't re-run it. See [Step 4](#step-4-if-the-account-brief-demo-shares-the-org-deploy-it-first) |
| `sf project deploy start` says the object isn't found in the project | The command didn't run from `code/` | `cd code` and run it again |

---

[Index](README.md) · [← Previous: Before the session](01-before-the-session.md) · [Next: Session plan →](03-session-plan.md)
