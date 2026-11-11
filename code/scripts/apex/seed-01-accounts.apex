// Seed 01 of 04: the 50-account book of business.
// Creates missing DEMO accounts, their contacts, and 6 DEMO products with standard price book entries.
// Add-only and re-runnable: never deletes, skips anything that already exists.
// Run after afl-coworker-skills/code/deploy.sh when both demos share an org.
//
// Accounts this script creates get a Description starting with MARKER. Seeds 01-03 add child
// records (contacts, opportunities, tasks, cases, orders) only to marked accounts, so accounts the
// sister demo created keep exactly the data its tests expect. Seed 04 adds account priorities to all.
//
// Optional: set SELLER_USERNAME to the test seller. The first 20 accounts (the seller's book,
// including the 5 test accounts) are then owned by that user; the other 30 by the running user.
String SELLER_USERNAME = '';

String MARKER = 'DEMO account.';
Date today = Date.today();

// ---------------------------------------------------------------------------------------------
// Profile table: one row per account. Every later script derives its data from this table, so
// keep it identical in all four scripts.
// Columns: name | industry | employees | city | state | region | tier | health | seller book (Y/N)
// health: GROWING, STABLE, DECLINING, LAPSED, NEW, EDGE
// ---------------------------------------------------------------------------------------------
List<String> PROFILES = new List<String>{
    // Seller's book: 20 accounts (5 test accounts first)
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
    // Rest of the sales team: 30 accounts
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

// Contacts per tier: [min, max]. Exact count = min + (index mod span).
Map<String, List<Integer>> CONTACTS_BY_TIER = new Map<String, List<Integer>>{
    'ENT' => new List<Integer>{ 6, 8 }, 'MID' => new List<Integer>{ 3, 5 }, 'SMB' => new List<Integer>{ 1, 2 }
};

// Titles by industry: the first is the primary buyer. Single Thread accounts get only one contact.
Map<String, List<String>> TITLES = new Map<String, List<String>>{
    'Healthcare' => new List<String>{ 'Practice Administrator', 'Facilities Director', 'Procurement Manager', 'Office Manager', 'CFO', 'Director of Nursing', 'IT Manager', 'Clinic Operations Lead' },
    'Education' => new List<String>{ 'Business Manager', 'Facilities Director', 'Purchasing Coordinator', 'Principal', 'Superintendent', 'IT Director', 'Office Manager', 'Assistant Superintendent' },
    'Government' => new List<String>{ 'Purchasing Agent', 'Facilities Manager', 'Finance Director', 'Office Manager', 'IT Manager', 'City Clerk', 'Operations Manager', 'Budget Analyst' },
    'Nonprofit' => new List<String>{ 'Executive Director', 'Office Manager', 'Operations Coordinator', 'Finance Manager', 'Facilities Volunteer Lead', 'Program Director', 'Board Treasurer', 'Admin Assistant' },
    'Manufacturing' => new List<String>{ 'Plant Manager', 'Purchasing Manager', 'Office Manager', 'EHS Manager', 'Controller', 'Maintenance Supervisor', 'HR Manager', 'Operations Director' },
    'Default' => new List<String>{ 'Office Manager', 'Operations Director', 'Procurement Lead', 'Controller', 'Facilities Manager', 'IT Manager', 'Executive Assistant', 'COO' }
};
List<String> FIRST = new List<String>{ 'Avery', 'Jordan', 'Morgan', 'Priya', 'Marcus', 'Elena', 'Darius', 'Mei', 'Rafael', 'Hannah', 'Tomas', 'Grace', 'Imani', 'Victor', 'Leah', 'Samir', 'Colleen', 'Andre', 'Nadia', 'Owen' };
List<String> LAST = new List<String>{ 'Okafor', 'Lindqvist', 'Ramirez', 'Brennan', 'Nguyen', 'Petrov', 'Whitaker', 'Castillo', 'Haddad', 'Sorensen', 'Delgado', 'Iyer', 'Mbeki', 'Fitzgerald', 'Novak', 'Abernathy', 'Kowalski', 'Tanaka', 'Oyelaran', 'Marchetti' };

// Accounts whose priority signal is Single Thread keep exactly one contact (see seed-04).
Set<String> SINGLE_THREAD = new Set<String>{ 'DEMO Pinecrest School District|Portland', 'DEMO Grace Fellowship Church|Joliet', 'DEMO Montclair Montessori|Montclair' };

// Products: code => [name, list price]. DEMO Furniture and DEMO Print are reused if the sister demo created them.
Map<String, List<String>> PRODUCTS = new Map<String, List<String>>{
    'FURN' => new List<String>{ 'DEMO Furniture', '100' },
    'PRINT' => new List<String>{ 'DEMO Print', '50' },
    'SUPPL' => new List<String>{ 'DEMO Office Supplies', '25' },
    'BREAK' => new List<String>{ 'DEMO Breakroom', '30' },
    'JANIT' => new List<String>{ 'DEMO Janitorial', '40' },
    'TECH' => new List<String>{ 'DEMO Technology', '200' }
};

// ---------------------------------------------------------------------------------------------
// 1. Price book and products
// ---------------------------------------------------------------------------------------------
Pricebook2 std = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!std.IsActive) {
    std.IsActive = true;
    update std;
}

Map<String, Product2> productsByName = new Map<String, Product2>();
List<String> productNames = new List<String>();
for (List<String> p : PRODUCTS.values()) { productNames.add(p[0]); }
for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Name IN :productNames]) { productsByName.put(p.Name, p); }

List<Product2> newProducts = new List<Product2>();
for (String code : PRODUCTS.keySet()) {
    String name = PRODUCTS.get(code)[0];
    if (!productsByName.containsKey(name)) {
        Product2 p = new Product2(Name = name, ProductCode = code, IsActive = true);
        newProducts.add(p);
        productsByName.put(name, p);
    }
}
insert newProducts;

Set<Id> pricedProductIds = new Set<Id>();
for (PricebookEntry e : [SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = :std.Id AND Product2.Name IN :productNames]) {
    pricedProductIds.add(e.Product2Id);
}
List<PricebookEntry> newEntries = new List<PricebookEntry>();
for (String code : PRODUCTS.keySet()) {
    Product2 p = productsByName.get(PRODUCTS.get(code)[0]);
    if (!pricedProductIds.contains(p.Id)) {
        newEntries.add(new PricebookEntry(Pricebook2Id = std.Id, Product2Id = p.Id, UnitPrice = Decimal.valueOf(PRODUCTS.get(code)[1]), IsActive = true));
    }
}
insert newEntries;

// ---------------------------------------------------------------------------------------------
// 2. Accounts (matched on Name + BillingCity so the two Harbor accounts stay distinct)
// ---------------------------------------------------------------------------------------------
Id sellerId = null;
if (String.isNotBlank(SELLER_USERNAME)) {
    List<User> sellers = [SELECT Id FROM User WHERE Username = :SELLER_USERNAME AND IsActive = true LIMIT 1];
    if (sellers.isEmpty()) {
        throw new IllegalArgumentException('SELLER_USERNAME not found or inactive: ' + SELLER_USERNAME);
    }
    sellerId = sellers[0].Id;
}

Map<String, Account> existing = new Map<String, Account>();
for (Account a : [SELECT Id, Name, BillingCity, BillingState, OwnerId FROM Account WHERE Name LIKE 'DEMO %']) {
    existing.put(a.Name + '|' + a.BillingCity, a);
}

// Orgs with state and country picklists reject free-text BillingState/BillingCountry: they need
// the ISO codes in BillingStateCode/BillingCountryCode instead. Detect which one this org uses.
Boolean usePicklists = Schema.SObjectType.Account.fields.getMap().containsKey('billingstatecode');

List<Account> toInsert = new List<Account>();
List<Account> toUpdate = new List<Account>();
for (String row : PROFILES) {
    List<String> f = row.split('\\|');
    String key = f[0] + '|' + f[3];
    Boolean inSellerBook = f[8] == 'Y';
    Id owner = (inSellerBook && sellerId != null) ? sellerId : UserInfo.getUserId();
    String slug = f[0].removeStart('DEMO ').toLowerCase().replaceAll('[^a-z0-9]', '');

    if (existing.containsKey(key)) {
        // Sister-demo accounts: fill gaps only, never overwrite.
        Account a = existing.get(key);
        Boolean changed = false;
        if (String.isBlank(a.BillingState)) {
            if (usePicklists) {
                a.put('BillingCountryCode', 'US');
                a.put('BillingStateCode', f[4]);
            } else {
                a.BillingState = f[4];
            }
            changed = true;
        }
        if (inSellerBook && sellerId != null && a.OwnerId != sellerId) { a.OwnerId = sellerId; changed = true; }
        if (changed) { toUpdate.add(a); }
        continue;
    }
    Account acc = new Account(
        Name = f[0],
        Industry = f[1],
        NumberOfEmployees = Integer.valueOf(f[2]),
        BillingCity = f[3],
        Website = slug + '.example',
        Type = 'Customer',
        Description = MARKER + ' Region: ' + f[5] + '. Tier: ' + f[6] + '. Health: ' + f[7] + '.',
        OwnerId = owner
    );
    if (usePicklists) {
        acc.put('BillingCountryCode', 'US');
        acc.put('BillingStateCode', f[4]);
    } else {
        acc.BillingState = f[4];
        acc.BillingCountry = 'United States';
    }
    toInsert.add(acc);
}
insert toInsert;
update toUpdate;

// ---------------------------------------------------------------------------------------------
// 3. Contacts (only for marked accounts that have none, so sister-demo accounts are left alone)
// ---------------------------------------------------------------------------------------------
Map<String, Account> byKey = new Map<String, Account>();
Set<Id> withContacts = new Set<Id>();
for (Account a : [SELECT Id, Name, BillingCity, OwnerId, Description, (SELECT Id FROM Contacts LIMIT 1) FROM Account WHERE Name LIKE 'DEMO %']) {
    byKey.put(a.Name + '|' + a.BillingCity, a);
    Boolean ours = a.Description != null && a.Description.startsWith(MARKER);
    if (!ours || !a.Contacts.isEmpty()) { withContacts.add(a.Id); }
}

List<Contact> contacts = new List<Contact>();
for (Integer i = 0; i < PROFILES.size(); i++) {
    List<String> f = PROFILES[i].split('\\|');
    String key = f[0] + '|' + f[3];
    Account a = byKey.get(key);
    if (a == null || withContacts.contains(a.Id)) { continue; }

    List<Integer> range = CONTACTS_BY_TIER.get(f[6]);
    Integer count = range[0] + Math.mod(i, range[1] - range[0] + 1);
    if (SINGLE_THREAD.contains(key)) { count = 1; }
    List<String> titles = TITLES.containsKey(f[1]) ? TITLES.get(f[1]) : TITLES.get('Default');
    String domain = f[0].removeStart('DEMO ').toLowerCase().replaceAll('[^a-z0-9]', '') + '.example';

    for (Integer c = 0; c < count; c++) {
        String first = FIRST[Math.mod(i * 3 + c, FIRST.size())];
        String last = LAST[Math.mod(i * 7 + c * 2, LAST.size())];
        contacts.add(new Contact(
            AccountId = a.Id,
            OwnerId = a.OwnerId,
            FirstName = first,
            LastName = last,
            Title = titles[Math.mod(c, titles.size())],
            Email = (first.left(1) + last).toLowerCase() + '@' + domain,
            Phone = '(555) 01' + String.valueOf(Math.mod(i * 13 + c, 90) + 10).leftPad(2, '0')
        ));
    }
}
insert contacts;

System.debug('=== SEED 01 COMPLETE ===');
System.debug('Products added: ' + newProducts.size() + ' | Price book entries added: ' + newEntries.size());
System.debug('Accounts added: ' + toInsert.size() + ' | Accounts updated: ' + toUpdate.size() + ' | Contacts added: ' + contacts.size());
System.debug('DEMO accounts now: ' + [SELECT COUNT() FROM Account WHERE Name LIKE 'DEMO %']);
