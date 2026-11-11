@IsTest
private class AccountPriorityServiceTest {

    @TestSetup
    static void setup() {
        Account solo = new Account(Name = 'TEST Solo Clinic', BillingCity = 'Chicago');
        Account twinA = new Account(Name = 'TEST Twin Supply', BillingCity = 'Seattle');
        Account twinB = new Account(Name = 'TEST Twin Supply', BillingCity = 'Tacoma');
        Account empty = new Account(Name = 'TEST Empty Logistics', BillingCity = 'Dallas');
        insert new List<Account>{ solo, twinA, twinB, empty };

        insert new Contact(AccountId = solo.Id, LastName = 'Buyer');
        insert new Opportunity(AccountId = solo.Id, Name = 'TEST Solo Opp', StageName = openStage(), CloseDate = Date.today().addDays(30));

        insert new List<Account_Priority__c>{
            priority(solo.Id, 'TEST Solo P1', 1, 'Open', 70),
            priority(solo.Id, 'TEST Solo P2', 2, 'Open', 85),
            priority(solo.Id, 'TEST Solo P3', 3, 'Actioned', 99),
            priority(twinA.Id, 'TEST Twin A P1', 1, 'Open', 60)
        };
    }

    private static Account_Priority__c priority(Id accountId, String name, Integer rank, String status, Integer score) {
        return new Account_Priority__c(
            Account__c = accountId,
            Name = name,
            Priority_Rank__c = rank,
            Priority_Reason__c = name + ' reason',
            Recommended_Action__c = name + ' action',
            Status__c = status,
            Signal_Type__c = 'Spend Decline',
            Propensity_Score__c = score,
            Estimated_Value__c = 1000 * rank
        );
    }

    private static String openStage() {
        return [SELECT ApiName FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].ApiName;
    }

    private static AccountPriorityService.Response run(String recordId, String accountName) {
        AccountPriorityService.Request req = new AccountPriorityService.Request();
        req.recordId = recordId;
        req.accountName = accountName;
        return AccountPriorityService.getPriorities(new List<AccountPriorityService.Request>{ req })[0];
    }

    private static List<Object> priorities(AccountPriorityService.Response res) {
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.prioritiesJson);
        return (List<Object>) body.get('priorities');
    }

    @IsTest
    static void byName_returnsOnlyOpenPrioritiesInRankOrder() {
        Test.startTest();
        AccountPriorityService.Response res = run(null, 'TEST Solo Clinic');
        Test.stopTest();

        Assert.isTrue(res.isSuccess);
        Assert.areEqual('ACCOUNT', res.scope);
        Assert.areEqual('TEST Solo Clinic', res.resolvedAccountName);
        Assert.areEqual(String.valueOf(Date.today()), res.today);
        Assert.areEqual(2, res.priorityCount, 'Actioned priority must be excluded');
        List<Object> rows = priorities(res);
        Assert.areEqual('TEST Solo P1 reason', ((Map<String, Object>) rows[0]).get('reason'), 'Rank 1 first');
    }

    @IsTest
    static void byPartialName_resolvesSingleMatch() {
        AccountPriorityService.Response res = run(null, 'Solo Clin');
        Assert.isTrue(res.isSuccess);
        Assert.areEqual('TEST Solo Clinic', res.resolvedAccountName);
    }

    @IsTest
    static void byAccountId_resolves() {
        Account solo = [SELECT Id FROM Account WHERE Name = 'TEST Solo Clinic'];
        AccountPriorityService.Response res = run(solo.Id, null);
        Assert.isTrue(res.isSuccess);
        Assert.areEqual(String.valueOf(solo.Id), res.accountId);
    }

    @IsTest
    static void byContactAndOpportunityId_resolveToParentAccount() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Buyer'];
        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TEST Solo Opp'];
        Assert.areEqual('TEST Solo Clinic', run(c.Id, null).resolvedAccountName);
        Assert.areEqual('TEST Solo Clinic', run(o.Id, null).resolvedAccountName);
    }

    @IsTest
    static void duplicateName_returnsAmbiguousWithCandidates() {
        AccountPriorityService.Response res = run(null, 'TEST Twin Supply');
        Assert.isFalse(res.isSuccess);
        Assert.areEqual('ACCOUNT_AMBIGUOUS', res.errorType);
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.prioritiesJson);
        Assert.areEqual(2, ((List<Object>) body.get('candidates')).size());
    }

    @IsTest
    static void unknownName_returnsNotFound() {
        AccountPriorityService.Response res = run(null, 'No Such Account Anywhere');
        Assert.isFalse(res.isSuccess);
        Assert.areEqual('ACCOUNT_NOT_FOUND', res.errorType);
    }

    @IsTest
    static void invalidRecordId_returnsNotFound() {
        AccountPriorityService.Response res = run('not-an-id', null);
        Assert.isFalse(res.isSuccess);
        Assert.areEqual('ACCOUNT_NOT_FOUND', res.errorType);
    }

    @IsTest
    static void accountWithNoPriorities_returnsZero() {
        AccountPriorityService.Response res = run(null, 'TEST Empty Logistics');
        Assert.isTrue(res.isSuccess);
        Assert.areEqual(0, res.priorityCount);
    }

    @IsTest
    static void blankInputs_returnBookSortedByScope() {
        // Test data is owned by the running user, so all open priorities are in "my book".
        AccountPriorityService.Response res = run('', '  ');
        Assert.isTrue(res.isSuccess);
        Assert.areEqual('BOOK', res.scope);
        Assert.areEqual(3, res.priorityCount, '3 open priorities across 2 accounts');
        Map<String, Object> first = (Map<String, Object>) priorities(res)[0];
        Assert.areEqual(85, Integer.valueOf(first.get('score')), 'Highest score first');
        Assert.areEqual('TEST Solo Clinic', first.get('accountName'));
    }

    @IsTest
    static void book_excludesAccountsOwnedByOthers() {
        User other = otherUser();
        Account mine = [SELECT Id FROM Account WHERE Name = 'TEST Solo Clinic'];
        mine.OwnerId = other.Id;
        update mine;

        AccountPriorityService.Response res = run(null, null);
        Assert.areEqual(1, res.priorityCount, 'Only the Twin A priority is still in my book');
    }

    private static User otherUser() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        User u = new User(
            ProfileId = profileId,
            LastName = 'Other',
            Alias = 'pothr',
            Email = 'other.seller@example.com',
            Username = 'priority.other.' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        // runAs isolates the setup-object insert from the Account update (avoids MIXED_DML_OPERATION).
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert u;
        }
        return u;
    }
}
