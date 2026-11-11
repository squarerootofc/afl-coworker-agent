[Index](README.md) · [← Previous: Next steps](15-next-steps.md)

# 16. Teardown (optional)

**When:** Only at the end of the engagement, and only if the customer wants the demo removed  
**Who:** The driver, as an admin  
**Time:** 30 to 45 minutes

> **This demo never needs a reset between runs.** To get open priorities back, use the top-up: `./code/deploy.sh <alias> --top-up`. It only adds. Teardown is for removing the demo for good.

> **⚠️ Destructive.** This page deletes an agent, Apex, permission sets, records and possibly a custom object. Run it only in a sandbox or Developer Edition org. Every prompt shows counts and waits for "yes" before it deletes anything.

---

## Before you start

### 1. Confirm the org

```bash
sf org display --target-org <alias>
sf data query --target-org <alias> -q "SELECT Name, IsSandbox, OrganizationType FROM Organization"
```

**If `IsSandbox` is false and `OrganizationType` isn't Developer Edition, stop.**

### 2. Check whether the Account Brief demo is in this org

```bash
sf data query --target-org <alias> -q "SELECT Id, Name FROM ApexClass WHERE Name = 'AccountContextService'"
```

Write down the result. It decides how far you go at [Step 6](#step-6-the-shared-object-rule).

| Result | Account Brief demo | You'll delete |
|---|---|---|
| 1 row | Present | Steps 1 to 5 only. The shared object, its 5 base fields and the DEMO accounts stay |
| 0 rows | Not present | Steps 1 to 8 |

### 3. Work from your build project, not `code/`

`sf project delete source` deletes the component from the org **and** the local files. Run it from the project you built in today, or from a copy. Never from this repo's `code/`, which is the reference.

### 4. Keep `Priority_Admin` until the end

New fields have no field-level security by default. The driver needs `Priority_Admin` to read `Action_Record_Id__c` and delete priorities. It is removed last, in [Step 8](#step-8-delete-the-object-and-the-admin-permission-set).

### Safety checklist

Only continue if all of these are true:

- [ ] `IsSandbox` is true, or this is a Developer Edition org
- [ ] This is the right org (`sf org display` shows the expected username and instance)
- [ ] You exported anything you want to keep: the follow-through reports, a few trace files, the test results
- [ ] Nobody else is using the demo in this org
- [ ] Every DEMO account is fictional (name starts with "DEMO ")
- [ ] You wrote down whether `AccountContextService` exists

---

## Step 1: Deactivate the agent

```bash
sf agent deactivate --json --api-name Priority_Followthrough --target-org <alias>
```

Sellers can no longer use it. Check:

```bash
sf data query --target-org <alias> -q "SELECT VersionNumber, Status FROM BotVersion WHERE BotDefinition.DeveloperName = 'Priority_Followthrough'"
```

No version shows `Active`.

---

## Step 2: Delete the agent (Setup)

The CLI can't fully delete a published agent; the org reports dependency errors. Use Setup.

1. Setup > Quick Find **Agents** > **Agentforce Agents** **(to confirm the path in this release)**.
2. Find **Priority Follow-Through**.
3. Row menu > **Delete**, then confirm **(to confirm the labels)**.
4. If Setup refuses because a permission set still references the agent, do [Step 3](#step-3-remove-the-seller-permission-sets) for `Priority_Agent_Access` first, then come back.

Check:

```bash
sf data query --target-org <alias> -q "SELECT Id FROM BotDefinition WHERE DeveloperName = 'Priority_Followthrough'"
```

0 rows.

Whether deleting the agent in Setup also removes the authoring bundle is **(to confirm)**. If the bundle is still there, delete it from your build project (this also deletes the local files):

```bash
sf project delete source --json --metadata AiAuthoringBundle:Priority_Followthrough --target-org <alias>
```

---

## Step 3: Remove the seller permission sets

**Prompt 16A: Unassign and delete the seller permission sets**

```
ROLE
You are a Salesforce admin removing demo access from an org.

TASK
Remove the permission sets Priority_Agent_Access and Priority_Agent_User
from org <alias>.
1. List every user assigned to either one:
   SELECT Id, Assignee.Username, PermissionSet.Name FROM PermissionSetAssignment
   WHERE PermissionSet.Name IN ('Priority_Agent_Access','Priority_Agent_User')
2. Show me the list and the counts. Wait for me to type "yes".
3. After "yes", delete each assignment:
   sf data delete record --sobject PermissionSetAssignment --record-id <Id> --target-org <alias>
4. Delete both permission sets from my build project:
   sf project delete source --json --metadata PermissionSet:Priority_Agent_Access PermissionSet:Priority_Agent_User --target-org <alias>
5. Verify with the query in step 1 (0 rows) and:
   SELECT Name FROM PermissionSet WHERE Name IN ('Priority_Agent_Access','Priority_Agent_User')

EXPECTED OUTPUT
1. A table of assignments: user, permission set
2. A pause for "yes"
3. A table: step, result
4. The verification results

RULES
- Show the plan and wait for "yes" before deleting anything.
- Don't touch Priority_Admin. It is removed at the end.
- Don't touch any other permission set.
- Run commands from my build project, never from this repo's code/ folder.
- Every command uses --target-org <alias>.

EXAMPLE OUTPUT
Found 2 assignments:
| User | Permission set |
| seller@example.com | Priority_Agent_Access |
| seller@example.com | Priority_Agent_User |
Then I'll delete both permission sets. Type "yes" to proceed.
[After yes]
| Step | Result |
| Unassign (2) | Deleted |
| Delete permission sets | Succeeded: 2 components |
Verification: 0 assignments, 0 permission sets.
```

**What to check:** the seller has neither permission set, and neither appears in Setup > Permission Sets.

---

## Step 4: Delete the Apex classes

**Prompt 16B: Delete the four Apex classes**

```
ROLE
You are a Salesforce developer removing demo code from an org.

TASK
Delete these Apex classes from org <alias>:
AccountPriorityService, AccountPriorityServiceTest,
PriorityActionService, PriorityActionServiceTest
1. Confirm they exist:
   SELECT Name FROM ApexClass WHERE Name IN ('AccountPriorityService','AccountPriorityServiceTest','PriorityActionService','PriorityActionServiceTest')
2. Show me the list. Wait for me to type "yes".
3. After "yes", from my build project:
   sf project delete source --json --metadata ApexClass:AccountPriorityService ApexClass:AccountPriorityServiceTest ApexClass:PriorityActionService ApexClass:PriorityActionServiceTest --target-org <alias>
4. Verify with the query in step 1.

EXPECTED OUTPUT
1. The list of classes found
2. A pause for "yes"
3. The delete result
4. Verification: 0 classes

RULES
- Show the plan and wait for "yes" before deleting.
- Delete only these four classes. Never touch AccountContextService
  or any other class.
- If the delete fails with a dependency on the agent, stop and tell me.
  The agent from Step 2 still exists.
- Run from my build project, never from this repo's code/ folder.

EXAMPLE OUTPUT
Found 4 classes: PriorityActionService, PriorityActionServiceTest,
AccountPriorityService, AccountPriorityServiceTest. Type "yes" to proceed.
[After yes]
Delete succeeded: 4 components. Verification: 0 demo classes remain.
```

**If it fails:** a dependency error names the agent or a planner bundle. Go back to Step 2 and make sure the agent is gone.

---

## Step 5: Delete the records the agent created

The agent's Tasks and Opportunities are the ones whose Id is in a priority's `Action_Record_Id__c` **and** whose Description starts with "From account priority". The seed's history priorities also link to Tasks and Opportunities, but those have other descriptions and are left alone here.

**Prompt 16C: Delete agent-created Tasks and Opportunities**

```
ROLE
You are a Salesforce developer cleaning up records an agent created during
a demo.

TASK
In org <alias>, find and delete the Tasks and Opportunities created by the
Priority Follow-Through agent.
1. Collect the Ids:
   SELECT Id, Name, Account__r.Name, Action_Record_Id__c FROM Account_Priority__c
   WHERE Account__r.Name LIKE 'DEMO %' AND Action_Record_Id__c != null
2. Query Tasks and Opportunities with those Ids, including Description.
3. Keep only records whose Description starts with "From account priority".
4. Show me a table: object, Id, Subject or Name, account, created by,
   created date, and the totals. Wait for me to type "yes".
5. After "yes", delete exactly those records with anonymous Apex
   (sf apex run --target-org <alias> --file <file>).
6. Verify: repeat steps 1 to 3. The result is 0 records.

EXPECTED OUTPUT
1. The table and totals
2. A pause for "yes"
3. Deleted counts per object
4. The verification result

RULES
- Show the plan and wait for "yes" before deleting.
- Description is a long text field: don't filter on it in SOQL. Query by
  Id, then check startsWith('From account priority') in code.
- Delete only records that pass both checks (Id in Action_Record_Id__c
  AND the Description prefix).
- Don't change the Account_Priority__c records in this step.
- Use normal delete, not hard delete or emptyRecycleBin.
- Every command uses --target-org <alias>.

EXAMPLE OUTPUT
Found 9 records created by the agent:
| Object | Subject or Name | Account | Created by | Created |
| Task | Offer site-level furniture review | DEMO Lakeshore Medical Group | Seller | YYYY-MM-DD |
| Opportunity | Lakeshore Medical Group - Propose managed print review | DEMO Lakeshore Medical Group | Seller | YYYY-MM-DD |
...
Totals: 7 Tasks, 2 Opportunities. Skipped 14 linked records (seed history).
Type "yes" to proceed.
[After yes]
Deleted: 7 Tasks, 2 Opportunities. Verification: 0 agent records remain.
```

**What to check:** the totals match what you expect from the sessions and tests, and the skipped count matches the seed history (up to 14 linked records).

---

## Step 6: The shared-object rule

Look at your result from [Before you start, check 2](#2-check-whether-the-account-brief-demo-is-in-this-org).

### If `AccountContextService` exists: stop here

The Account Brief demo uses `Account_Priority__c`, its 5 base fields and the DEMO accounts. **Keep them.** Keep the DEMO priorities and the 50-account data too.

What you can still do:
- **Remove `Priority_Admin`** (Prompt 16E, the permission set part only), unless someone still needs to read the 6 new fields.
- **Optional: delete the 6 new fields** the Account Brief demo doesn't use: `Status__c`, `Actioned_On__c`, `Action_Record_Id__c`, `Signal_Type__c`, `Propensity_Score__c`, `Estimated_Value__c`. Remove `Priority_Admin` first, since it references them. From your build project, after showing the list and getting a "yes":
  ```bash
  sf project delete source --json --metadata CustomField:Account_Priority__c.Status__c CustomField:Account_Priority__c.Actioned_On__c CustomField:Account_Priority__c.Action_Record_Id__c CustomField:Account_Priority__c.Signal_Type__c CustomField:Account_Priority__c.Propensity_Score__c CustomField:Account_Priority__c.Estimated_Value__c --target-org <alias>
  ```
  If the Account Brief demo was updated to filter on `Status__c`, check that it still works afterwards.

Then go to [Step 9](#step-9-verify).

### If it doesn't exist: continue with Step 7

---

## Step 7: Delete the DEMO data (only without the Account Brief demo)

**Prompt 16D: Delete DEMO priorities, child records, accounts and products**

```
ROLE
You are a Salesforce developer removing a demo's seed data from a sandbox.

TASK
In org <alias>, delete the data the demo seed created.
First confirm again that this returns 0 rows, and stop if it doesn't:
   SELECT Id FROM ApexClass WHERE Name = 'AccountContextService'

Then work out what to delete:
A. All Account_Priority__c where Account__r.Name LIKE 'DEMO %'.
B. The demo's accounts: Accounts where Name LIKE 'DEMO %' and whose
   Description starts with "DEMO account." (check in code, not in SOQL).
   List any DEMO account without that marker separately; those are not
   deleted.
C. For the accounts in B, their child records:
   OrderItems and Orders, Cases, Tasks, Opportunities, Contacts.
D. The accounts in B.
E. PricebookEntries for Products where Name LIKE 'DEMO %', then those
   Products.

Show me a count for every object in A to E, plus the unmarked DEMO accounts
you will leave. Wait for me to type "yes". Then delete in exactly this
order: A, then C (OrderItems, Orders, Cases, Tasks, Opportunities,
Contacts), then D, then E.

EXPECTED OUTPUT
1. A table: step, object, count to delete
2. The list of DEMO accounts without the marker (not deleted)
3. A pause for "yes"
4. A table: object, deleted, errors
5. Verification counts (all 0 for deleted objects)

RULES
- Show the plan and wait for "yes" before deleting anything.
- Priorities first: Account_Priority__c.Account__c is a Restrict lookup, so an
  account with priorities can't be deleted.
- Orders are Activated. An activated order can't be deleted: set Status to
  'Draft' first, then delete the OrderItems and Orders. If the org refuses,
  stop and tell me.
- Description is a long text field: don't filter on it in SOQL. Query by
  name, then check startsWith('DEMO account.') in code.
- Use anonymous Apex (sf apex run --target-org <alias> --file <file>). If a
  run hits a governor limit, run one object per execution.
- Use normal delete, not hard delete or emptyRecycleBin.
- If a Product can't be deleted because something still uses it, set
  IsActive = false instead and list it.
- Don't change the standard price book, users, or anything not named
  "DEMO ".
- Every command uses --target-org <alias>.

EXAMPLE OUTPUT
| Step | Object | To delete |
| A | Account_Priority__c | 92 |
| C | OrderItem | 1,140 |
| C | Order | 486 |
| C | Case | 48 |
| C | Task | 150 |
| C | Opportunity | 193 |
| C | Contact | 152 |
| D | Account | 50 |
| E | PricebookEntry | 6 |
| E | Product2 | 6 |
DEMO accounts without the marker (kept): none.
Type "yes" to proceed.
[After yes]
All deleted, 0 errors. Verification: 0 DEMO accounts, 0 DEMO products,
0 DEMO priorities.
```

**What to check:**
- The counts are in the range `validate.sh` showed: 50 accounts, about 150 or more contacts, 190 or more opportunities, 480 or more orders
- Zero errors
- The unmarked list is empty, or you know where those accounts came from

---

## Step 8: Delete the object and the admin permission set

**Prompt 16E: Delete Account_Priority__c and Priority_Admin**

```
ROLE
You are a Salesforce developer removing a demo's custom object.

TASK
In org <alias>:
1. Confirm AccountContextService doesn't exist and
   SELECT COUNT() FROM Account_Priority__c returns 0. If either check fails,
   stop.
2. List what will go: the Account_Priority__c object with its 11 fields, and
   the Priority_Admin permission set with its assignments:
   SELECT Id, Assignee.Username FROM PermissionSetAssignment
   WHERE PermissionSet.Name = 'Priority_Admin'
3. Show me the list. Wait for me to type "yes".
4. After "yes", from my build project:
   sf project delete source --json --metadata CustomObject:Account_Priority__c --target-org <alias>
   then delete each Priority_Admin assignment:
   sf data delete record --sobject PermissionSetAssignment --record-id <Id> --target-org <alias>
   then:
   sf project delete source --json --metadata PermissionSet:Priority_Admin --target-org <alias>
5. Verify:
   SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'Account_Priority__c'
   SELECT Name FROM PermissionSet WHERE Name = 'Priority_Admin'

EXPECTED OUTPUT
1. The list from step 2
2. A pause for "yes"
3. A table: component, result
4. The verification results

RULES
- Show the plan and wait for "yes" before deleting.
- If the object delete reports that a report, report type, list view or
  flow uses it, list them and stop. Don't delete those without asking me.
- If the object delete reports a dependency on Priority_Admin, delete the
  permission set first, then the object.
- Run from my build project, never from this repo's code/ folder.

EXAMPLE OUTPUT
Will delete: Account_Priority__c (11 fields), Priority_Admin (1 assignment:
admin@example.com). Type "yes" to proceed.
[After yes]
| Component | Result |
| CustomObject:Account_Priority__c | Deleted |
| Priority_Admin assignment | Deleted |
| PermissionSet:Priority_Admin | Deleted |
Verification: object not found, permission set not found.
```

A deleted custom object stays in Setup > Object Manager > **Deleted Objects** for a while and can be restored from there. Erase it there if you need the name or the limit back **(to confirm the retention period in this org)**.

---

## Step 9: Verify

Run each query. The expected result depends on Step 6.

```sql
-- Agent: 0 in both cases
SELECT COUNT() FROM BotDefinition WHERE DeveloperName = 'Priority_Followthrough'

-- Apex: 0 in both cases
SELECT Name FROM ApexClass WHERE Name IN ('AccountPriorityService','AccountPriorityServiceTest','PriorityActionService','PriorityActionServiceTest')

-- Permission sets: 0 in both cases
-- (1, Priority_Admin, if you kept it with the Account Brief demo)
SELECT Name FROM PermissionSet WHERE Name IN ('Priority_Admin','Priority_Agent_User','Priority_Agent_Access')

-- Without the Account Brief demo: 0
SELECT COUNT() FROM Account WHERE Name LIKE 'DEMO %'
SELECT COUNT() FROM Product2 WHERE Name LIKE 'DEMO %'
SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'Account_Priority__c'
```

With the Account Brief demo present, also re-run steps 1 to 3 of Prompt 16C: it should find 0 agent-created records.

Run each one with `sf data query --target-org <alias> -q "<query>"`.

**Check in Setup:**
- [ ] Agentforce Agents: no Priority Follow-Through
- [ ] Apex Classes: no `AccountPriorityService` or `PriorityActionService` classes
- [ ] Permission Sets: no `Priority_Agent_Access` or `Priority_Agent_User` (and no `Priority_Admin`, unless you kept it)
- [ ] Without the Account Brief demo: Object Manager has no Account Priority object

`seed-01` may have turned on the standard price book. It's left on; that's harmless.

---

## What you have now

- **Without the Account Brief demo:** the org has no trace of this demo: no agent, Apex, permission sets, DEMO records or priority object
- **With the Account Brief demo:** the agent, its Apex, its permission sets and the records it created are gone. The shared object, the DEMO accounts and their data stay for the Account Brief demo

To build it again, start from [Before the session](01-before-the-session.md), or run `./code/deploy.sh <alias> <seller-username>` from `code/`.

---

[Index](README.md) · [← Previous: Next steps](15-next-steps.md)
