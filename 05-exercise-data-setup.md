[Index](README.md) · [← Previous: Coworker, skill or agent](04-architecture-coworker-first.md) · [Next: Coworker first →](06-demo-coworker-default.md)

# 5. The data: tour the 50-account book

**Time:** 10 minutes  
**Tool:** Developer Console (Query Editor), or `sf data query --target-org <alias>`  
**Output:** the group knows what's in the book and why the agent's answers will match it

This is a tour, not a build. The admin loaded the data before the session ([page 2, Step 5](02-org-setup.md#step-5-load-the-50-account-book-data-only)). All data is fictional: every name starts with "DEMO" and every email ends in `.example`.

---

## How the data is built

### One profile row per account

Each seed script holds the same **profile table**: one line per account. Everything else (contacts, opportunities, orders, account priorities) is generated from that line.

```
'DEMO Lakeshore Medical Group|Healthcare|1800|Chicago|IL|Midwest|ENT|DECLINING|Y'
  name                       |industry  |employees|city|state|region|tier|health|seller's book
```

| Column | Drives |
|---|---|
| Industry | Contact titles, the product mix in orders, which category declines, which one is missing |
| Tier | Number of contacts, monthly spend, deal size |
| Health | Open, won and lost opportunities; how recent the last activity is; cases; the shape of 12 months of orders; which priority signals fire |
| Seller's book | Owner: `Y` = the test seller, `N` = the driver (the rest of the sales team) |
| Position in the table | Small, fixed variations between accounts of the same type |

So when a priority says "Furniture spend down 22% over 6 months", the order history shows it.

### Three rules

1. **Deterministic.** No random numbers. Every org gets the same data, so the test expectations hold.
2. **Add-only.** Each script fills only the DEMO accounts that don't have its records yet, matching accounts on name **and** billing city. Nothing is deleted. Safe to re-run.
3. **Top up, don't reset.** The agent uses up open priorities. Re-running `seed-04-priorities.apex` adds new Open priorities to any account below its starting count. It never edits or deletes existing priorities, or the Tasks and Opportunities the agent created. Those stay as follow-through history.

---

## What's in the book

**50 accounts.** The test seller owns **20** (their book, including the 5 test accounts). The driver owns the other 30.

### By segment

| Segment | Accounts | Example |
|---|---|---|
| Healthcare (clinics, dental, senior living, hospice) | 13 | DEMO Lakeshore Medical Group, DEMO Northfield Dental Partners |
| Education (K-12, private, college) | 9 | DEMO Pinecrest School District, DEMO St. Brigid Academy |
| Professional services (legal, accounting, insurance, finance, consulting) | 8 | DEMO Hale & Ostrander LLP, DEMO Brennan Tax Advisors |
| Manufacturing | 5 | DEMO Kessler Tool & Die |
| Government | 4 | DEMO Village of Cedar Ridge |
| Nonprofit and religious | 4 | DEMO Grace Fellowship Church |
| Logistics and wholesale | 4 | DEMO Ridgeway Logistics, DEMO Harbor Supply Co (Seattle and Tacoma) |
| Hospitality | 2 | DEMO Lakefront Suites Hotel |
| Real estate | 1 | DEMO Evergreen Property Management |

### By size

| Tier | Accounts | Employees | Monthly spend | Contacts each |
|---|---|---|---|---|
| Enterprise | 7 | 1,100–4,200 | $15k–$40k | 6–8 |
| Mid-market | 23 | 110–900 | $3k–$15k | 3–5 |
| Small | 20 | 22–95 | $300–$3k | 1–2 |

Three accounts with a Single Thread signal (Pinecrest, Grace Fellowship, Montclair Montessori) get exactly one contact, whatever their tier.

### By region

Midwest 18, Northeast 10, South 10, West 12. The seller's book is mostly Midwest (16 of 20).

### By health

| Health | Accounts | Seller's book | Orders, last 12 months | Last completed activity | Signals it produces |
|---|---|---|---|---|---|
| Growing | 10 | 4 | Up about 25% over the year | About 6 days ago | Expansion, Category Gap |
| Stable | 18 | 5 | Flat (within 4%) | About 25 days ago | Category Gap, Renewal, Managed Print |
| Declining | 9 (incl. Lakeshore) | 4 | First category down 22% over the last 6 months; an open high-priority case | About 45 days ago | Spend Decline, Service Risk |
| Lapsed | 5 | 2 | Orders stop three months ago | About 95 days ago | Reorder Lapsed |
| New | 5 (incl. Pinecrest) | 2 | Last 3 months only | About 9 days ago | Single Thread, Category Gap |
| Test edge cases | 3 (Ridgeway, Harbor ×2) | 3 | None | About 30 days ago | Fixed (see below) |

> **If the Account Brief demo shares this org,** its 5 test accounts keep their own contacts, opportunities, orders and cases. The book doesn't add to them. Only their owner, a missing billing state, and the account priorities change.

---

## The account priorities

- **57 open priorities** on **33 accounts**. The other 17 accounts have none, as in a real book.
- **29 of them** sit in the seller's 20 accounts, so "top 10 in my book" is a real choice.
- **20 history records** from earlier quarters: 14 Actioned (each linked to a completed Task or a won Opportunity) and 6 Dismissed. Plus Lakeshore's Actioned priority. A follow-through report has data on day one.

### The 8 signal types (`Signal_Type__c`)

| Signal | Reason (template) | Recommended action | Estimated value | Score | Open on a fresh load |
|---|---|---|---|---|---|
| Spend Decline | {Category} spend down 22% over 6 months | Offer a {category} review | About 6 months of the lost spend | 70–85 | 8 |
| Category Gap | Buys {A} but not {B} | Introduce {B} with a trial order | 20% of monthly spend × 12 | 50–65 | 16 |
| Reorder Lapsed | No order in {n} days | Check-in call to confirm the next order | Monthly spend × 3 | 65–80 | 5 |
| Renewal | Price agreement renews in {n} days | Book a renewal review | Monthly spend × 12 | 80–90 | 5 |
| Expansion | Headcount up 15% this year, or new location opening next quarter | Propose a furniture and supplies starter package | Monthly spend × 4 | 60–75 | 7 |
| Managed Print | Print spend above segment average | Propose a managed print review | 15% of an estimated year of print spend | 45–60 | 3 |
| Service Risk | Open high-priority case {n} days before renewal | Resolve the case, then book the renewal review | Monthly spend × 12 | 75–90 | 8 |
| Single Thread | Only one contact on file | Identify a second decision maker | 0 | 40–55 | 5 |

`Propensity_Score__c` (0 to 100) ranks priorities across the seller's book. `Estimated_Value__c` becomes the default amount when the follow-up is an Opportunity. Both stand in for what a real priority feed would provide.

### The 5 test accounts

These values are fixed. The tests on [page 12](12-exercise-test.md) depend on them.

| Account | Open priorities (rank: signal, reason, value, score) | Other | Used in tests |
|---|---|---|---|
| DEMO Lakeshore Medical Group (Chicago) | 1: Spend Decline, "Declining furniture spend at 3 sites", $36,000, 82<br>2: Managed Print, "Print volume flat", $8,600, 58<br>3: Service Risk, "Open delivery-delay case before renewal", $120,000, 88 | Priority 4 (Category Gap, $24,000) is **Actioned**, 14 days ago. The agent must not list it | 1, 2, 3, 6, 8, 9, 10 |
| DEMO Pinecrest School District (Portland) | 1: Single Thread, "Only one contact on file", $0, 47 | New account, 1 contact | 7 |
| DEMO Harbor Supply Co (Seattle) | 1: Reorder Lapsed, "No order in 104 days", $5,400, 72 | **Same name** as Tacoma | 4 |
| DEMO Harbor Supply Co (Tacoma) | 1: Expansion, "New warehouse opening next quarter", $9,500, 66 | **Same name** as Seattle | 4 |
| DEMO Ridgeway Logistics (Dallas) | None, on purpose | | 5 |

Their priority names are fixed too: "Lakeshore Priority 1" to "4", "Pinecrest Priority 1", "Harbor Seattle Priority 1", "Harbor Tacoma Priority 1". Priorities added by a top-up get a new name ("{account} {signal} #{rank}").

---

## Walk through 3 accounts

Open the Developer Console > **Query Editor** tab. Paste each query, click **Execute**.

### 1. A growing account: DEMO Prairie View Senior Living

```sql
SELECT EffectiveDate, TotalAmount
FROM Order
WHERE Account.Name = 'DEMO Prairie View Senior Living'
ORDER BY EffectiveDate
```

**Look for:** 12 orders, one a month. The amount climbs steadily, from about $6,000 a year ago to about $7,500 last month. That growth is why its priorities are **Expansion** ("Headcount up 15% this year") and **Category Gap** ("Buys furniture but not technology accessories").

### 2. A declining account: DEMO Lakeshore Medical Group

```sql
SELECT Order.EffectiveDate, Product2.Name, UnitPrice
FROM OrderItem
WHERE Order.Account.Name = 'DEMO Lakeshore Medical Group'
AND Product2.Name = 'DEMO Furniture'
ORDER BY Order.EffectiveDate
```

**Look for:** 12 furniture lines. Furniture is flat at $6,000 for the older 6 months, then drops each month to $4,680 (down 22%). That's **Lakeshore Priority 1**: "Declining furniture spend at 3 sites".

> **If the Account Brief demo shares this org,** Lakeshore keeps that demo's own orders, which this seed doesn't change, and they don't show this decline. Use **DEMO Kessler Tool & Die** as the declining example instead: change the account name in the query and set `Product2.Name = 'DEMO Janitorial'`. Janitorial is flat at $5,250, then drops to $4,095. Its priorities are Spend Decline ("Janitorial supplies spend down 22% over 6 months") and Service Risk.

### 3. A lapsed account: DEMO Oak Park Pediatrics

```sql
SELECT EffectiveDate, TotalAmount
FROM Order
WHERE Account.Name = 'DEMO Oak Park Pediatrics'
ORDER BY EffectiveDate
```

**Look for:** 10 orders of $1,650 each, then **nothing for the last two months**. The newest order is from three months ago. That gap is its one priority: **Reorder Lapsed**, "No order in 104 days", worth $4,950 (3 months of spend).

### Then: see the priorities for all three

```sql
SELECT Account__r.Name, Name, Signal_Type__c, Priority_Reason__c,
       Recommended_Action__c, Estimated_Value__c, Propensity_Score__c, Status__c
FROM Account_Priority__c
WHERE Account__r.Name IN ('DEMO Prairie View Senior Living',
                          'DEMO Lakeshore Medical Group',
                          'DEMO Oak Park Pediatrics')
ORDER BY Account__r.Name, Priority_Rank__c
```

**Look for:** 7 rows on a fresh load. Lakeshore has 4: three **Open** and one **Actioned**. The agent must only offer the three Open ones.

---

## What to check

Run the health check from `code/`:

```bash
./validate.sh <alias> <seller-username>
```

| Check | Want |
|---|---|
| DEMO accounts | 50 or more |
| DEMO contacts | 150 or more |
| DEMO opportunities | 190 or more |
| DEMO orders | 480 or more |
| Open DEMO priorities | 57 or more |
| Actioned or Dismissed (history) | 21 or more |
| DEMO Lakeshore Medical Group (Chicago) open priorities | exactly 3 |
| DEMO Pinecrest School District (Portland) | exactly 1 |
| DEMO Harbor Supply Co (Seattle) | exactly 1 |
| DEMO Harbor Supply Co (Tacoma) | exactly 1 |
| DEMO Ridgeway Logistics (Dallas) | exactly 0 |
| Accounts owned (seller book) | 20 |

At this point in the day, the Apex class, `Priority_Agent_User` and `Priority_Agent_Access` lines show FAIL. That's expected: the group builds them on pages 8 and 11.

To count the seller's open priorities (29 on a fresh load), run this in the Query Editor:

```sql
SELECT COUNT() FROM Account_Priority__c
WHERE Status__c = 'Open' AND Account__r.Owner.Username = '<seller-username>'
```

**If a test account count is off:** a rehearsal used up a priority. Top up: `./deploy.sh <alias> --top-up` from `code/`, then run `validate.sh` again.

---

## What you have now

- A 50-account book where every priority matches the account's history
- 20 accounts in the seller's book, with 29 open priorities to choose from
- 5 test accounts with fixed values the tests depend on
- A way to refresh open priorities without deleting anything

**Next:** [6. Coworker first](06-demo-coworker-default.md)

---

[Index](README.md) · [← Previous: Coworker, skill or agent](04-architecture-coworker-first.md) · [Next: Coworker first →](06-demo-coworker-default.md)
