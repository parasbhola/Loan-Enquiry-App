public with sharing class LoanEnquiryController {

    @AuraEnabled
    public static Id createLoanEnquiry(
        String applicantName,
        Decimal loanAmount,
        String loanPurpose
    ) {

        // Validation
        if (String.isBlank(applicantName)) {
            throw new AuraHandledException(
                'Applicant Name is required.'
            );
        }

        if (loanAmount == null || loanAmount <= 0) {
            throw new AuraHandledException(
                'Loan Amount must be greater than zero.'
            );
        }

        // Object-level CRUD check
        if (!Schema.sObjectType.Loan_Enquiry__c.isCreateable()) {
            throw new AuraHandledException(
                'You do not have permission to create a Loan Enquiry.'
            );
        }

        Loan_Enquiry__c enquiry = new Loan_Enquiry__c(
            Applicant_Name__c = applicantName,
            Loan_Amount__c = loanAmount,
            Loan_Purpose__c = loanPurpose,
            Status__c = 'New',
            External_Check_Status__c = 'Pending'
        );

        // Field-level security
        SObjectAccessDecision decision =
            Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Loan_Enquiry__c>{ enquiry }
            );

        List<Loan_Enquiry__c> accessibleEnquiries =
            (List<Loan_Enquiry__c>) decision.getRecords();

        if (accessibleEnquiries.isEmpty()) {
            throw new AuraHandledException(
                'You do not have permission to create this Loan Enquiry.'
            );
        }

        // Insert
        insert accessibleEnquiries;

        enquiry = accessibleEnquiries[0];

        // Start external check
        System.enqueueJob(
            new LoanExternalCheckQueueable(
                enquiry.Id,
                1
            )
        );

        return enquiry.Id;
    }


    @AuraEnabled(cacheable=true)
    public static List<Loan_Document__c> getLoanDocuments(
        Id loanEnquiryId
    ) {

        if (loanEnquiryId == null) {
            return new List<Loan_Document__c>();
        }

        // Object-level CRUD check
        if (!Schema.sObjectType.Loan_Document__c.isAccessible()) {
            throw new AuraHandledException(
                'You do not have permission to view Loan Documents.'
            );
        }

        List<Loan_Document__c> documents = [
            SELECT Id,
                   Name,
                   Document_Name__c,
                   Document_Type__c,
                   Uploaded_Date__c
            FROM Loan_Document__c
            WHERE Loan_Enquiry__c = :loanEnquiryId
            ORDER BY Uploaded_Date__c DESC
        ];

        // Field-level security
        SObjectAccessDecision decision =
            Security.stripInaccessible(
                AccessType.READABLE,
                documents
            );

        return (List<Loan_Document__c>) decision.getRecords();
    }


    @AuraEnabled
    public static Id createLoanDocument(
        Id loanEnquiryId,
        String documentName,
        String documentType,
        Date uploadedDate
    ) {

        // Validation
        if (loanEnquiryId == null) {
            throw new AuraHandledException(
                'Loan Enquiry is required.'
            );
        }

        if (String.isBlank(documentName)) {
            throw new AuraHandledException(
                'Document Name is required.'
            );
        }

        // Object-level CRUD check
        if (!Schema.sObjectType.Loan_Document__c.isCreateable()) {
            throw new AuraHandledException(
                'You do not have permission to create a Loan Document.'
            );
        }

        Loan_Document__c documentRecord =
            new Loan_Document__c(
                Loan_Enquiry__c = loanEnquiryId,
                Document_Name__c = documentName,
                Document_Type__c = documentType,
                Uploaded_Date__c = uploadedDate
            );

        // Field-level security
        SObjectAccessDecision decision =
            Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Loan_Document__c>{ documentRecord }
            );

        List<Loan_Document__c> accessibleDocuments =
            (List<Loan_Document__c>) decision.getRecords();

        if (accessibleDocuments.isEmpty()) {
            throw new AuraHandledException(
                'You do not have permission to create this Loan Document.'
            );
        }

        // Insert
        insert accessibleDocuments;

        documentRecord = accessibleDocuments[0];

        return documentRecord.Id;
    }
    
    @AuraEnabled(cacheable=true)
public static Loan_Enquiry__c getLoanStatus(Id loanEnquiryId) {

    if (loanEnquiryId == null) {
        throw new AuraHandledException(
            'Loan Enquiry ID is required.'
        );
    }

    List<Loan_Enquiry__c> enquiries = [
        SELECT Id,
               Applicant_Name__c,
               Loan_Amount__c,
               Loan_Purpose__c,
               Status__c,
               External_Check_Status__c,
               External_Check_Result__c
        FROM Loan_Enquiry__c
        WHERE Id = :loanEnquiryId
        LIMIT 1
    ];

    if (enquiries.isEmpty()) {
        throw new AuraHandledException(
            'Loan Enquiry not found.'
        );
    }

    return enquiries[0];
}
    
}