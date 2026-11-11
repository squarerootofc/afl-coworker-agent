@IsTest
private class PriorityActionServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'DEMO Test Clinic', BillingCity = 'Chicago');
        insert acc;
        insert new List<Account_Priority__c>{
            new Account_Priority__c(Account__c = acc.Id, Name = 'TEST Open', Status__c = 'Open', Priority_Rank__c = 1,
                Priority_Reason__c = 'Furniture spend down 22%', Recommended_Action__c = 'Offer a furniture review',
                Estimated_Value__c = 18000),
            new Account_Priority__c(Account__c = acc.Id, Name = 'TEST Done', Status__c = 'Actioned', Priority_Rank__c = 2,
                Priority_Reason__c = 'Done already', Recommended_Action__c = 'Nothing')
        };
    }

    private static Account_Priority__c open() {
        return [SELECT Id FROM Account_Priority__c WHERE Name = 'TEST Open'];
    }

    private static PriorityActionService.Response run(String priorityId, String type, String subject, String dueDate, Decimal amount) {
        PriorityActionService.Request req = new PriorityActionService.Request();
        req.priorityId = priorityId;
        req.actionType = type;
        req.subject = subject;
        req.dueDate = dueDate;
        req.amount = amount;
        return PriorityActionService.logAction(new List<PriorityActionService.Request>{ req })[0];
    }

    @IsTest
    static void task_createsTaskAndActionsPriority() {
        Id pid = open().Id;
        String due = String.valueOf(Date.today().addDays(3));

        Test.startTest();
        PriorityActionService.Response res = run(pid, 'Task', 'Call about furniture review', due, null);
        Test.stopTest();

        Assert.isTrue(res.isSuccess, res.message);
        Assert.areEqual('Task', res.recordType);
        Task t = [SELECT Subject, ActivityDate, WhatId, Status FROM Task WHERE Id = :res.recordId];
        Assert.areEqual('Call about furniture review', t.Subject);
        Assert.areEqual(Date.today().addDays(3), t.ActivityDate);
        Assert.areEqual([SELECT Id FROM Account WHERE Name = 'DEMO Test Clinic'].Id, t.WhatId);
        Assert.isNotNull(t.Status, 'Default task status read from the org');

        Account_Priority__c p = [SELECT Status__c, Actioned_On__c, Action_Record_Id__c FROM Account_Priority__c WHERE Id = :pid];
        Assert.areEqual('Actioned', p.Status__c);
        Assert.areEqual(Date.today(), p.Actioned_On__c);
        Assert.areEqual(res.recordId, p.Action_Record_Id__c);
    }

    @IsTest
    static void task_defaultsSubjectAndDueDate() {
        PriorityActionService.Response res = run(open().Id, null, null, null, null);
        Assert.isTrue(res.isSuccess, res.message);
        Task t = [SELECT Subject, ActivityDate FROM Task WHERE Id = :res.recordId];
        Assert.areEqual('Offer a furniture review', t.Subject);
        Assert.areEqual(Date.today().addDays(7), t.ActivityDate);
    }

    @IsTest
    static void opportunity_usesEstimatedValueAndFirstOpenStage() {
        PriorityActionService.Response res = run(open().Id, 'opportunity', null, null, 0);
        Assert.isTrue(res.isSuccess, res.message);
        Opportunity o = [SELECT Name, Amount, StageName, CloseDate, IsClosed FROM Opportunity WHERE Id = :res.recordId];
        Assert.areEqual(18000, o.Amount, 'Amount 0 falls back to estimated value');
        Assert.isFalse(o.IsClosed);
        Assert.areEqual(Date.today().addDays(30), o.CloseDate);
        Assert.areEqual('Test Clinic - Offer a furniture review', o.Name, 'DEMO prefix removed from the name');
    }

    @IsTest
    static void opportunity_usesSellerAmount() {
        PriorityActionService.Response res = run(open().Id, 'Opportunity', 'Clinic refresh', null, 25000);
        Assert.isTrue(res.isSuccess, res.message);
        Assert.areEqual(25000, [SELECT Amount FROM Opportunity WHERE Id = :res.recordId].Amount);
    }

    @IsTest
    static void secondCall_isRejected_noDuplicate() {
        Id pid = open().Id;
        Assert.isTrue(run(pid, 'Task', null, null, null).isSuccess);

        PriorityActionService.Response second = run(pid, 'Task', null, null, null);
        Assert.isFalse(second.isSuccess);
        Assert.areEqual('PRIORITY_NOT_OPEN', second.errorType);
        Id accountId = [SELECT Id FROM Account WHERE Name = 'DEMO Test Clinic'].Id;
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :accountId]);
    }

    @IsTest
    static void actionedPriority_isRejected() {
        Id done = [SELECT Id FROM Account_Priority__c WHERE Name = 'TEST Done'].Id;
        PriorityActionService.Response res = run(done, 'Task', null, null, null);
        Assert.isFalse(res.isSuccess);
        Assert.areEqual('PRIORITY_NOT_OPEN', res.errorType);
    }

    @IsTest
    static void badInputs_returnErrorsWithoutWriting() {
        Id pid = open().Id;
        Assert.areEqual('INVALID_ACTION_TYPE', run(pid, 'Email', null, null, null).errorType);
        Assert.areEqual('INVALID_DATE', run(pid, 'Task', null, 'next friday', null).errorType);
        Assert.areEqual('INVALID_DATE', run(pid, 'Task', null, String.valueOf(Date.today().addDays(-1)), null).errorType);
        Assert.areEqual('PRIORITY_NOT_FOUND', run('not-an-id', 'Task', null, null, null).errorType);
        Assert.areEqual(0, [SELECT COUNT() FROM Task]);
        Assert.areEqual('Open', [SELECT Status__c FROM Account_Priority__c WHERE Id = :pid].Status__c);
    }

    @IsTest
    static void deletedPriority_returnsNotFound() {
        Account_Priority__c p = open();
        delete p;
        Assert.areEqual('PRIORITY_NOT_FOUND', run(p.Id, 'Task', null, null, null).errorType);
    }
}
