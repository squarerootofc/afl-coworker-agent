/**
 * PriorityActionService
 * Invocable action for the Priority Follow-Through agent.
 * Turns one open account priority into a Task or an Opportunity and marks the priority Actioned,
 * in one transaction. The agent only exposes this action after the seller confirms.
 */
public with sharing class PriorityActionService {

    @TestVisible private static final String TYPE_TASK = 'Task';
    @TestVisible private static final String TYPE_OPPORTUNITY = 'Opportunity';
    @TestVisible private static final Integer DEFAULT_TASK_DAYS = 7;
    @TestVisible private static final Integer DEFAULT_CLOSE_DAYS = 30;

    public class Request {
        @InvocableVariable(label='Priority ID' description='Id of the open account priority to act on' required=true)
        public String priorityId;

        @InvocableVariable(label='Action Type' description='Task or Opportunity')
        public String actionType;

        @InvocableVariable(label='Subject' description='Task subject or Opportunity name. Defaults to the recommended action.')
        public String subject;

        @InvocableVariable(label='Due Date' description='Task due date or Opportunity close date as YYYY-MM-DD. Defaults to 7 or 30 days out.')
        public String dueDate;

        @InvocableVariable(label='Amount' description='Opportunity amount. 0 or blank uses the estimated value on the priority.')
        public Decimal amount;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True if the record was created and the priority actioned')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Type' description='PRIORITY_NOT_FOUND, PRIORITY_NOT_OPEN, INVALID_ACTION_TYPE, INVALID_DATE or SAVE_FAILED')
        public String errorType;

        @InvocableVariable(label='Message' description='What happened, in plain language')
        public String message;

        @InvocableVariable(label='Record ID' description='Id of the Task or Opportunity created')
        public String recordId;

        @InvocableVariable(label='Record Type' description='Task or Opportunity')
        public String recordType;

        @InvocableVariable(label='Record Name' description='Task subject or Opportunity name')
        public String recordName;
    }

    @InvocableMethod(label='Log Priority Action' description='Creates a Task or Opportunity from one open account priority and marks the priority Actioned' category='Sales Assistant')
    public static List<Response> logAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        // The agent sends one request per call; each gets its own savepoint inside handle().
        for (Request req : requests) {
            responses.add(handle(req));
        }
        return responses;
    }

    private static Response handle(Request req) {
        String actionType = normalizeType(req.actionType);
        if (actionType == null) {
            return errorResponse('INVALID_ACTION_TYPE', 'Action type must be Task or Opportunity.');
        }
        Date dueDate;
        if (String.isNotBlank(req.dueDate)) {
            try {
                dueDate = Date.valueOf(req.dueDate.trim());
            } catch (Exception e) {
                return errorResponse('INVALID_DATE', 'The date must be in YYYY-MM-DD format.');
            }
            if (dueDate < Date.today()) {
                return errorResponse('INVALID_DATE', 'The date can\'t be in the past.');
            }
        }

        Id priorityId;
        try {
            priorityId = Id.valueOf(req.priorityId);
        } catch (Exception e) {
            return errorResponse('PRIORITY_NOT_FOUND', 'That priority doesn\'t exist or you don\'t have access to it.');
        }

        List<Account_Priority__c> rows = [
            SELECT Id, Name, Status__c, Account__c, Account__r.Name, Priority_Reason__c,
                   Recommended_Action__c, Estimated_Value__c
            FROM Account_Priority__c
            WHERE Id = :priorityId
            WITH USER_MODE
            LIMIT 1
            FOR UPDATE
        ];
        if (rows.isEmpty()) {
            return errorResponse('PRIORITY_NOT_FOUND', 'That priority doesn\'t exist or you don\'t have access to it.');
        }
        Account_Priority__c priority = rows[0];
        if (priority.Status__c != 'Open') {
            return errorResponse('PRIORITY_NOT_OPEN', 'That priority is already ' + priority.Status__c + '.');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            SObject created = actionType == TYPE_TASK
                ? (SObject) buildTask(req, priority, dueDate)
                : (SObject) buildOpportunity(req, priority, dueDate);
            insert as user created;

            priority.Status__c = 'Actioned';
            priority.Actioned_On__c = Date.today();
            priority.Action_Record_Id__c = created.Id;
            update as user priority;

            Response res = new Response();
            res.isSuccess = true;
            res.recordId = created.Id;
            res.recordType = actionType;
            res.recordName = (String) created.get(actionType == TYPE_TASK ? 'Subject' : 'Name');
            res.message = actionType + ' created for ' + priority.Account__r.Name + '. Priority marked Actioned.';
            return res;
        } catch (Exception e) {
            Database.rollback(sp);
            return errorResponse('SAVE_FAILED', e.getMessage());
        }
    }

    private static Task buildTask(Request req, Account_Priority__c priority, Date dueDate) {
        return new Task(
            WhatId = priority.Account__c,
            OwnerId = UserInfo.getUserId(),
            Subject = String.isNotBlank(req.subject) ? req.subject.left(255) : priority.Recommended_Action__c,
            ActivityDate = dueDate != null ? dueDate : Date.today().addDays(DEFAULT_TASK_DAYS),
            Status = defaultTaskStatus(),
            Priority = 'Normal',
            Description = 'From account priority ' + priority.Name + ': ' + priority.Priority_Reason__c
        );
    }

    private static Opportunity buildOpportunity(Request req, Account_Priority__c priority, Date dueDate) {
        String name = String.isNotBlank(req.subject)
            ? req.subject
            : priority.Account__r.Name.removeStart('DEMO ') + ' - ' + priority.Recommended_Action__c;
        return new Opportunity(
            AccountId = priority.Account__c,
            OwnerId = UserInfo.getUserId(),
            Name = name.left(120),
            StageName = firstOpenStage(),
            CloseDate = dueDate != null ? dueDate : Date.today().addDays(DEFAULT_CLOSE_DAYS),
            Amount = (req.amount != null && req.amount > 0) ? req.amount : priority.Estimated_Value__c,
            Description = 'From account priority ' + priority.Name + ': ' + priority.Priority_Reason__c
        );
    }

    // Stage and status names differ between orgs, so read them instead of hard-coding "Prospecting" or "Not Started".
    private static String firstOpenStage() {
        List<OpportunityStage> stages = [
            SELECT ApiName FROM OpportunityStage
            WHERE IsActive = true AND IsClosed = false
            ORDER BY SortOrder ASC LIMIT 1
        ];
        return stages.isEmpty() ? null : stages[0].ApiName;
    }

    private static String defaultTaskStatus() {
        List<TaskStatus> statuses = [SELECT ApiName FROM TaskStatus WHERE IsDefault = true LIMIT 1];
        return statuses.isEmpty() ? null : statuses[0].ApiName;
    }

    private static String normalizeType(String value) {
        if (String.isBlank(value) || value.trim().equalsIgnoreCase(TYPE_TASK)) {
            return TYPE_TASK;
        }
        if (value.trim().equalsIgnoreCase(TYPE_OPPORTUNITY) || value.trim().equalsIgnoreCase('Opp')) {
            return TYPE_OPPORTUNITY;
        }
        return null;
    }

    private static Response errorResponse(String errorType, String message) {
        Response res = new Response();
        res.isSuccess = false;
        res.errorType = errorType;
        res.message = message;
        return res;
    }
}
