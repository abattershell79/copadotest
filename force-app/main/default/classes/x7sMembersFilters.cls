/*
 * Copyright (c) 2020. 7Summits Inc.
 */

/**
 * Members filter management
 */
public with sharing class x7sMembersFilters {
    private final static String FIELD_SEPARATOR = '\\.';
    private final static String MEMBER_RECORD = 'Member';
    private final static String FIELD_NAME = 'Name';
    private final static String FILTER_RECORD = 'X7S_Members_Filter_Entry__c';
    private final static String FILTER_PARENT = 'Filter__r.Name';
    private final Integer MAXCMTLIMIT = 100;

    // Filter set
    public List<X7S_Members_Filter_Item__mdt> filters { get; set; }

    // Filter settings
    public Decimal PickList_Limit { get; set; }
    public Boolean SendNotification { get; set; }

    public x7sMembersFilters() {
        X7S_Members_Filter_Setting__mdt settings = [    //NOPMD
                SELECT Filter_List_Limit__c, Send_Email_Notification__c
                FROM X7S_Members_Filter_Setting__mdt
                WHERE DeveloperName = 'Default'
        ];

        PickList_Limit = settings.Filter_List_Limit__c;
        SendNotification = settings.Send_Email_Notification__c;

        Map<Id, X7S_Members_Filter_Item__mdt> allFilters = new Map<Id, X7S_Members_Filter_Item__mdt>([
                SELECT Id, DeveloperName, Field_Name__c
                FROM X7S_Members_Filter_Item__mdt
                LIMIT :MAXCMTLIMIT
        ]);

        filters = allFilters.values();
    }

    public X7S_Members_Filter_Item__mdt getFilterByName(String name) {
        for (X7S_Members_Filter_Item__mdt filter : filters) {
            if (filter.DeveloperName == name) {
                return filter;
            }
        }

        return null;
    }

    public X7S_Members_Filter_Item__mdt getFilterByFieldName(String fieldName) {
        String fieldStringValue = String.escapeSingleQuotes(fieldName);
        String fieldString = fieldStringValue.startsWith(MEMBER_RECORD)
                ? fieldStringValue
                : MEMBER_RECORD + '.' + fieldStringValue;


        for (X7S_Members_Filter_Item__mdt filter : filters) {
            if (filter.Field_Name__c == fieldString) {
                return filter;
            }
        }

        return null;
    }

    public X7S_Members_Filter__c clearFilter(String filterName) {
        List<X7S_Members_Filter__c> filterItems = [SELECT Id, Name FROM X7S_Members_Filter__c WHERE Name = :filterName WITH SECURITY_ENFORCED];

        if (filterItems.size() > 0) {
            if (X7S_Members_Filter__c.sObjectType.getDescribe().isDeletable()) {
                delete filterItems;
            }
        }

        if (X7S_Members_Filter__c.SObjectType.getDescribe().isCreateable()) {
            X7S_Members_Filter__c newFilter = new X7S_Members_Filter__c(Name = filterName);
            insert newFilter;
        }
        filterItems = [SELECT Id, Name FROM X7S_Members_Filter__c WHERE Name = :filterName];
        return filterItems[0];
    }

    public List<String> getFieldRecords(X7S_Members_Filter_Item__mdt filter) {
        List<String> records = new List<String>();
        List<String>fieldParts = filter.Field_Name__c.split(FIELD_SEPARATOR);

        for (Integer count = 0; count < fieldParts.size() - 1; count++) {
            records.add(fieldParts[count]);
        }

        return records;
    }

    public String getFieldName(X7S_Members_Filter_Item__mdt filter) {
        List<String>fieldParts = filter.Field_Name__c.split(FIELD_SEPARATOR);
        String fieldName = fieldParts[fieldParts.size() - 1];

        return fieldName;
    }

    public List<String> getFilterValues(String fieldName, String searchString) {
        X7S_Members_Filter_Item__mdt filter = getFilterByFieldName(fieldName);

        return getFilterValues(filter, searchString);
    }

    public List<String> getFilterValues(X7S_Members_Filter_Item__mdt filter, String searchString) {
        List<String> values = new List<String>();
        Integer recordLimit = (Integer) this.PickList_Limit;

        String query = 'SELECT ' + FIELD_NAME;
        query += ' FROM ' + FILTER_RECORD;
        query += ' WHERE ' + FILTER_PARENT;
        query += ' = \'' + filter.DeveloperName + '\'';

        if (String.isNotBlank(searchString)) {
            query += ' AND  Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'';
        }

        query += ' ORDER BY ' + FIELD_NAME;
        query += ' LIMIT ' + recordLimit;

        System.debug('getFilterValues from Filter object qry: ' + query);

        List<X7S_Members_Filter_Entry__c> results = Database.query(query);
        for (X7S_Members_Filter_Entry__c entry : results) {
            values.add(entry.Name);
        }

        System.debug('    found : ' + values.size());
        return values;

    }

    public List<X7S_Members_Filter_Entry__c> getFilterEntries(X7S_Members_Filter_Item__mdt filter) {
        List<X7S_Members_Filter_Entry__c> entries = new List<X7S_Members_Filter_Entry__c>();
        Integer recordLimit = (Integer) this.PickList_Limit;

        String query = 'SELECT ' + FIELD_NAME;
        query += ' FROM ' + FILTER_RECORD;
        query += ' WHERE ' + FILTER_PARENT;
        query += ' = \'' + filter.DeveloperName + '\'';

        query += ' ORDER BY ' + FIELD_NAME;
        query += ' LIMIT ' + recordLimit;

        System.debug('getFilterEntries from Filter object qry: ' + query);

        entries = Database.query(query);

        return entries;
    }

    public void notifyBatchCompletion(Database.BatchableContext bc, X7S_Members_Filter__c filter, Integer count) {
        if (!SendNotification) {
            return;
        }

        AsyncApexJob job = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob
                WHERE Id = :bc.getJobId()
                WITH SECURITY_ENFORCED
        ];

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        String[] toAddresses = new String[]{
                job.CreatedBy.Email
        };
        email.setToAddresses(toAddresses);


        List<String> params = new String[]{
                filter.Name,
                String.valueOf(job.TotalJobItems),
                String.valueOf(job.JobItemsProcessed),
                String.valueOf(job.NumberOfErrors),
                String.valueOf(count)
        };

        email.setSubject(String.format(System.Label.x7sMemberBatchFilterSubject, params) + job.Status);
        email.setPlainTextBody(String.format(System.Label.x7sMembersBatchFilterBody, params));

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                email
        });
    }
}