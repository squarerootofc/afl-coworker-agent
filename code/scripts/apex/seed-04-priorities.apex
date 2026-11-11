// Seed 04 of 04: account priorities and follow-through history for the 50-account book.
// Also the TOP-UP script: re-run it before each rehearsal or test pass. It adds new Open
// priorities to any account below its baseline count and never edits or deletes existing ones,
// so priorities the agent actioned (and the Tasks/Opportunities it created) stay as history.
// Run after seed-03-orders.apex.

Date today = Date.today();

// Same profile table as seed-01 (name | industry | employees | city | state | region | tier | health | book).
List<String> PROFILES = new List<String>{
    'DEMO Lakeshore Medical Group|Healthcare|1800|Chicago|IL|Midwest|ENT|DECLINING|Y',
    'DEMO Pinecrest School District|Education|320|Portland|OR|West|MID|NEW|Y',
    'DEMO Harbor Supply Co|Wholesale|45|Seattle|WA|West|SMB|EDGE|Y',
    'DEMO Harbor Supply Co|Wholesale|38|Tacoma|WA|West|SMB|EDGE|Y',
    'DEMO Ridgeway Logistics|Transportation|650|Dallas|TX|South|MID|EDGE|Y',
    'DEMO Northfield Dental Partners|Healthcare|85|Evanston|IL|Midwest|SMB|STABLE|Y',
    'DEMO Prairie View Senior Living|Healthcare|420|Naperville|IL|Midwest|MID|GROWING|Y',
    'DEMO Oak Park Pediatrics|Healthcare|60|Oak Park|IL|Midwest|SMB|LAPSED|Y',
    'DEMO St. Brigid Academy|Education|140|Milwaukee|WI|Midwest|MID|STABLE|Y',
    'DEMO Fox Valley Community College|Education|1200|Elgin|IL|Midwest|ENT|GROWING|Y',
    'DEMO Hale & Ostrander LLP|Legal|210|Chicago|IL|Midwest|MID|DECLINING|Y',
    'DEMO Brennan Tax Advisors|Accounting|35|Schaumburg|IL|Midwest|SMB|STABLE|Y',
    'DEMO Village of Cedar Ridge|Government|260|Cedar Ridge|IN|Midwest|MID|STABLE|Y',
    'DEMO Grace Fellowship Church|Nonprofit|28|Joliet|IL|Midwest|SMB|NEW|Y',
    'DEMO Kessler Tool & Die|Manufacturing|380|Rockford|IL|Midwest|MID|DECLINING|Y',
    'DEMO Lakefront Suites Hotel|Hospitality|190|Chicago|IL|Midwest|MID|GROWING|Y',
    'DEMO Westbrook Family Clinic|Healthcare|48|Oakbrook|IL|Midwest|SMB|GROWING|Y',
    'DEMO Summit Insurance Group|Insurance|540|Columbus|OH|Midwest|MID|STABLE|Y',
    'DEMO Riverbend Unified Schools|Education|2600|Grand Rapids|MI|Midwest|ENT|DECLINING|Y',
    'DEMO Maple Grove Animal Hospital|Healthcare|32|Maple Grove|MN|Midwest|SMB|LAPSED|Y',
    'DEMO Beacon Hill Orthopedics|Healthcare|310|Boston|MA|Northeast|MID|STABLE|N',
    'DEMO Hudson Valley Hospice|Healthcare|150|Poughkeepsie|NY|Northeast|MID|DECLINING|N',
    'DEMO Keystone Cardiology Associates|Healthcare|95|Harrisburg|PA|Northeast|SMB|GROWING|N',
    'DEMO Magnolia Health System|Healthcare|4200|Atlanta|GA|South|ENT|STABLE|N',
    'DEMO Gulf Coast Urgent Care|Healthcare|75|Tampa|FL|South|SMB|NEW|N',
    'DEMO Desert Sky Dermatology|Healthcare|40|Phoenix|AZ|West|SMB|STABLE|N',
    'DEMO Cascade Behavioral Health|Healthcare|260|Spokane|WA|West|MID|DECLINING|N',
    'DEMO Brookline Preparatory School|Education|110|Brookline|MA|Northeast|MID|STABLE|N',
    'DEMO Lone Star ISD|Education|3100|Austin|TX|South|ENT|GROWING|N',
    'DEMO Blue Ridge Christian School|Education|65|Asheville|NC|South|SMB|LAPSED|N',
    'DEMO Sierra Vista College|Education|900|Sacramento|CA|West|MID|STABLE|N',
    'DEMO Montclair Montessori|Education|40|Montclair|NJ|Northeast|SMB|NEW|N',
    'DEMO Archer & Vale Accounting|Accounting|120|Philadelphia|PA|Northeast|MID|STABLE|N',
    'DEMO Pemberton Legal Group|Legal|75|Charlotte|NC|South|SMB|DECLINING|N',
    'DEMO Ironwood Insurance Brokers|Insurance|160|Denver|CO|West|MID|GROWING|N',
    'DEMO Calder Wealth Partners|Financial Services|55|Stamford|CT|Northeast|SMB|STABLE|N',
    'DEMO Pacific Rim Consulting|Consulting|240|San Diego|CA|West|MID|LAPSED|N',
    'DEMO Town of Millbrook|Government|180|Millbrook|NY|Northeast|MID|STABLE|N',
    'DEMO Harris County Clerk|Government|1100|Houston|TX|South|ENT|STABLE|N',
    'DEMO City of Riverside Parks|Government|90|Riverside|CA|West|SMB|DECLINING|N',
    'DEMO New Hope Food Pantry|Nonprofit|22|Nashville|TN|South|SMB|STABLE|N',
    'DEMO Unity Temple|Nonprofit|30|Seattle|WA|West|SMB|GROWING|N',
    'DEMO Habitat Partners of Ohio|Nonprofit|140|Cincinnati|OH|Midwest|MID|NEW|N',
    'DEMO Carolina Precision Machining|Manufacturing|210|Greensboro|NC|South|MID|STABLE|N',
    'DEMO Atlas Packaging Corp|Manufacturing|1500|Memphis|TN|South|ENT|DECLINING|N',
    'DEMO Pioneer Plastics|Manufacturing|85|Akron|OH|Midwest|SMB|GROWING|N',
    'DEMO Granite State Fabrication|Manufacturing|60|Manchester|NH|Northeast|SMB|LAPSED|N',
    'DEMO Bayside Freight|Transportation|310|Oakland|CA|West|MID|STABLE|N',
    'DEMO Copper Canyon Resort|Hospitality|280|Scottsdale|AZ|West|MID|GROWING|N',
    'DEMO Evergreen Property Management|Real Estate|120|Portland|ME|Northeast|MID|STABLE|N'
};

// Monthly spend per tier, same formula as seed-03, so estimated values match the order history.
Map<String, List<Decimal>> MONTHLY = new Map<String, List<Decimal>>{
    'ENT' => new List<Decimal>{ 15000, 40000 }, 'MID' => new List<Decimal>{ 3000, 15000 }, 'SMB' => new List<Decimal>{ 300, 3000 }
};
// First category in seed-03's mix for each industry (the one that declines), and one it never buys.
Map<String, List<String>> CATEGORY = new Map<String, List<String>>{
    'Healthcare' => new List<String>{ 'furniture', 'technology accessories' },
    'Education' => new List<String>{ 'furniture', 'janitorial supplies' },
    'Manufacturing' => new List<String>{ 'janitorial supplies', 'furniture' },
    'Hospitality' => new List<String>{ 'furniture', 'office supplies' },
    'Nonprofit' => new List<String>{ 'office supplies', 'breakroom supplies' },
    'Default' => new List<String>{ 'office supplies', 'breakroom supplies' }
};

// ---------------------------------------------------------------------------------------------
// Signal catalog. Each signal builds a reason, a recommended action, an estimated value and a score.
// ---------------------------------------------------------------------------------------------
// Signals per health, in priority-rank order. Accounts not listed in FIXED get these.
Map<String, List<String>> SIGNALS_BY_HEALTH = new Map<String, List<String>>{
    'GROWING' => new List<String>{ 'Expansion', 'Category Gap' },
    'STABLE' => new List<String>{ 'Category Gap', 'Renewal', 'Managed Print' },
    'DECLINING' => new List<String>{ 'Spend Decline', 'Service Risk' },
    'LAPSED' => new List<String>{ 'Reorder Lapsed' },
    'NEW' => new List<String>{ 'Single Thread', 'Category Gap' },
    'EDGE' => new List<String>()
};
// Open priorities per account. 17 of the 50 carry none, like a real book. Index = profile row.
// Test accounts (rows 0-4) are fixed in FIXED below.
Map<Integer, Integer> OPEN_COUNT_OVERRIDE = new Map<Integer, Integer>{
    // Seller's book (rows 5-19): 23 open across these, 29 with the test accounts.
    5 => 1, 6 => 2, 7 => 1, 8 => 2, 9 => 2, 10 => 2, 11 => 1, 12 => 3, 13 => 1, 14 => 2, 15 => 1, 16 => 2, 17 => 1, 18 => 2, 19 => 0,
    // Rest of team (rows 20-49): 15 with none. Plus row 19 and Ridgeway = 17 of 50.
    20 => 2, 21 => 2, 22 => 0, 23 => 3, 24 => 2, 25 => 0, 26 => 2, 27 => 0, 28 => 2, 29 => 1,
    30 => 0, 31 => 2, 32 => 0, 33 => 2, 34 => 0, 35 => 0, 36 => 1, 37 => 0, 38 => 2, 39 => 0,
    40 => 0, 41 => 0, 42 => 2, 43 => 0, 44 => 2, 45 => 0, 46 => 1, 47 => 0, 48 => 2, 49 => 0
};

// Fixed priorities for the 5 test accounts (the tests depend on these exact values).
// Columns: account key | name | rank | signal | reason | recommended action | value | score | status
List<String> FIXED = new List<String>{
    'DEMO Lakeshore Medical Group|Chicago|Lakeshore Priority 1|1|Spend Decline|Declining furniture spend at 3 sites|Offer site-level furniture review|36000|82|Open',
    'DEMO Lakeshore Medical Group|Chicago|Lakeshore Priority 2|2|Managed Print|Print volume flat|Propose managed print review|8600|58|Open',
    'DEMO Lakeshore Medical Group|Chicago|Lakeshore Priority 3|3|Service Risk|Open delivery-delay case before renewal|Resolve the case, then book the renewal review|120000|88|Open',
    'DEMO Lakeshore Medical Group|Chicago|Lakeshore Priority 4|4|Category Gap|Buys furniture and print but not office supplies|Introduce office supplies with a trial order|24000|61|Actioned',
    'DEMO Pinecrest School District|Portland|Pinecrest Priority 1|1|Single Thread|Only one contact on file|Identify a second decision maker in facilities|0|47|Open',
    'DEMO Harbor Supply Co|Seattle|Harbor Seattle Priority 1|1|Reorder Lapsed|No order in 104 days|Check-in call to confirm the next order|5400|72|Open',
    'DEMO Harbor Supply Co|Tacoma|Harbor Tacoma Priority 1|1|Expansion|New warehouse opening next quarter|Propose a warehouse supplies starter kit|9500|66|Open'
    // DEMO Ridgeway Logistics: no priorities on purpose (test 5).
};

// Follow-through history: 14 Actioned (each linked to a completed Task or won Opportunity) and
// 6 Dismissed, spread across rows that carry no open priorities. Row index | signal | status.
List<String> HISTORY = new List<String>{
    '19|Reorder Lapsed|Actioned', '22|Expansion|Actioned', '25|Category Gap|Actioned', '27|Renewal|Actioned',
    '30|Category Gap|Actioned', '32|Single Thread|Actioned', '34|Spend Decline|Actioned', '35|Managed Print|Actioned',
    '37|Reorder Lapsed|Actioned', '39|Spend Decline|Actioned', '41|Renewal|Actioned', '43|Category Gap|Actioned',
    '45|Expansion|Actioned', '47|Reorder Lapsed|Actioned',
    '40|Managed Print|Dismissed', '49|Renewal|Dismissed', '22|Single Thread|Dismissed', '27|Managed Print|Dismissed',
    '37|Category Gap|Dismissed', '43|Renewal|Dismissed'
};

// ---------------------------------------------------------------------------------------------
// Helpers are written inline because anonymous Apex can't declare static methods.
// ---------------------------------------------------------------------------------------------
Map<String, Account> byKey = new Map<String, Account>();
for (Account a : [SELECT Id, Name, BillingCity, OwnerId FROM Account WHERE Name LIKE 'DEMO %']) {
    byKey.put(a.Name + '|' + a.BillingCity, a);
}

// Existing priorities, by account, and all names (names are the upsert key).
Map<Id, Integer> openByAccount = new Map<Id, Integer>();
Map<Id, Integer> totalByAccount = new Map<Id, Integer>();
Set<String> existingNames = new Set<String>();
Map<String, Account_Priority__c> existingByName = new Map<String, Account_Priority__c>();
for (Account_Priority__c p : [SELECT Id, Name, Account__c, Status__c, Signal_Type__c FROM Account_Priority__c WHERE Account__r.Name LIKE 'DEMO %']) {
    existingNames.add(p.Name);
    existingByName.put(p.Name, p);
    Integer t = totalByAccount.containsKey(p.Account__c) ? totalByAccount.get(p.Account__c) : 0;
    totalByAccount.put(p.Account__c, t + 1);
    // Sister-demo priorities have no Status__c yet; treat blank as Open.
    if (p.Status__c == null || p.Status__c == 'Open') {
        Integer o = openByAccount.containsKey(p.Account__c) ? openByAccount.get(p.Account__c) : 0;
        openByAccount.put(p.Account__c, o + 1);
    }
}

List<Account_Priority__c> toInsert = new List<Account_Priority__c>();
List<Account_Priority__c> toUpdate = new List<Account_Priority__c>();
Integer historyLinks = 0;

// ---- 1. Fixed test-account priorities --------------------------------------------------------
for (String row : FIXED) {
    List<String> f = row.split('\\|');
    Account a = byKey.get(f[0] + '|' + f[1]);
    if (a == null) { continue; }
    // Sister seeds name these "Lakeshore Priority 1" or "DEMO Lakeshore Priority 1" depending on version.
    String match = existingByName.containsKey(f[2]) ? f[2] : (existingByName.containsKey('DEMO ' + f[2]) ? 'DEMO ' + f[2] : null);
    if (match != null) {
        // Sister priorities exist without the new fields: fill them once, never overwrite.
        Account_Priority__c p = existingByName.get(match);
        if (p.Signal_Type__c == null) {
            toUpdate.add(new Account_Priority__c(
                Id = p.Id, Signal_Type__c = f[4], Estimated_Value__c = Decimal.valueOf(f[7]),
                Propensity_Score__c = Decimal.valueOf(f[8]), Status__c = p.Status__c == null ? f[9] : p.Status__c
            ));
        }
        continue;
    }
    toInsert.add(new Account_Priority__c(
        Account__c = a.Id, Name = f[2], Priority_Rank__c = Integer.valueOf(f[3]), Signal_Type__c = f[4],
        Priority_Reason__c = f[5], Recommended_Action__c = f[6], Estimated_Value__c = Decimal.valueOf(f[7]),
        Propensity_Score__c = Decimal.valueOf(f[8]), Status__c = f[9],
        Refreshed_On__c = today.addDays(-3),
        Actioned_On__c = f[9] == 'Actioned' ? today.addDays(-14) : null
    ));
}

// ---- 2. Generated priorities for rows 5-49, plus top-up for every account -------------------
Map<String, Integer> baselineOpen = new Map<String, Integer>{
    'DEMO Lakeshore Medical Group|Chicago' => 3, 'DEMO Pinecrest School District|Portland' => 1,
    'DEMO Harbor Supply Co|Seattle' => 1, 'DEMO Harbor Supply Co|Tacoma' => 1, 'DEMO Ridgeway Logistics|Dallas' => 0
};
List<String> TOPUP_SIGNALS = new List<String>{ 'Category Gap', 'Renewal', 'Managed Print', 'Expansion', 'Reorder Lapsed', 'Single Thread', 'Spend Decline', 'Service Risk' };

for (Integer i = 0; i < PROFILES.size(); i++) {
    List<String> f = PROFILES[i].split('\\|');
    String key = f[0] + '|' + f[3];
    Account a = byKey.get(key);
    if (a == null) { continue; }
    String shortName = f[0].removeStart('DEMO ');
    List<Decimal> range = MONTHLY.get(f[6]);
    Decimal monthly = range[0] + (range[1] - range[0]) * (Decimal.valueOf(Math.mod(i, 5)) / 4);
    List<String> cats = CATEGORY.containsKey(f[1]) ? CATEGORY.get(f[1]) : CATEGORY.get('Default');

    Integer target = baselineOpen.containsKey(key) ? baselineOpen.get(key) : OPEN_COUNT_OVERRIDE.get(i);
    if (target == null) { target = 0; }
    Integer haveOpen = openByAccount.containsKey(a.Id) ? openByAccount.get(a.Id) : 0;
    // Count what this run is already adding for the account (fixed rows above).
    for (Account_Priority__c p : toInsert) {
        if (p.Account__c == a.Id && p.Status__c == 'Open') { haveOpen++; }
    }
    Integer need = target - haveOpen;
    if (need <= 0) { continue; }

    List<String> plan = new List<String>(SIGNALS_BY_HEALTH.get(f[7]));
    for (String s : TOPUP_SIGNALS) { if (!plan.contains(s)) { plan.add(s); } }

    Integer nextRank = (totalByAccount.containsKey(a.Id) ? totalByAccount.get(a.Id) : 0) + 1;
    for (Account_Priority__c p : toInsert) { if (p.Account__c == a.Id) { nextRank++; } }

    Integer added = 0;
    Integer cursor = 0;
    Integer guard = 0;
    while (added < need && guard < 40) {
        guard++;
        String signal = plan[Math.mod(cursor, plan.size())];
        cursor++;
        String name = shortName + ' ' + signal + ' #' + nextRank;
        if (existingNames.contains(name)) { nextRank++; continue; }

        String reason;
        String action;
        Decimal value;
        Integer score;
        Integer daysLapsed = 95 + Math.mod(i * 7, 40);
        if (signal == 'Spend Decline') {
            reason = cats[0].capitalize() + ' spend down 22% over 6 months';
            action = 'Offer a ' + cats[0] + ' review';
            // Annual spend in that category at risk if the decline continues.
            value = (monthly * 0.4 * 12).setScale(0);
            score = 70 + Math.mod(i, 16);
        } else if (signal == 'Category Gap') {
            reason = 'Buys ' + cats[0] + ' but not ' + cats[1];
            action = 'Introduce ' + cats[1] + ' with a trial order';
            value = (monthly * 0.2 * 12).setScale(0);
            score = 50 + Math.mod(i, 16);
        } else if (signal == 'Reorder Lapsed') {
            reason = 'No order in ' + daysLapsed + ' days';
            action = 'Check-in call to confirm the next order';
            value = (monthly * 3).setScale(0);
            score = 65 + Math.mod(i, 16);
        } else if (signal == 'Renewal') {
            reason = 'Price agreement renews in ' + (45 + Math.mod(i * 11, 75)) + ' days';
            action = 'Book a renewal review';
            value = (monthly * 12).setScale(0);
            score = 80 + Math.mod(i, 11);
        } else if (signal == 'Expansion') {
            reason = Math.mod(i, 2) == 0 ? 'Headcount up 15% this year' : 'New location opening next quarter';
            action = 'Propose a furniture and supplies starter package';
            value = (monthly * 4).setScale(0);
            score = 60 + Math.mod(i, 16);
        } else if (signal == 'Managed Print') {
            reason = 'Print spend above segment average';
            action = 'Propose a managed print review';
            value = (monthly * 0.15 * 12 * 0.15).setScale(0);
            score = 45 + Math.mod(i, 16);
        } else if (signal == 'Service Risk') {
            reason = 'Open high-priority case ' + (20 + Math.mod(i, 25)) + ' days before renewal';
            action = 'Resolve the case, then book the renewal review';
            value = (monthly * 12).setScale(0);
            score = 75 + Math.mod(i, 16);
        } else {
            reason = 'Only one contact on file';
            action = 'Identify a second decision maker';
            value = 0;
            score = 40 + Math.mod(i, 16);
        }

        toInsert.add(new Account_Priority__c(
            Account__c = a.Id, Name = name, Priority_Rank__c = nextRank, Signal_Type__c = signal,
            Priority_Reason__c = reason.left(255), Recommended_Action__c = action.left(255),
            Estimated_Value__c = value, Propensity_Score__c = score, Status__c = 'Open',
            Refreshed_On__c = today.addDays(-Math.mod(i, 10))
        ));
        existingNames.add(name);
        nextRank++;
        added++;
    }
}

// ---- 3. Follow-through history (first run only: skipped if any history name exists) --------
List<Account_Priority__c> historyRows = new List<Account_Priority__c>();
Boolean historyExists = false;
for (String n : existingNames) { if (n.endsWith('(history)')) { historyExists = true; break; } }
if (!historyExists) {
    for (Integer h = 0; h < HISTORY.size(); h++) {
        List<String> f = HISTORY[h].split('\\|');
        List<String> p = PROFILES[Integer.valueOf(f[0])].split('\\|');
        Account a = byKey.get(p[0] + '|' + p[3]);
        if (a == null) { continue; }
        historyRows.add(new Account_Priority__c(
            Account__c = a.Id, Name = p[0].removeStart('DEMO ') + ' ' + f[1] + ' (history)',
            Priority_Rank__c = 9, Signal_Type__c = f[1], Status__c = f[2],
            Priority_Reason__c = f[1] + ' signal from a prior quarter',
            Recommended_Action__c = f[2] == 'Actioned' ? 'Followed up by the account owner' : 'Dismissed by the account owner',
            Propensity_Score__c = 55 + Math.mod(h * 7, 30), Estimated_Value__c = 2500 + h * 750,
            Refreshed_On__c = today.addDays(-60 - h * 5),
            Actioned_On__c = f[2] == 'Actioned' ? today.addDays(-45 - h * 4) : null
        ));
    }
}

insert toInsert;
update toUpdate;
insert historyRows;

// Link each Actioned history row to a completed Task or a won Opportunity on its account.
if (!historyRows.isEmpty()) {
    Set<Id> accountIds = new Set<Id>();
    for (Account_Priority__c p : historyRows) { accountIds.add(p.Account__c); }
    Map<Id, List<Id>> wonByAccount = new Map<Id, List<Id>>();
    for (Opportunity o : [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :accountIds AND IsWon = true ORDER BY CloseDate DESC]) {
        if (!wonByAccount.containsKey(o.AccountId)) { wonByAccount.put(o.AccountId, new List<Id>()); }
        wonByAccount.get(o.AccountId).add(o.Id);
    }
    Map<Id, List<Id>> doneByAccount = new Map<Id, List<Id>>();
    for (Task t : [SELECT Id, WhatId FROM Task WHERE WhatId IN :accountIds AND IsClosed = true ORDER BY ActivityDate DESC]) {
        if (!doneByAccount.containsKey(t.WhatId)) { doneByAccount.put(t.WhatId, new List<Id>()); }
        doneByAccount.get(t.WhatId).add(t.Id);
    }
    List<Account_Priority__c> links = new List<Account_Priority__c>();
    Integer n = 0;
    for (Account_Priority__c p : historyRows) {
        if (p.Status__c != 'Actioned') { continue; }
        // Alternate: every third actioned priority converted to a won Opportunity, the rest to Tasks.
        List<Id> pool = (Math.mod(n, 3) == 0 && wonByAccount.containsKey(p.Account__c)) ? wonByAccount.get(p.Account__c) : doneByAccount.get(p.Account__c);
        n++;
        if (pool == null || pool.isEmpty()) { continue; }
        links.add(new Account_Priority__c(Id = p.Id, Action_Record_Id__c = pool.remove(0)));
    }
    update links;
    historyLinks = links.size();
}

System.debug('=== SEED 04 COMPLETE ===');
System.debug('Priorities added: ' + toInsert.size() + ' (including fixed test-account rows)' + ' | Sister priorities updated: ' + toUpdate.size());
System.debug('History added: ' + historyRows.size() + ' (' + historyLinks + ' linked to a Task or Opportunity)');
System.debug('Open DEMO priorities now: ' + [SELECT COUNT() FROM Account_Priority__c WHERE Account__r.Name LIKE 'DEMO %' AND Status__c = 'Open']);
