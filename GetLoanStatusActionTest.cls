@IsTest
private class GetLoanStatusActionTest {

    // --------------------------------------------------
    // TEST DATA
    // --------------------------------------------------

    @TestSetup
    static void setupData() {

        Loan_Enquiry__c loan = new Loan_Enquiry__c(
            Applicant_Name__c = 'Status Test Applicant',
            Loan_Amount__c = 300000,
            Loan_Purpose__c = 'Home Purchase',
            Status__c = 'Under Review',
            External_Check_Status__c = 'Success',
            External_Check_Result__c = 'Credit check completed successfully.'
        );

        insert loan;
    }


    // --------------------------------------------------
    // SUCCESSFUL STATUS LOOKUP
    // --------------------------------------------------

    @IsTest
    static void testGetLoanStatusSuccess() {

        Loan_Enquiry__c loan = [
            SELECT Id,
                   Status__c,
                   External_Check_Status__c,
                   External_Check_Result__c
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        GetLoanStatusAction.Request request =
            new GetLoanStatusAction.Request();

        request.loanEnquiryId = loan.Id;

        List<GetLoanStatusAction.Request> requests =
            new List<GetLoanStatusAction.Request>();

        requests.add(request);

        Test.startTest();

        List<GetLoanStatusAction.Response> responses =
            GetLoanStatusAction.getLoanStatus(requests);

        Test.stopTest();

        System.assertEquals(
            1,
            responses.size(),
            'Expected one response.'
        );

        GetLoanStatusAction.Response response =
            responses[0];

        System.assertEquals(
            loan.Id,
            response.loanEnquiryId
        );

        System.assertEquals(
            'Under Review',
            response.status
        );

        System.assertEquals(
            'Success',
            response.externalCheckStatus
        );

        System.assertEquals(
            'Credit check completed successfully.',
            response.externalCheckResult
        );

        System.assertEquals(
            'Loan status retrieved successfully.',
            response.message
        );
    }


    // --------------------------------------------------
    // NULL LOAN ENQUIRY ID
    // --------------------------------------------------

    @IsTest
    static void testGetLoanStatusWithNullId() {

        GetLoanStatusAction.Request request =
            new GetLoanStatusAction.Request();

        request.loanEnquiryId = null;

        List<GetLoanStatusAction.Request> requests =
            new List<GetLoanStatusAction.Request>();

        requests.add(request);

        Test.startTest();

        List<GetLoanStatusAction.Response> responses =
            GetLoanStatusAction.getLoanStatus(requests);

        Test.stopTest();

        System.assertEquals(
            1,
            responses.size()
        );

        GetLoanStatusAction.Response response =
            responses[0];

        System.assertEquals(
            null,
            response.loanEnquiryId
        );

        System.assertEquals(
            'Loan Enquiry Id is required.',
            response.message
        );

        System.assertEquals(
            null,
            response.status
        );

        System.assertEquals(
            null,
            response.externalCheckStatus
        );

        System.assertEquals(
            null,
            response.externalCheckResult
        );
    }


    // --------------------------------------------------
    // LOAN ENQUIRY NOT FOUND
    // --------------------------------------------------

    @IsTest
    static void testGetLoanStatusNotFound() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Id deletedLoanId = loan.Id;

        delete loan;

        GetLoanStatusAction.Request request =
            new GetLoanStatusAction.Request();

        request.loanEnquiryId = deletedLoanId;

        List<GetLoanStatusAction.Request> requests =
            new List<GetLoanStatusAction.Request>();

        requests.add(request);

        Test.startTest();

        List<GetLoanStatusAction.Response> responses =
            GetLoanStatusAction.getLoanStatus(requests);

        Test.stopTest();

        System.assertEquals(
            1,
            responses.size()
        );

        GetLoanStatusAction.Response response =
            responses[0];

        System.assertEquals(
            deletedLoanId,
            response.loanEnquiryId
        );

        System.assertEquals(
            'Loan Enquiry was not found or is not accessible.',
            response.message
        );

        System.assertEquals(
            null,
            response.status
        );
    }


    // --------------------------------------------------
    // MULTIPLE REQUESTS
    // --------------------------------------------------

    @IsTest
    static void testGetLoanStatusMultipleRequests() {

        Loan_Enquiry__c loan1 = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Loan_Enquiry__c loan2 = new Loan_Enquiry__c(
            Applicant_Name__c = 'Second Status Applicant',
            Loan_Amount__c = 250000,
            Loan_Purpose__c = 'Vehicle',
            Status__c = 'New',
            External_Check_Status__c = 'Pending',
            External_Check_Result__c = 'Waiting for verification.'
        );

        insert loan2;

        GetLoanStatusAction.Request request1 =
            new GetLoanStatusAction.Request();

        request1.loanEnquiryId = loan1.Id;

        GetLoanStatusAction.Request request2 =
            new GetLoanStatusAction.Request();

        request2.loanEnquiryId = loan2.Id;

        List<GetLoanStatusAction.Request> requests =
            new List<GetLoanStatusAction.Request>();

        requests.add(request1);
        requests.add(request2);

        Test.startTest();

        List<GetLoanStatusAction.Response> responses =
            GetLoanStatusAction.getLoanStatus(requests);

        Test.stopTest();

        System.assertEquals(
            2,
            responses.size(),
            'Expected two responses.'
        );

        System.assertEquals(
            loan1.Id,
            responses[0].loanEnquiryId
        );

        System.assertEquals(
            'Under Review',
            responses[0].status
        );

        System.assertEquals(
            loan2.Id,
            responses[1].loanEnquiryId
        );

        System.assertEquals(
            'New',
            responses[1].status
        );

        System.assertEquals(
            'Pending',
            responses[1].externalCheckStatus
        );
    }
}