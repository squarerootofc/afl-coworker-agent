// Seed 03 of 04: 12 months of orders for the 50-account book.
// Each account's order history follows its health (growing, stable, declining, lapsed, new),
// so the priority reasons written by seed-04 match what the brief shows.
// Add-only and re-runnable: only accounts seed-01 created (Description starts with "DEMO account.")
// that have no orders yet. The sister demo's accounts keep their orders, or lack of them.
// Run after seed-02-activity.apex.
//
// Limits: about 400 orders and 1,000 order items in 4 DML statements. If CPU time is tight in an
// org with heavy Order automation, set BATCH to 1 or 2 and run the script once per batch.
Integer BATCH = 0; // 0 = all accounts; 1 = rows 1-25; 2 = rows 26-50

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

// Monthly spend per tier. Exact value = low + (high - low) * ((index mod 5) / 4).
Map<String, List<Decimal>> MONTHLY = new Map<String, List<Decimal>>{
    'ENT' => new List<Decimal>{ 15000, 40000 }, 'MID' => new List<Decimal>{ 3000, 15000 }, 'SMB' => new List<Decimal>{ 300, 3000 }
};

// Category mix by industry: product code => share of monthly spend. A category that is missing
// here is a Category Gap in seed-04.
Map<String, Map<String, Decimal>> MIX = new Map<String, Map<String, Decimal>>{
    'Healthcare' => new Map<String, Decimal>{ 'FURN' => 0.40, 'SUPPL' => 0.30, 'PRINT' => 0.15, 'JANIT' => 0.15 },
    'Education' => new Map<String, Decimal>{ 'FURN' => 0.45, 'SUPPL' => 0.35, 'TECH' => 0.20 },
    'Manufacturing' => new Map<String, Decimal>{ 'JANIT' => 0.35, 'BREAK' => 0.30, 'SUPPL' => 0.35 },
    'Hospitality' => new Map<String, Decimal>{ 'FURN' => 0.35, 'JANIT' => 0.35, 'BREAK' => 0.30 },
    'Nonprofit' => new Map<String, Decimal>{ 'SUPPL' => 0.60, 'PRINT' => 0.40 },
    'Default' => new Map<String, Decimal>{ 'SUPPL' => 0.40, 'PRINT' => 0.30, 'FURN' => 0.15, 'TECH' => 0.15 }
};

// Health shapes the 12-month series (m = 1 is last month, m = 12 is a year ago).
// DECLINING: the account's first category falls by DECLINE_PCT over 6 months; others stay flat.
Decimal DECLINE_PCT = 0.22;

// ---------------------------------------------------------------------------------------------
Pricebook2 std = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!std.IsActive) {
    throw new IllegalArgumentException('Standard price book is inactive. Run seed-01-accounts.apex first.');
}
Map<String, PricebookEntry> entryByCode = new Map<String, PricebookEntry>();
for (PricebookEntry e : [SELECT Id, Product2Id, Product2.ProductCode, Product2.Name FROM PricebookEntry WHERE Pricebook2Id = :std.Id AND Product2.Name LIKE 'DEMO %' AND IsActive = true]) {
    entryByCode.put(e.Product2.ProductCode, e);
}

Map<String, Account> byKey = new Map<String, Account>();
Set<Id> hasOrders = new Set<Id>();
for (Account a : [SELECT Id, Name, BillingCity, OwnerId, Description, (SELECT Id FROM Orders LIMIT 1) FROM Account WHERE Name LIKE 'DEMO %']) {
    // Description is a long text field, so SOQL can't filter on it; check the marker here instead.
    if (a.Description == null || !a.Description.startsWith('DEMO account.')) { continue; }
    byKey.put(a.Name + '|' + a.BillingCity, a);
    if (!a.Orders.isEmpty()) { hasOrders.add(a.Id); }
}

List<Order> orders = new List<Order>();
List<List<OrderItem>> itemsPerOrder = new List<List<OrderItem>>();

Integer startRow = BATCH == 2 ? 25 : 0;
Integer endRow = BATCH == 1 ? 25 : PROFILES.size();
for (Integer i = startRow; i < endRow; i++) {
    List<String> f = PROFILES[i].split('\\|');
    Account a = byKey.get(f[0] + '|' + f[3]);
    if (a == null || hasOrders.contains(a.Id)) { continue; }
    String tier = f[6];
    String health = f[7];
    if (health == 'EDGE') { continue; } // Harbor x2 and Ridgeway stay sparse in a standalone org too.

    List<Decimal> range = MONTHLY.get(tier);
    Decimal monthly = range[0] + (range[1] - range[0]) * (Decimal.valueOf(Math.mod(i, 5)) / 4);
    Map<String, Decimal> mix = MIX.containsKey(f[1]) ? MIX.get(f[1]) : MIX.get('Default');
    List<String> codes = new List<String>(mix.keySet());
    String declining = codes[0];

    // Months with orders: LAPSED stopped ordering 3 months ago; NEW started 3 months ago.
    Integer firstMonth = health == 'LAPSED' ? 3 : 1;
    Integer lastMonth = health == 'NEW' ? 3 : 12;

    for (Integer m = firstMonth; m <= lastMonth; m++) {
        Order o = new Order(
            AccountId = a.Id, OwnerId = a.OwnerId, Pricebook2Id = std.Id, Status = 'Draft',
            EffectiveDate = today.addMonths(-m).toStartOfMonth().addDays(Math.mod(i, 20))
        );
        List<OrderItem> items = new List<OrderItem>();
        for (String code : codes) {
            PricebookEntry e = entryByCode.get(code);
            if (e == null) { continue; }
            Decimal amount = monthly * mix.get(code);
            if (health == 'GROWING') {
                // Up about 25% over the year: a year ago is the base, last month is the peak.
                amount = amount * (1 + 0.25 * (12 - m) / 11);
            }
            if (health == 'DECLINING' && code == declining && m <= 6) {
                // Flat for months 7-12, then a straight decline to (1 - DECLINE_PCT) last month.
                amount = amount * (1 - DECLINE_PCT * (7 - m) / 6);
            }
            if (health == 'STABLE') {
                amount = amount * (1 + 0.04 * Decimal.valueOf(Math.sin(m + i)));
            }
            amount = amount.setScale(2);
            if (amount <= 0) { continue; }
            items.add(new OrderItem(PricebookEntryId = e.Id, Product2Id = e.Product2Id, Quantity = 1, UnitPrice = amount));
        }
        if (!items.isEmpty()) {
            orders.add(o);
            itemsPerOrder.add(items);
        }
    }
}

insert orders;
List<OrderItem> allItems = new List<OrderItem>();
for (Integer k = 0; k < orders.size(); k++) {
    for (OrderItem it : itemsPerOrder[k]) {
        it.OrderId = orders[k].Id;
        allItems.add(it);
    }
}
insert allItems;

for (Order o : orders) { o.Status = 'Activated'; }
update orders;

System.debug('=== SEED 03 COMPLETE (batch ' + BATCH + ') ===');
System.debug('Orders added: ' + orders.size() + ' | Order items added: ' + allItems.size());
System.debug('CPU ms used: ' + Limits.getCpuTime() + ' of ' + Limits.getLimitCpuTime());
