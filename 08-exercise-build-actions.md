[Index](README.md) · [← Previous: Exercise 1: Design the agent](07-exercise-design-agent.md) · [Next: Exercise 3: Write the Agent Script →](09-exercise-write-agent-script.md)

# Exercise 2: Build the actions

**Time:** 50 minutes (8A and 8B before lunch, 8C and 8D after)  
**Tool:** Agentforce Vibes or Claude Code with the Salesforce DX MCP server, in the `priority-agent` project ([page 2](02-org-setup.md#step-1-do-the-shared-org-setup))  
**Output:** two Apex actions deployed with passing tests, and the seller's permission set assigned

The agent's two actions are Apex invocable methods. The agent never reads or writes Salesforce data itself: it calls these.

| Prompt | Builds | Agent action | Time |
|---|---|---|---|
| 8A | Checks the `Account_Priority__c` object has its 11 fields | | 5 min |
| 8B | `AccountPriorityService` + test | `Get Account Priorities` (read) | 20 min |
| 8C | `PriorityActionService` + test | `Log Priority Action` (write) | 15 min |
| 8D | Deploys both with tests; `Priority_Agent_User` permission set | | 10 min |

> **Fallback available.** The finished, tested classes are in `code/`. If a step takes more than 10 minutes to fix, use the [Fallback](#fallback) at the end of this page and move on.

**Before you start:** the driver has `Priority_Admin` (assigned in pre-work). The Apex tests write the new priority fields in user mode and fail without it.

---

## Prompt 8A: Check the priority object

The object and its fields were deployed in pre-work. This prompt checks them against the spec and creates only what's missing.

```
ROLE
You are a Salesforce developer working in my org through the Salesforce
DX tools. My org alias is <alias>.

TASK
1. Retrieve the custom object Account_Priority__c and its fields from the org
   into force-app.
2. Compare it with the spec below. Report each field as MATCH, DIFFERENT
   or MISSING.
3. For each MISSING field, create the field metadata exactly as specified.
4. Show me the list of components you would deploy, and wait for my
   approval before deploying anything.

Object: Account_Priority__c
- Label "Account Priority", plural "Account Priorities"
- Name field: label "Priority Name", type Text
- Sharing model ReadWrite. Activities, reports and search enabled

Fields (11):
Base fields (also used by the Account Brief demo):
1. Account__c: Lookup(Account), required, delete constraint Restrict,
   relationship name Account_Priorities, relationship label "Account Priorities"
2. Priority_Rank__c: Number, precision 18, scale 0
3. Priority_Reason__c: Text(255)
4. Recommended_Action__c: Text(255)
5. Refreshed_On__c: Date
New fields for the agent:
6. Status__c: Picklist, restricted, values in this order: Open (default),
   Actioned, Dismissed
7. Actioned_On__c: Date. Description "Date the seller acted on the
   priority."
8. Action_Record_Id__c: Text(18), not unique. Description "Id of the Task
   or Opportunity created from this priority. Links recommendation to
   outcome."
9. Signal_Type__c: Picklist, restricted, no default, values in this
   order: Spend Decline, Category Gap, Reorder Lapsed, Renewal, Expansion,
   Managed Print, Service Risk, Single Thread
10. Propensity_Score__c: Number, precision 3, scale 0. Description "0 to
    100. Ranks priorities across a seller's book. Stand-in for a real
    propensity-to-buy signal."
11. Estimated_Value__c: Currency, precision 16, scale 2. Description
    "Estimated revenue if the priority is acted on. Default amount when
    the follow-up is an Opportunity."

EXPECTED OUTPUT
1. A table: field, expected type, org type, MATCH / DIFFERENT / MISSING
2. If anything is MISSING: the component list to deploy, then stop and
   wait for my approval
3. After I approve: the deploy result (component, type, status)
4. One-line summary

RULES
- Use --target-org <alias> on every sf command
- Use the exact API names, types, lengths and picklist values above
- Never change a field that already exists. If a field is DIFFERENT,
  report it and stop. Don't fix it
- Don't delete anything. Don't create records
- If every field is MATCH, deploy nothing and say so

EXAMPLE OUTPUT
| Field | Expected | In org | Result |
| Account__c | Lookup(Account), Restrict | Lookup(Account), Restrict | MATCH |
| Status__c | Picklist: Open*, Actioned, Dismissed | same | MATCH |
...
All 11 fields match. Nothing to deploy.
```

**What to check:**
- 11 fields, all **MATCH** (pre-work deployed them)
- `Status__c` default is **Open**
- `Signal_Type__c` has all **8** values
- Nothing was deployed, unless a field was MISSING and you approved it

**If it fails:**
- **A field is MISSING:** approve the deploy. Then re-deploy the admin permission set from `code/`, because new fields get no field-level security: `sf project deploy start --target-org <alias> --metadata PermissionSet:Priority_Admin`
- **A field is DIFFERENT:** stop. Another project created a field with the same name. Don't change it in a shared org; ask the facilitator
- **Retrieve finds nothing:** the pre-work data load didn't run. See [page 2, Step 5](02-org-setup.md#step-5-load-the-50-account-book-data-only)

---

## Prompt 8B: Build `Get Account Priorities`

```
ROLE
You are a Salesforce Apex developer building an invocable action for an
Agentforce employee agent. My org alias is <alias>.

TASK
Create the Apex class AccountPriorityService and its test class
AccountPriorityServiceTest in force-app/main/default/classes, with
API version 68.0 meta files.

1. CLASS
   - public with sharing class AccountPriorityService
   - Constants (@TestVisible private static final):
     MAX_BOOK_PRIORITIES = 10, STATUS_OPEN = 'Open'
   - @InvocableMethod(label='Get Account Priorities',
       description='Returns open account priorities for one account, or the
       top open priorities across the book of the seller',
       category='Sales Assistant')
     public static List<Response> getPriorities(List<Request> requests)
     One Response per Request, in order.

2. REQUEST (inner class Request, both @InvocableVariable, not required)
   - recordId (String), label 'Record ID': Account, Contact or
     Opportunity Id. Blank for the seller's whole book
   - accountName (String), label 'Account Name': exact or partial name.
     Blank for the seller's whole book

3. RESPONSE (inner class Response, all @InvocableVariable)
   - isSuccess (Boolean), label 'Success'
   - errorType (String), label 'Error Type': ACCOUNT_NOT_FOUND or
     ACCOUNT_AMBIGUOUS when isSuccess is false
   - errorMessage (String), label 'Error Message'
   - scope (String), label 'Scope': ACCOUNT or BOOK
   - accountId (String), label 'Account ID': when scope is ACCOUNT
   - resolvedAccountName (String), label 'Account Name': when scope is
     ACCOUNT
   - priorityCount (Integer), label 'Priority Count'
   - prioritiesJson (String), label 'Priorities JSON'
   - today (String), label 'Today': Date.today() as YYYY-MM-DD, set on
     EVERY response, including errors

4. BEHAVIOUR
   a. Both inputs blank (null or whitespace) → BOOK scope:
      open priorities on accounts the running user owns
      (Account__r.OwnerId = UserInfo.getUserId()),
      ORDER BY Propensity_Score__c DESC NULLS LAST,
               Priority_Rank__c ASC NULLS LAST,
      LIMIT MAX_BOOK_PRIORITIES. isSuccess = true, scope = 'BOOK'.
   b. recordId set (it wins over accountName). Trim it, then Id.valueOf:
      - not a valid Id → ACCOUNT_NOT_FOUND
      - Account Id → that account
      - Contact Id → the Contact's AccountId
      - Opportunity Id → the Opportunity's AccountId
      - any other object, or no parent account → ACCOUNT_NOT_FOUND
      Then read the Account (Id, Name, BillingCity, BillingState).
   c. accountName set. Trim it, then:
      - exact match first: Name = :name, ORDER BY BillingCity, LIMIT 10
      - if none: Name LIKE :pattern with pattern '%' + name + '%',
        ORDER BY Name, BillingCity, LIMIT 10
   d. Resolution result:
      - 0 accounts → isSuccess false, errorType 'ACCOUNT_NOT_FOUND',
        errorMessage 'No account matches that name or record.',
        priorityCount 0
      - 2+ accounts → isSuccess false, errorType 'ACCOUNT_AMBIGUOUS',
        errorMessage '<n> accounts share that name.', priorityCount 0,
        prioritiesJson {"candidates":[{id, name, billingCity,
        billingState}]}
      - 1 account → ACCOUNT scope: that account's open priorities,
        ORDER BY Priority_Rank__c ASC NULLS LAST,
                 Propensity_Score__c DESC NULLS LAST.
        isSuccess true, scope 'ACCOUNT', accountId, resolvedAccountName
   e. Open only: Status__c = 'Open' in both scopes.
   f. Success JSON: {"priorities":[{id, accountId, accountName,
      accountCity, rank, reason, recommendedAction, signalType, score,
      estimatedValue, refreshedOn}]} mapped from Id, Account__c,
      Account__r.Name, Account__r.BillingCity, Priority_Rank__c,
      Priority_Reason__c, Recommended_Action__c, Signal_Type__c,
      Propensity_Score__c, Estimated_Value__c, Refreshed_On__c.
      priorityCount = number of priorities.

5. TEST CLASS AccountPriorityServiceTest (@IsTest, @TestSetup)
   Setup: accounts "TEST Solo Clinic" (Chicago), "TEST Twin Supply"
   (Seattle), "TEST Twin Supply" (Tacoma), "TEST Empty Logistics"
   (Dallas). A Contact and an Opportunity on Solo (read the stage from
   OpportunityStage: first active, not closed, by SortOrder).
   Priorities: Solo P1 rank 1 Open score 70; Solo P2 rank 2 Open
   score 85; Solo P3 rank 3 Actioned score 99; Twin A P1 rank 1 Open
   score 60.
   Tests:
   - byName_returnsOnlyOpenPrioritiesInRankOrder: 2 priorities, rank 1
     first, scope ACCOUNT, today set
   - byPartialName_resolvesSingleMatch: "Solo Clin" finds Solo
   - byAccountId_resolves
   - byContactAndOpportunityId_resolveToParentAccount
   - duplicateName_returnsAmbiguousWithCandidates: 2 candidates
   - unknownName_returnsNotFound
   - invalidRecordId_returnsNotFound: recordId 'not-an-id'
   - accountWithNoPriorities_returnsZero: Empty Logistics, success, 0
   - blankInputs_returnBookSortedByScope: recordId '' and accountName
     '  ' → scope BOOK, 3 priorities, first has score 85
   - book_excludesAccountsOwnedByOthers: move Solo to another user →
     1 priority left. Create that user with the 'Standard User' profile
     inside System.runAs(new User(Id = UserInfo.getUserId())) to avoid
     MIXED_DML_OPERATION

EXPECTED OUTPUT
1. Files: AccountPriorityService.cls, AccountPriorityServiceTest.cls
   and their -meta.xml files
2. A table of the Response fields: name, type, when it's set
3. One-line summary. Don't deploy yet

RULES
- WITH USER_MODE on every SOQL query, so sharing and field access apply
- Bind variables only. Don't use String.escapeSingleQuotes on the name:
  it breaks names with apostrophes, and binds are already safe
- Never return ACCOUNT_REQUIRED: blank inputs mean the seller's book
- Use the exact class, method, variable and label names above
- Tests use Assert.isTrue / Assert.areEqual, not System.assert
- Write the code from this spec. Don't copy it from other projects on
  this machine

EXAMPLE OUTPUT
Created AccountPriorityService (about 200 lines) and
AccountPriorityServiceTest (10 tests). Not deployed.
```

**What to check:**
- `public with sharing`, and `WITH USER_MODE` on every query
- Blank inputs return `scope = 'BOOK'`, not an error
- Book: ordered by `Propensity_Score__c` first, `LIMIT 10`, owner is the running user
- Account: ordered by `Priority_Rank__c` first
- `today` is set on every response, including errors
- The ambiguous case puts **candidates** in `prioritiesJson`
- 10 test methods

**Checkpoint before lunch:** deploy this class and its test on their own.

```bash
sf project deploy start --target-org <alias> \
  --metadata ApexClass:AccountPriorityService ApexClass:AccountPriorityServiceTest \
  --test-level RunSpecifiedTests --tests AccountPriorityServiceTest --wait 15
```

**If it fails:**
- **`No such column 'Status__c'`** (or another priority field): the field is missing or the driver has no access to it. Re-run 8A, then check `Priority_Admin` is assigned to the driver
- **`book_excludesAccountsOwnedByOthers` fails with `List has no rows for assignment`:** the org has no profile named `Standard User`. Change the test to a non-admin profile that exists in the org
- **`MIXED_DML_OPERATION`:** the test inserts the user and updates the account in the same context. Put the user insert inside `System.runAs`
- **`blankInputs_...` returns more than 3:** the test can see org data. Remove `SeeAllData=true`
- **A test fails on an Account or Opportunity insert:** a validation rule in the org. Read the message and add the required field to the test data

---

## Prompt 8C: Build `Log Priority Action`

```
ROLE
You are a Salesforce Apex developer building the write action for an
Agentforce employee agent. The agent only reaches this action after the
seller confirms. My org alias is <alias>.

TASK
Create the Apex class PriorityActionService and its test class
PriorityActionServiceTest in force-app/main/default/classes, with
API version 68.0 meta files.

1. CLASS
   - public with sharing class PriorityActionService
   - Constants (@TestVisible private static final):
     TYPE_TASK = 'Task', TYPE_OPPORTUNITY = 'Opportunity',
     DEFAULT_TASK_DAYS = 7, DEFAULT_CLOSE_DAYS = 30
   - @InvocableMethod(label='Log Priority Action',
       description='Creates a Task or Opportunity from one open account
       priority and marks the priority Actioned',
       category='Sales Assistant')
     public static List<Response> logAction(List<Request> requests)
     One Response per Request; each Request has its own savepoint.

2. REQUEST (inner class Request, all @InvocableVariable)
   - priorityId (String), label 'Priority ID', required=true
   - actionType (String), label 'Action Type': Task or Opportunity
   - subject (String), label 'Subject': Task subject or Opportunity name.
     Defaults to the recommended action
   - dueDate (String), label 'Due Date': YYYY-MM-DD. Defaults to 7 days
     out for a Task, 30 for an Opportunity
   - amount (Decimal), label 'Amount': 0 or blank uses the priority's
     estimated value

3. RESPONSE (inner class Response, all @InvocableVariable)
   - isSuccess (Boolean), label 'Success'
   - errorType (String), label 'Error Type': PRIORITY_NOT_FOUND,
     PRIORITY_NOT_OPEN, INVALID_ACTION_TYPE, INVALID_DATE or SAVE_FAILED
   - message (String), label 'Message': what happened, in plain language
   - recordId (String), label 'Record ID'
   - recordType (String), label 'Record Type': Task or Opportunity
   - recordName (String), label 'Record Name': Task subject or
     Opportunity name

4. CHECKS, in this order. Each failure returns isSuccess false and
   writes nothing
   a. actionType: blank or "task" (any case) → Task; "opportunity" or
      "opp" (any case) → Opportunity; anything else →
      INVALID_ACTION_TYPE, 'Action type must be Task or Opportunity.'
   b. dueDate, if not blank: Date.valueOf(trimmed value).
      Doesn't parse → INVALID_DATE, 'The date must be in YYYY-MM-DD
      format.' Before today → INVALID_DATE, 'The date can't be in the
      past.'
   c. priorityId: Id.valueOf fails → PRIORITY_NOT_FOUND, 'That priority
      doesn't exist or you don't have access to it.'
   d. Query the priority (Id, Name, Status__c, Account__c,
      Account__r.Name, Priority_Reason__c, Recommended_Action__c,
      Estimated_Value__c) WITH USER_MODE, LIMIT 1, FOR UPDATE.
      No row → PRIORITY_NOT_FOUND (same message).
   e. Status__c is not 'Open' → PRIORITY_NOT_OPEN,
      'That priority is already <Status__c>.'

5. WRITE (one transaction)
   - Database.setSavepoint() before any DML
   - Task: WhatId = priority's account, OwnerId = running user,
     Subject = subject (first 255 chars) or Recommended_Action__c,
     ActivityDate = dueDate or today + DEFAULT_TASK_DAYS,
     Status = the org's default TaskStatus
       (SELECT ApiName FROM TaskStatus WHERE IsDefault = true LIMIT 1),
     Priority = 'Normal',
     Description = 'From account priority <Name>: <Priority_Reason__c>'
   - Opportunity: AccountId = priority's account, OwnerId = running user,
     Name = subject, or the account name with a leading "DEMO " removed
       + ' - ' + Recommended_Action__c; first 120 chars,
     StageName = the org's first open stage
       (SELECT ApiName FROM OpportunityStage WHERE IsActive = true
        AND IsClosed = false ORDER BY SortOrder ASC LIMIT 1),
     CloseDate = dueDate or today + DEFAULT_CLOSE_DAYS,
     Amount = amount if it is greater than 0, else Estimated_Value__c,
     Description as for the Task
   - insert as user the new record
   - Mark the priority: Status__c = 'Actioned',
     Actioned_On__c = today, Action_Record_Id__c = new record Id;
     update as user
   - Success: isSuccess true, recordId, recordType, recordName (Subject
     or Name), message '<Task|Opportunity> created for <account name>.
     Priority marked Actioned.'
   - Any exception: Database.rollback(savepoint), SAVE_FAILED with the
     exception message

6. TEST CLASS PriorityActionServiceTest (@IsTest, @TestSetup)
   Setup: account "DEMO Test Clinic" (Chicago). Priority "TEST Open":
   Open, rank 1, reason 'Furniture spend down 22%', action 'Offer a
   furniture review', estimated value 18000. Priority "TEST Done":
   Actioned, rank 2.
   Tests:
   - task_createsTaskAndActionsPriority: subject, date in 3 days,
     WhatId = account, Status not null; priority Actioned, Actioned_On__c
     today, Action_Record_Id__c = the Task Id
   - task_defaultsSubjectAndDueDate: all blank → subject 'Offer a
     furniture review', due today + 7
   - opportunity_usesEstimatedValueAndFirstOpenStage: type 'opportunity',
     amount 0 → Amount 18000, not closed, close today + 30, Name
     'Test Clinic - Offer a furniture review'
   - opportunity_usesSellerAmount: amount 25000 → Amount 25000
   - secondCall_isRejected_noDuplicate: second call → PRIORITY_NOT_OPEN,
     still exactly 1 Task on the account
   - actionedPriority_isRejected: TEST Done → PRIORITY_NOT_OPEN
   - badInputs_returnErrorsWithoutWriting: 'Email' → INVALID_ACTION_TYPE;
     'next friday' → INVALID_DATE; yesterday → INVALID_DATE;
     'not-an-id' → PRIORITY_NOT_FOUND; 0 Tasks; priority still Open
   - deletedPriority_returnsNotFound

EXPECTED OUTPUT
1. Files: PriorityActionService.cls, PriorityActionServiceTest.cls and
   their -meta.xml files
2. A table of the error codes: code, when, message
3. One-line summary. Don't deploy yet

RULES
- WITH USER_MODE on the priority query. insert as user and update as
  user for every write
- Never hard-code "Prospecting" or "Not Started": stage and status
  names differ between orgs, so read them as above
- The new record and the priority update succeed or fail together
- Use the exact class, method, variable, label and error code names
- Tests use Assert.isTrue / Assert.areEqual, not System.assert
- Write the code from this spec. Don't copy it from other projects on
  this machine

EXAMPLE OUTPUT
Created PriorityActionService (about 185 lines) and
PriorityActionServiceTest (8 tests). Not deployed.
```

**What to check:**
- Input checks run **before** any query or write, in the order a to e
- `FOR UPDATE` on the priority query, and the `Status__c != 'Open'` check after it
- One savepoint; rollback on any exception
- Stage and Task status read from `OpportunityStage` and `TaskStatus`, not typed in
- Amount: the seller's amount if it's greater than 0, else `Estimated_Value__c`
- The default Opportunity name drops "DEMO "
- The priority gets all three: `Status__c = 'Actioned'`, `Actioned_On__c`, `Action_Record_Id__c`
- 8 test methods

**If it fails:**
- **Tests fail with `SAVE_FAILED` and a validation rule message:** a rule in the org blocks the test Task or Opportunity. The assertion message shows the rule. Add the field it needs to the record the class builds, or ask the org's admin about the rule
- **`Status` is null on the Task:** the org has no default Task status. Set one in Setup > Object Manager > Task > Fields > Status
- **`Variable does not exist: Status__c`:** the field is missing. Re-run 8A

---

## Prompt 8D: Deploy, test, and give the seller access

```
ROLE
You are a Salesforce developer deploying Apex and a permission set.
My org alias is <alias>.

TASK
1. Deploy AccountPriorityService, AccountPriorityServiceTest,
   PriorityActionService and PriorityActionServiceTest together, running
   only their two test classes:
   sf project deploy start --target-org <alias>
     --metadata ApexClass:AccountPriorityService
                ApexClass:AccountPriorityServiceTest
                ApexClass:PriorityActionService
                ApexClass:PriorityActionServiceTest
     --test-level RunSpecifiedTests
     --tests AccountPriorityServiceTest PriorityActionServiceTest
     --wait 15
2. Show the test results and coverage per class.
3. Create the permission set Priority_Agent_User in
   force-app/main/default/permissionsets:
   - Label "Priority Agent User", hasActivationRequired false
   - Description: "Data and action access for the Priority
     Follow-Through agent: the two Apex actions, read and update on account
     priorities, create on Tasks and Opportunities. Agent visibility is
     granted separately by Priority_Agent_Access after the agent is
     published."
   - User permission EditTask (Tasks have no object permission)
   - Apex class access: AccountPriorityService, PriorityActionService
   - Account_Priority__c: read and edit. No create, delete, view all or
     modify all
   - Field access, read only: Priority_Rank__c, Priority_Reason__c,
     Recommended_Action__c, Refreshed_On__c, Signal_Type__c,
     Propensity_Score__c, Estimated_Value__c
   - Field access, read and edit: Status__c, Actioned_On__c,
     Action_Record_Id__c
   - No entry for Account__c (it's required, so it can't be listed)
   - Account: read. Contact: read. Opportunity: read, create, edit
4. Show me the permission set XML and wait for my approval.
5. After I approve, deploy it and assign it to the test seller:
   sf project deploy start --target-org <alias>
     --metadata PermissionSet:Priority_Agent_User --wait 10
   sf org assign permset --target-org <alias>
     --name Priority_Agent_User --on-behalf-of <seller-username>

EXPECTED OUTPUT
1. Deploy result: 4 classes, tests X/X pass, coverage per class
2. The permission set XML, then wait
3. After approval: deploy result and assignment result
4. One-line summary

RULES
- Use --target-org <alias> on every sf command
- Deploy the classes before the permission set (it references them)
- Don't give the seller Priority_Admin, and don't add agent access to
  this permission set
- Don't create Priority_Agent_Access yet

EXAMPLE OUTPUT
Deploy succeeded: 4 Apex classes. Tests 18/18 pass.
Coverage: AccountPriorityService 9x%, PriorityActionService 9x%.
Priority_Agent_User deployed and assigned to seller@example.com.
```

**What to check:**
- Deploy succeeds; **18 tests pass** (10 + 8)
- Each class has at least 75% coverage
- The permission set has 2 class accesses, `EditTask`, and **no** `agentAccesses` block
- `Status__c`, `Actioned_On__c` and `Action_Record_Id__c` are the only editable priority fields
- Run `./validate.sh <alias> <seller-username>` from `code/`: **Apex classes (2 + 2 tests)** OK, **Permission sets** OK, **Priority_Agent_User assigned** OK. `Priority_Agent_Access` still shows FAIL; that's expected

**Optional smoke test (read-only).** Developer Console > Debug > **Open Execute Anonymous Window**:

```apex
AccountPriorityService.Request req = new AccountPriorityService.Request();
req.accountName = 'DEMO Lakeshore Medical Group';
AccountPriorityService.Response res =
    AccountPriorityService.getPriorities(new List<AccountPriorityService.Request>{ req })[0];
System.debug(res.isSuccess + ' ' + res.scope + ' ' + res.priorityCount);
System.debug(res.prioritiesJson);
```

**Expect:** `true ACCOUNT 3`, and the JSON starts with rank 1, "Declining furniture spend at 3 sites". Don't call `PriorityActionService` here: it would action a real priority.

**If it fails:**
- **`Average test coverage ... at least 75%`:** a class isn't covered enough by its test. Add tests for the uncovered branches the result lists
- **A test fails here but passed before lunch:** something changed in the org (a new validation rule, or the driver lost `Priority_Admin`). Read the failure, fix, redeploy
- **Permission set deploy: `no ApexClass named ... found`:** the classes didn't deploy. Fix step 1 first
- **Permission set deploy fails on `Account__c`:** required fields can't have field permissions. Remove that entry
- **Assign fails: user not found:** check the username in Setup > Users

### Why `Priority_Agent_Access` waits until page 11

Seller access is split into two permission sets:

| Permission set | Gives | When |
|---|---|---|
| `Priority_Agent_User` | The two Apex actions, priority field access, Task and Opportunity create | Now |
| `Priority_Agent_Access` | Visibility of the `Priority_Followthrough` agent | [Page 11](11-exercise-publish-and-connect.md), after publish |

`Priority_Agent_Access` points at the agent by name. Until the agent is published, there's nothing to point at, and the deploy fails.

---

## Fallback

> **If the live build is stuck,** deploy the finished classes and run their tests, from `code/`:
>
> ```bash
> cd code
> sf project deploy start --target-org <alias> --metadata ApexClass:AccountPriorityService ApexClass:AccountPriorityServiceTest ApexClass:PriorityActionService ApexClass:PriorityActionServiceTest --test-level RunSpecifiedTests --tests AccountPriorityServiceTest PriorityActionServiceTest
> ```
>
> Then the seller's permission set:
>
> ```bash
> sf project deploy start --target-org <alias> --metadata PermissionSet:Priority_Agent_User
> sf org assign permset --target-org <alias> --name Priority_Agent_User --on-behalf-of <seller-username>
> ```
>
> To keep working in `priority-agent` afterwards, retrieve them: `sf project retrieve start --target-org <alias> --metadata ApexClass:AccountPriorityService ApexClass:AccountPriorityServiceTest ApexClass:PriorityActionService ApexClass:PriorityActionServiceTest PermissionSet:Priority_Agent_User`

---

## What you have now

- `Account_Priority__c` checked: 11 fields, matching the spec
- `AccountPriorityService` (**Get Account Priorities**): one account or the seller's book, Open only, user mode
- `PriorityActionService` (**Log Priority Action**): Task or Opportunity, Open only, once per priority, one transaction
- 18 passing tests
- `Priority_Agent_User` assigned to the test seller

**Next:** [Exercise 3: Write the Agent Script](09-exercise-write-agent-script.md)

---

[Index](README.md) · [← Previous: Exercise 1: Design the agent](07-exercise-design-agent.md) · [Next: Exercise 3: Write the Agent Script →](09-exercise-write-agent-script.md)
