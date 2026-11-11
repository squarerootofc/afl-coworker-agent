// Seed 02 of 04: opportunities, completed tasks and cases for the 50-account book.
// Add-only and re-runnable: each record type is created only for accounts seed-01 created
// (Description starts with MARKER) that have none yet, so the sister demo's accounts keep their data.
// Run after seed-01-accounts.apex.

String MARKER = 'DEMO account.';
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

// Deal size per tier (base amount for opportunities).
Map<String, Decimal> DEAL_BASE = new Map<String, Decimal>{ 'ENT' => 60000, 'MID' => 18000, 'SMB' => 4000 };

// Opportunity themes; the name is "<short account name> - <theme>".
List<String> THEMES = new List<String>{ 'Furniture Refresh', 'Managed Print Program', 'Annual Supplies Agreement', 'Breakroom Program', 'Janitorial Supplies', 'Technology Accessories', 'New Location Fit-Out', 'Ergonomic Seating' };

// Open opportunities per health: ENT gets one extra.
Map<String, Integer> OPEN_OPPS = new Map<String, Integer>{ 'GROWING' => 3, 'STABLE' => 2, 'DECLINING' => 1, 'LAPSED' => 0, 'NEW' => 1, 'EDGE' => 1 };
Map<String, Integer> WON_OPPS = new Map<String, Integer>{ 'GROWING' => 2, 'STABLE' => 2, 'DECLINING' => 1, 'LAPSED' => 1, 'NEW' => 0, 'EDGE' => 0 };
Map<String, Integer> LOST_OPPS = new Map<String, Integer>{ 'GROWING' => 0, 'STABLE' => 1, 'DECLINING' => 2, 'LAPSED' => 1, 'NEW' => 0, 'EDGE' => 0 };

// Days since last completed activity, by health: [most recent, spacing].
Map<String, List<Integer>> ACTIVITY = new Map<String, List<Integer>>{
    'GROWING' => new List<Integer>{ 6, 18 }, 'STABLE' => new List<Integer>{ 25, 30 }, 'DECLINING' => new List<Integer>{ 45, 35 },
    'LAPSED' => new List<Integer>{ 95, 40 }, 'NEW' => new List<Integer>{ 9, 12 }, 'EDGE' => new List<Integer>{ 30, 30 }
};
List<String> CALL_SUBJECTS = new List<String>{ 'Quarterly check-in call', 'Reviewed reorder schedule', 'Sent catalog and pricing', 'Followed up on delivery', 'Introduced new product line', 'Confirmed contract terms' };

// Cases: [subject, priority]. Declining and Service Risk accounts get an open case (see seed-04).
List<List<String>> CASE_TYPES = new List<List<String>>{
    new List<String>{ 'Late delivery', 'Medium' }, new List<String>{ 'Invoice discrepancy', 'Low' }, new List<String>{ 'Damaged shipment', 'High' },
    new List<String>{ 'Backordered item', 'Medium' }, new List<String>{ 'Return request', 'Low' }, new List<String>{ 'Wrong item shipped', 'Medium' }
};
Map<String, Integer> CLOSED_CASES = new Map<String, Integer>{ 'GROWING' => 1, 'STABLE' => 1, 'DECLINING' => 2, 'LAPSED' => 1, 'NEW' => 0, 'EDGE' => 0 };
Set<String> OPEN_CASE = new Set<String>{ 'DECLINING' };

// ---------------------------------------------------------------------------------------------
// Org-specific picklist values: read them instead of hard-coding (stages differ between orgs).
// ---------------------------------------------------------------------------------------------
List<String> openStages = new List<String>();
String wonStage;
String lostStage;
for (OpportunityStage s : [SELECT ApiName, IsClosed, IsWon FROM OpportunityStage WHERE IsActive = true ORDER BY SortOrder]) {
    if (!s.IsClosed) { openStages.add(s.ApiName); }
    if (s.IsClosed && s.IsWon && wonStage == null) { wonStage = s.ApiName; }
    if (s.IsClosed && !s.IsWon && lostStage == null) { lostStage = s.ApiName; }
}
String taskDone = [SELECT ApiName FROM TaskStatus WHERE IsClosed = true LIMIT 1].ApiName;
String caseOpen = [SELECT ApiName FROM CaseStatus WHERE IsClosed = false AND IsDefault = true LIMIT 1].ApiName;
String caseClosed = [SELECT ApiName FROM CaseStatus WHERE IsClosed = true LIMIT 1].ApiName;

// ---------------------------------------------------------------------------------------------
// Which accounts already have each record type (skip those).
// ---------------------------------------------------------------------------------------------
Map<String, Account> byKey = new Map<String, Account>();
Set<Id> hasOpps = new Set<Id>();
Set<Id> hasTasks = new Set<Id>();
Set<Id> hasCases = new Set<Id>();
for (Account a : [
    SELECT Id, Name, BillingCity, OwnerId, Description,
           (SELECT Id FROM Opportunities LIMIT 1), (SELECT Id FROM Tasks LIMIT 1), (SELECT Id FROM Cases LIMIT 1),
           (SELECT Id FROM Contacts ORDER BY CreatedDate LIMIT 1)
    FROM Account WHERE Name LIKE 'DEMO %'
]) {
    // Description is a long text field, so SOQL can't filter on it; check the marker here instead.
    if (a.Description == null || !a.Description.startsWith(MARKER)) { continue; }
    byKey.put(a.Name + '|' + a.BillingCity, a);
    if (!a.Opportunities.isEmpty()) { hasOpps.add(a.Id); }
    if (!a.Tasks.isEmpty()) { hasTasks.add(a.Id); }
    if (!a.Cases.isEmpty()) { hasCases.add(a.Id); }
}

List<Opportunity> opps = new List<Opportunity>();
List<Task> tasks = new List<Task>();
List<Case> cases = new List<Case>();

for (Integer i = 0; i < PROFILES.size(); i++) {
    List<String> f = PROFILES[i].split('\\|');
    Account a = byKey.get(f[0] + '|' + f[3]);
    if (a == null) { continue; }
    String tier = f[6];
    String health = f[7];
    String shortName = f[0].removeStart('DEMO ');
    Decimal base = DEAL_BASE.get(tier);
    Id contactId = a.Contacts.isEmpty() ? null : a.Contacts[0].Id;

    // Opportunities
    if (!hasOpps.contains(a.Id)) {
        Integer openCount = OPEN_OPPS.get(health) + (tier == 'ENT' ? 1 : 0);
        for (Integer o = 0; o < openCount; o++) {
            // Spread open deals across the org's open stages and the next 120 days.
            String stage = openStages[Math.mod(i + o, Math.min(openStages.size(), 4))];
            opps.add(new Opportunity(
                AccountId = a.Id, OwnerId = a.OwnerId,
                Name = shortName + ' - ' + THEMES[Math.mod(i + o, THEMES.size())],
                StageName = stage,
                CloseDate = today.addDays(20 + Math.mod(i * 17 + o * 31, 100)),
                Amount = (base * (0.6 + Math.mod(i + o * 3, 9) * 0.1)).setScale(0)
            ));
        }
        for (Integer w = 0; w < WON_OPPS.get(health); w++) {
            opps.add(new Opportunity(
                AccountId = a.Id, OwnerId = a.OwnerId,
                Name = shortName + ' - ' + THEMES[Math.mod(i + w + 4, THEMES.size())] + ' (FY26)',
                StageName = wonStage,
                CloseDate = today.addDays(-30 - Math.mod(i * 23 + w * 61, 300)),
                Amount = (base * (0.8 + Math.mod(i + w, 6) * 0.1)).setScale(0)
            ));
        }
        for (Integer l = 0; l < LOST_OPPS.get(health); l++) {
            opps.add(new Opportunity(
                AccountId = a.Id, OwnerId = a.OwnerId,
                Name = shortName + ' - ' + THEMES[Math.mod(i + l + 2, THEMES.size())] + ' (competitive bid)',
                StageName = lostStage,
                CloseDate = today.addDays(-20 - Math.mod(i * 19 + l * 43, 200)),
                Amount = (base * (0.5 + Math.mod(i + l, 5) * 0.1)).setScale(0)
            ));
        }
    }

    // Completed activity history: 3 calls or emails, the most recent sets "last activity".
    if (!hasTasks.contains(a.Id)) {
        List<Integer> act = ACTIVITY.get(health);
        for (Integer t = 0; t < 3; t++) {
            Date d = today.addDays(-(act[0] + t * act[1]));
            tasks.add(new Task(
                WhatId = a.Id, WhoId = contactId, OwnerId = a.OwnerId,
                Subject = CALL_SUBJECTS[Math.mod(i + t, CALL_SUBJECTS.size())],
                ActivityDate = d, Status = taskDone, Priority = 'Normal',
                Description = 'DEMO activity history.'
            ));
        }
    }

    // Cases
    if (!hasCases.contains(a.Id)) {
        for (Integer c = 0; c < CLOSED_CASES.get(health); c++) {
            List<String> ct = CASE_TYPES[Math.mod(i + c, CASE_TYPES.size())];
            cases.add(new Case(AccountId = a.Id, ContactId = contactId, Subject = ct[0], Priority = ct[1], Status = caseClosed, Origin = 'Email'));
        }
        if (OPEN_CASE.contains(health)) {
            List<String> ct = CASE_TYPES[Math.mod(i + 3, CASE_TYPES.size())];
            cases.add(new Case(AccountId = a.Id, ContactId = contactId, Subject = ct[0], Priority = 'High', Status = caseOpen, Origin = 'Phone'));
        }
    }
}

insert opps;
insert tasks;
insert cases;

System.debug('=== SEED 02 COMPLETE ===');
System.debug('Opportunities added: ' + opps.size() + ' | Tasks added: ' + tasks.size() + ' | Cases added: ' + cases.size());
System.debug('Stages used: open=' + openStages + ' won=' + wonStage + ' lost=' + lostStage);
