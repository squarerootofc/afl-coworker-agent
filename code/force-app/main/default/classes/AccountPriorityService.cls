/**
 * AccountPriorityService
 * Invocable action for the Priority Follow-Through agent.
 * Returns open account priorities for one account, or across the running user's book.
 * Error contract matches AccountContextService (ACCOUNT_REQUIRED, ACCOUNT_NOT_FOUND, ACCOUNT_AMBIGUOUS).
 */
public with sharing class AccountPriorityService {

    @TestVisible private static final Integer MAX_BOOK_PRIORITIES = 10;
    @TestVisible private static final String STATUS_OPEN = 'Open';

    public class Request {
        @InvocableVariable(label='Record ID' description='Account, Contact, or Opportunity ID. Leave blank for the whole book of the seller.')
        public String recordId;

        @InvocableVariable(label='Account Name' description='Exact or partial account name. Leave blank for the whole book of the seller.')
        public String accountName;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True if the lookup ran, false on an error')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Type' description='ACCOUNT_NOT_FOUND or ACCOUNT_AMBIGUOUS when isSuccess is false')
        public String errorType;

        @InvocableVariable(label='Error Message' description='Human-readable error message')
        public String errorMessage;

        @InvocableVariable(label='Scope' description='ACCOUNT when one account was resolved, BOOK for the whole book of the seller')
        public String scope;

        @InvocableVariable(label='Account ID' description='Resolved account Id when scope is ACCOUNT')
        public String accountId;

        @InvocableVariable(label='Account Name' description='Resolved account name when scope is ACCOUNT')
        public String resolvedAccountName;

        @InvocableVariable(label='Priority Count' description='Number of open priorities returned')
        public Integer priorityCount;

        @InvocableVariable(label='Priorities JSON' description='Open priorities, or candidate accounts when ambiguous')
        public String prioritiesJson;

        @InvocableVariable(label='Today' description='Current date as YYYY-MM-DD, so the agent can turn "Friday" into a date')
        public String today;
    }

    @InvocableMethod(label='Get Account Priorities' description='Returns open account priorities for one account, or the top open priorities across the book of the seller' category='Sales Assistant')
    public static List<Response> getPriorities(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            responses.add(handle(req));
        }
        return responses;
    }

    private static Response handle(Request req) {
        Response res = resolve(req);
        res.today = String.valueOf(Date.today());
        return res;
    }

    private static Response resolve(Request req) {
        Boolean hasRecord = req != null && String.isNotBlank(req.recordId);
        Boolean hasName = req != null && String.isNotBlank(req.accountName);

        if (!hasRecord && !hasName) {
            return bookResponse();
        }

        List<Account> matches = hasRecord ? resolveById(req.recordId.trim()) : resolveByName(req.accountName.trim());
        if (matches.isEmpty()) {
            return errorResponse('ACCOUNT_NOT_FOUND', 'No account matches that name or record.');
        }
        if (matches.size() > 1) {
            Response res = errorResponse('ACCOUNT_AMBIGUOUS', matches.size() + ' accounts share that name.');
            List<Map<String, Object>> candidates = new List<Map<String, Object>>();
            for (Account acc : matches) {
                candidates.add(new Map<String, Object>{
                    'id' => acc.Id,
                    'name' => acc.Name,
                    'billingCity' => acc.BillingCity,
                    'billingState' => acc.BillingState
                });
            }
            res.prioritiesJson = JSON.serialize(new Map<String, Object>{ 'candidates' => candidates });
            return res;
        }
        return accountResponse(matches[0]);
    }

    private static List<Account> resolveById(String rawId) {
        Id recordId;
        try {
            recordId = Id.valueOf(rawId);
        } catch (Exception e) {
            return new List<Account>();
        }
        Id accountId;
        SObjectType sType = recordId.getSobjectType();
        if (sType == Account.SObjectType) {
            accountId = recordId;
        } else if (sType == Contact.SObjectType) {
            List<Contact> rows = [SELECT AccountId FROM Contact WHERE Id = :recordId WITH USER_MODE LIMIT 1];
            accountId = rows.isEmpty() ? null : rows[0].AccountId;
        } else if (sType == Opportunity.SObjectType) {
            List<Opportunity> rows = [SELECT AccountId FROM Opportunity WHERE Id = :recordId WITH USER_MODE LIMIT 1];
            accountId = rows.isEmpty() ? null : rows[0].AccountId;
        }
        if (accountId == null) {
            return new List<Account>();
        }
        return [SELECT Id, Name, BillingCity, BillingState FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
    }

    private static List<Account> resolveByName(String name) {
        List<Account> exact = [
            SELECT Id, Name, BillingCity, BillingState FROM Account
            WHERE Name = :name WITH USER_MODE ORDER BY BillingCity LIMIT 10
        ];
        if (!exact.isEmpty()) {
            return exact;
        }
        // Bind variables are injection-safe; escapeSingleQuotes here would break names with apostrophes.
        String pattern = '%' + name + '%';
        return [
            SELECT Id, Name, BillingCity, BillingState FROM Account
            WHERE Name LIKE :pattern WITH USER_MODE ORDER BY Name, BillingCity LIMIT 10
        ];
    }

    private static Response accountResponse(Account acc) {
        List<Account_Priority__c> rows = [
            SELECT Id, Name, Account__c, Account__r.Name, Account__r.BillingCity, Priority_Rank__c,
                   Priority_Reason__c, Recommended_Action__c, Signal_Type__c, Propensity_Score__c,
                   Estimated_Value__c, Refreshed_On__c
            FROM Account_Priority__c
            WHERE Account__c = :acc.Id AND Status__c = :STATUS_OPEN
            WITH USER_MODE
            ORDER BY Priority_Rank__c ASC NULLS LAST, Propensity_Score__c DESC NULLS LAST
        ];
        Response res = successResponse('ACCOUNT', rows);
        res.accountId = acc.Id;
        res.resolvedAccountName = acc.Name;
        return res;
    }

    private static Response bookResponse() {
        Id me = UserInfo.getUserId();
        List<Account_Priority__c> rows = [
            SELECT Id, Name, Account__c, Account__r.Name, Account__r.BillingCity, Priority_Rank__c,
                   Priority_Reason__c, Recommended_Action__c, Signal_Type__c, Propensity_Score__c,
                   Estimated_Value__c, Refreshed_On__c
            FROM Account_Priority__c
            WHERE Account__r.OwnerId = :me AND Status__c = :STATUS_OPEN
            WITH USER_MODE
            ORDER BY Propensity_Score__c DESC NULLS LAST, Priority_Rank__c ASC NULLS LAST
            LIMIT :MAX_BOOK_PRIORITIES
        ];
        return successResponse('BOOK', rows);
    }

    private static Response successResponse(String scope, List<Account_Priority__c> rows) {
        List<Map<String, Object>> priorities = new List<Map<String, Object>>();
        for (Account_Priority__c p : rows) {
            priorities.add(new Map<String, Object>{
                'id' => p.Id,
                'accountId' => p.Account__c,
                'accountName' => p.Account__r.Name,
                'accountCity' => p.Account__r.BillingCity,
                'rank' => p.Priority_Rank__c,
                'reason' => p.Priority_Reason__c,
                'recommendedAction' => p.Recommended_Action__c,
                'signalType' => p.Signal_Type__c,
                'score' => p.Propensity_Score__c,
                'estimatedValue' => p.Estimated_Value__c,
                'refreshedOn' => p.Refreshed_On__c
            });
        }
        Response res = new Response();
        res.isSuccess = true;
        res.scope = scope;
        res.priorityCount = priorities.size();
        res.prioritiesJson = JSON.serialize(new Map<String, Object>{ 'priorities' => priorities });
        return res;
    }

    private static Response errorResponse(String errorType, String message) {
        Response res = new Response();
        res.isSuccess = false;
        res.errorType = errorType;
        res.errorMessage = message;
        res.priorityCount = 0;
        return res;
    }
}
