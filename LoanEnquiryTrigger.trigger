trigger LoanEnquiryTrigger on Loan_Enquiry__c (before insert, after insert) {

    if (Trigger.isBefore && Trigger.isInsert) {
        LoanEnquiryTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        LoanEnquiryTriggerHandler.handleAfterInsert(Trigger.new);
    }
}