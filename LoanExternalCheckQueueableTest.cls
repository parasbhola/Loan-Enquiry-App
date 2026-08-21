@IsTest
private class LoanExternalCheckQueueableTest {

    // =====================================================
    // TEST DATA
    // =====================================================

    @TestSetup
    static void setupData() {

        Loan_Enquiry__c loan = new Loan_Enquiry__c(
            Applicant_Name__c = 'Test Applicant',
            Loan_Amount__c = 300000,
            Loan_Purpose__c = 'Home Purchase',
            Status__c = 'New',
            External_Check_Status__c = 'Pending'
        );

        insert loan;
    }


    // =====================================================
    // SUCCESS MOCK
    // =====================================================

    private class SuccessMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();

            response.setStatusCode(200);

            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setBody(
                '{"id":1,"name":"Test User","username":"testuser"}'
            );

            return response;
        }
    }


    // =====================================================
    // HTTP FAILURE MOCK
    // =====================================================

    private class FailureMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();

            response.setStatusCode(500);

            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setBody(
                '{"error":"External system unavailable"}'
            );

            return response;
        }
    }


    // =====================================================
    // EXCEPTION / TIMEOUT MOCK
    // =====================================================

    private class ExceptionMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            throw new CalloutException(
                'Simulated timeout'
            );
        }
    }


    // =====================================================
    // SUCCESSFUL CALLOUT
    // =====================================================

    @IsTest
    static void testSuccessfulCallout() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        System.enqueueJob(
            new LoanExternalCheckQueueable(
                loan.Id,
                1
            )
        );

        Test.stopTest();


        // -----------------------------------------------
        // Verify Loan Enquiry
        // -----------------------------------------------

        Loan_Enquiry__c updatedLoan = [
            SELECT
                External_Check_Status__c,
                External_Check_Result__c
            FROM Loan_Enquiry__c
            WHERE Id = :loan.Id
        ];

        System.assertEquals(
            'Success',
            updatedLoan.External_Check_Status__c
        );

        System.assert(
            updatedLoan.External_Check_Result__c.contains(
                'Test User'
            ),
            'External check result should contain Test User.'
        );


        // -----------------------------------------------
        // Verify Audit Log
        // -----------------------------------------------

        List<Loan_External_Check_Log__c> logs = [
            SELECT
                Status__c,
                Attempt_Number__c,
                Response__c
            FROM Loan_External_Check_Log__c
            WHERE Loan_Enquiry__c = :loan.Id
        ];

        System.assertEquals(
            1,
            logs.size()
        );

        System.assertEquals(
            'Success',
            logs[0].Status__c
        );

        System.assertEquals(
            1,
            logs[0].Attempt_Number__c
        );
    }


    // =====================================================
    // HTTP FAILURE - ATTEMPT 1
    // =====================================================

    @IsTest
    static void testFirstAttemptFailure() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new FailureMock()
        );

        // Prevent the retry from executing again in this test.
        LoanExternalCheckQueueable.disableRetryForTest = true;

        Test.startTest();

        System.enqueueJob(
            new LoanExternalCheckQueueable(
                loan.Id,
                1
            )
        );

        Test.stopTest();

        LoanExternalCheckQueueable.disableRetryForTest = false;


        // -----------------------------------------------
        // Verify status
        // -----------------------------------------------

        Loan_Enquiry__c updatedLoan = [
            SELECT External_Check_Status__c
            FROM Loan_Enquiry__c
            WHERE Id = :loan.Id
        ];

        System.assertEquals(
            'Pending',
            updatedLoan.External_Check_Status__c
        );


        // -----------------------------------------------
        // Verify audit log
        // -----------------------------------------------

        List<Loan_External_Check_Log__c> logs = [
            SELECT
                Status__c,
                Attempt_Number__c,
                Error_Message__c,
                Response__c
            FROM Loan_External_Check_Log__c
            WHERE Loan_Enquiry__c = :loan.Id
        ];

        System.assertEquals(
            1,
            logs.size()
        );

        System.assertEquals(
            'Failed',
            logs[0].Status__c
        );

        System.assertEquals(
            1,
            logs[0].Attempt_Number__c
        );

        System.assert(
            logs[0].Error_Message__c.contains(
                'HTTP Error: 500'
            )
        );
    }


    // =====================================================
    // SECOND ATTEMPT FAILURE
    // =====================================================

    @IsTest
    static void testSecondAttemptFailure() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new FailureMock()
        );

        // Prevent another retry.
        LoanExternalCheckQueueable.disableRetryForTest = true;

        Test.startTest();

        System.enqueueJob(
            new LoanExternalCheckQueueable(
                loan.Id,
                2
            )
        );

        Test.stopTest();

        LoanExternalCheckQueueable.disableRetryForTest = false;


        // -----------------------------------------------
        // Verify final status
        // -----------------------------------------------

        Loan_Enquiry__c updatedLoan = [
            SELECT External_Check_Status__c
            FROM Loan_Enquiry__c
            WHERE Id = :loan.Id
        ];

        System.assertEquals(
            'Failed',
            updatedLoan.External_Check_Status__c
        );


        // -----------------------------------------------
        // Verify audit log
        // -----------------------------------------------

        List<Loan_External_Check_Log__c> logs = [
            SELECT
                Status__c,
                Attempt_Number__c,
                Error_Message__c
            FROM Loan_External_Check_Log__c
            WHERE Loan_Enquiry__c = :loan.Id
        ];

        System.assertEquals(
            1,
            logs.size()
        );

        System.assertEquals(
            'Failed',
            logs[0].Status__c
        );

        System.assertEquals(
            2,
            logs[0].Attempt_Number__c
        );
    }


    // =====================================================
    // EXCEPTION / TIMEOUT
    // =====================================================

    @IsTest
    static void testCalloutException() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Test.setMock(
            HttpCalloutMock.class,
            new ExceptionMock()
        );

        // Prevent retry loop.
        LoanExternalCheckQueueable.disableRetryForTest = true;

        Test.startTest();

        System.enqueueJob(
            new LoanExternalCheckQueueable(
                loan.Id,
                1
            )
        );

        Test.stopTest();

        LoanExternalCheckQueueable.disableRetryForTest = false;


        // -----------------------------------------------
        // Verify status
        // -----------------------------------------------

        Loan_Enquiry__c updatedLoan = [
            SELECT External_Check_Status__c
            FROM Loan_Enquiry__c
            WHERE Id = :loan.Id
        ];

        System.assertEquals(
            'Pending',
            updatedLoan.External_Check_Status__c
        );


        // -----------------------------------------------
        // Verify audit log
        // -----------------------------------------------

        List<Loan_External_Check_Log__c> logs = [
            SELECT
                Status__c,
                Attempt_Number__c,
                Error_Message__c
            FROM Loan_External_Check_Log__c
            WHERE Loan_Enquiry__c = :loan.Id
        ];

        System.assertEquals(
            1,
            logs.size()
        );

        System.assertEquals(
            'Failed',
            logs[0].Status__c
        );

        System.assert(
            logs[0].Error_Message__c.contains(
                'Simulated timeout'
            )
        );
    }


    

 
}