public with sharing class LoanEnquiryTriggerHandler {

    public static void handleBeforeInsert(
        List<Loan_Enquiry__c> loanEnquiries
    ) {

        for (Loan_Enquiry__c loan : loanEnquiries) {

            if (
                loan.Loan_Amount__c != null &&
                loan.Loan_Amount__c > 500000
            ) {
                loan.Status__c = 'Under Review';
            }
        }
    }


    public static void handleAfterInsert(
        List<Loan_Enquiry__c> loanEnquiries
    ) {

        List<Task> tasksToCreate =
            new List<Task>();

        for (Loan_Enquiry__c loan : loanEnquiries) {

            if (
                loan.Loan_Amount__c != null &&
                loan.Loan_Amount__c > 500000
            ) {

                Task reviewTask = new Task(
                    Subject =
                        'Manual review required — high value loan.',
                    OwnerId = loan.OwnerId,
                    WhatId = loan.Id
                );

                tasksToCreate.add(reviewTask);
            }
        }

        if (!tasksToCreate.isEmpty()) {

            SObjectAccessDecision decision =
                Security.stripInaccessible(
                    AccessType.CREATABLE,
                    tasksToCreate
                );

            List<Task> accessibleTasks =
                (List<Task>) decision.getRecords();

            if (!accessibleTasks.isEmpty()) {
                insert accessibleTasks;
            }
        }
    }
}