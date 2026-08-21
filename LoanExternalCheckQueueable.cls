public with sharing class LoanExternalCheckQueueable
    implements Queueable, Database.AllowsCallouts {

    private Id loanEnquiryId;
    private Integer attemptNumber;

    @TestVisible
    private static Boolean disableRetryForTest = false;

    public LoanExternalCheckQueueable(
        Id loanEnquiryId,
        Integer attemptNumber
    ) {
        this.loanEnquiryId = loanEnquiryId;
        this.attemptNumber = attemptNumber;
    }

    public void execute(QueueableContext context) {

        // Get Loan Enquiry
        List<Loan_Enquiry__c> enquiries = [
            SELECT Id,
                   External_Check_Result__c,
                   External_Check_Status__c
            FROM Loan_Enquiry__c
            WHERE Id = :loanEnquiryId
            LIMIT 1
        ];

        // Enforce field-level security for READ
        SObjectAccessDecision readDecision =
            Security.stripInaccessible(
                AccessType.READABLE,
                enquiries
            );

        List<Loan_Enquiry__c> accessibleEnquiries =
            (List<Loan_Enquiry__c>) readDecision.getRecords();

        if (accessibleEnquiries.isEmpty()) {
            return;
        }

        Loan_Enquiry__c enquiry =
            accessibleEnquiries[0];


        // --------------------------------------------------
        // Create HTTP Request
        // --------------------------------------------------

        HttpRequest request = new HttpRequest();

        // Named Credential
        request.setEndpoint(
            'callout:JSONPlaceholder/users/1'
        );

        request.setMethod('GET');
        request.setTimeout(10000);


        // --------------------------------------------------
        // Execute Callout
        // --------------------------------------------------

        try {

            HttpResponse response =
                new Http().send(request);


            // --------------------------------------------------
            // SUCCESS
            // --------------------------------------------------

            if (
                response.getStatusCode() >= 200 &&
                response.getStatusCode() < 300
            ) {

                Map<String, Object> responseData =
                    (Map<String, Object>)
                    JSON.deserializeUntyped(
                        response.getBody()
                    );


                String result =
                    'External check completed for user ' +
                    String.valueOf(
                        responseData.get('name')
                    );


                enquiry.External_Check_Result__c =
                    result;

                enquiry.External_Check_Status__c =
                    'Success';


                // Update Loan Enquiry
                updateLoanEnquiry(enquiry);


                // Create Success Audit Log
                Loan_External_Check_Log__c logRecord =
                    new Loan_External_Check_Log__c();

                logRecord.Loan_Enquiry__c =
                    enquiry.Id;

                logRecord.Attempt_Number__c =
                    attemptNumber;

                logRecord.Attempt_Date__c =
                    System.now();

                logRecord.Status__c =
                    'Success';

                logRecord.Response__c =
                    response.getBody();


                insertLog(logRecord);

            }


            // --------------------------------------------------
            // HTTP FAILURE
            // --------------------------------------------------

            else {

                handleFailure(
                    enquiry,
                    'HTTP Error: ' +
                    response.getStatusCode(),
                    response.getBody()
                );
            }

        }


        // --------------------------------------------------
        // EXCEPTION
        // --------------------------------------------------

        catch (Exception e) {

            handleFailure(
                enquiry,
                e.getMessage(),
                null
            );
        }
    }


    // ======================================================
    // HANDLE FAILURE
    // ======================================================

    private void handleFailure(
        Loan_Enquiry__c enquiry,
        String errorMessage,
        String responseBody
    ) {

        // --------------------------------------------------
        // Set status
        //
        // Attempt 1 → Pending because retry will happen
        // Attempt 2 → Failed because retry is exhausted
        // --------------------------------------------------

        if (attemptNumber < 2) {

            enquiry.External_Check_Status__c =
                'Pending';

        } else {

            enquiry.External_Check_Status__c =
                'Failed';
        }


        // Update Loan Enquiry
        updateLoanEnquiry(enquiry);


        // --------------------------------------------------
        // Create Failure Audit Log
        // --------------------------------------------------

        Loan_External_Check_Log__c logRecord =
            new Loan_External_Check_Log__c();

        logRecord.Loan_Enquiry__c =
            enquiry.Id;

        logRecord.Attempt_Number__c =
            attemptNumber;

        logRecord.Attempt_Date__c =
            System.now();

        logRecord.Status__c =
            'Failed';

        logRecord.Error_Message__c =
            errorMessage;

        logRecord.Response__c =
            responseBody;


        insertLog(logRecord);


        // --------------------------------------------------
        // Retry only once
        // --------------------------------------------------

        if (attemptNumber < 2 && !disableRetryForTest) {

    System.enqueueJob(
        new LoanExternalCheckQueueable(
            enquiry.Id,
            attemptNumber + 1
        )
    );
}
    }


    // ======================================================
    // UPDATE LOAN ENQUIRY
    // ======================================================

    private static void updateLoanEnquiry(
        Loan_Enquiry__c enquiry
    ) {

        SObjectAccessDecision decision =
            Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<Loan_Enquiry__c>{
                    enquiry
                }
            );

        List<Loan_Enquiry__c> records =
            (List<Loan_Enquiry__c>)
            decision.getRecords();


        if (!records.isEmpty()) {

            update records;
        }
    }


    // ======================================================
    // INSERT AUDIT LOG
    // ======================================================

    private static void insertLog(
        Loan_External_Check_Log__c logRecord
    ) {

        SObjectAccessDecision decision =
            Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Loan_External_Check_Log__c>{
                    logRecord
                }
            );

        List<Loan_External_Check_Log__c> records =
            (List<Loan_External_Check_Log__c>)
            decision.getRecords();


        if (!records.isEmpty()) {

            insert records;
        }
    }
}