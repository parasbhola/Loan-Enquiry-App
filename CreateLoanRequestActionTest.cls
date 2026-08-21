@IsTest
private class CreateLoanRequestActionTest {

    // --------------------------------------------------
    // CALLOUT MOCK
    // --------------------------------------------------

    private class SuccessMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest request) {

            HttpResponse response = new HttpResponse();

            response.setStatusCode(200);
            response.setHeader(
                'Content-Type',
                'application/json'
            );

            response.setBody(
                '{"id":1,"name":"Agent Test User","username":"agenttest"}'
            );

            return response;
        }
    }


    // --------------------------------------------------
    // SUCCESSFUL AGENT ACTION
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanRequestSuccess() {

        CreateLoanRequestAction.Request request =
            new CreateLoanRequestAction.Request();

        request.applicantName = 'Agent Test Applicant';
        request.loanAmount = 300000;
        request.loanPurpose = 'Home Purchase';

        List<CreateLoanRequestAction.Request> requests =
            new List<CreateLoanRequestAction.Request>();

        requests.add(request);

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        List<CreateLoanRequestAction.Response> responses =
            CreateLoanRequestAction.createLoanRequest(
                requests
            );

        Test.stopTest();

        // Verify response
        System.assertEquals(
            1,
            responses.size(),
            'Expected one response.'
        );

        System.assertNotEquals(
            null,
            responses[0].loanEnquiryId,
            'Loan Enquiry ID should be returned.'
        );

        System.assertEquals(
            'Loan enquiry created successfully.',
            responses[0].message
        );

        // Verify ID is a valid Salesforce record
        Id enquiryId =
            Id.valueOf(responses[0].loanEnquiryId);

        Loan_Enquiry__c loan = [
            SELECT Id,
                   Applicant_Name__c,
                   Loan_Amount__c,
                   Loan_Purpose__c,
                   Status__c,
                   External_Check_Status__c
            FROM Loan_Enquiry__c
            WHERE Id = :enquiryId
        ];

        System.assertEquals(
            'Agent Test Applicant',
            loan.Applicant_Name__c
        );

        System.assertEquals(
            300000,
            loan.Loan_Amount__c
        );

        System.assertEquals(
            'Home Purchase',
            loan.Loan_Purpose__c
        );

        System.assertEquals(
            'New',
            loan.Status__c
        );
    }


    // --------------------------------------------------
    // INVALID REQUEST - BLANK APPLICANT NAME
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanRequestFailure() {

        CreateLoanRequestAction.Request request =
            new CreateLoanRequestAction.Request();

        request.applicantName = '';
        request.loanAmount = 300000;
        request.loanPurpose = 'Home Purchase';

        List<CreateLoanRequestAction.Request> requests =
            new List<CreateLoanRequestAction.Request>();

        requests.add(request);

        Test.startTest();

        List<CreateLoanRequestAction.Response> responses =
            CreateLoanRequestAction.createLoanRequest(
                requests
            );

        Test.stopTest();

        System.assertEquals(
            1,
            responses.size()
        );

        System.assertEquals(
            null,
            responses[0].loanEnquiryId,
            'No Loan Enquiry ID should be returned when creation fails.'
        );

        System.assert(
            responses[0].message.startsWith(
                'Failed to create loan enquiry:'
            ),
            'Expected failure message.'
        );
    }


    // --------------------------------------------------
    // MULTIPLE REQUESTS
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanRequestMultipleRequests() {

        List<CreateLoanRequestAction.Request> requests =
            new List<CreateLoanRequestAction.Request>();

        CreateLoanRequestAction.Request request1 =
            new CreateLoanRequestAction.Request();

        request1.applicantName = 'Agent Applicant One';
        request1.loanAmount = 200000;
        request1.loanPurpose = 'Vehicle';

        CreateLoanRequestAction.Request request2 =
            new CreateLoanRequestAction.Request();

        request2.applicantName = 'Agent Applicant Two';
        request2.loanAmount = 400000;
        request2.loanPurpose = 'Equipment';

        requests.add(request1);
        requests.add(request2);

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        List<CreateLoanRequestAction.Response> responses =
            CreateLoanRequestAction.createLoanRequest(
                requests
            );

        Test.stopTest();

        System.assertEquals(
            2,
            responses.size(),
            'Expected two responses.'
        );

        System.assertNotEquals(
            null,
            responses[0].loanEnquiryId
        );

        System.assertNotEquals(
            null,
            responses[1].loanEnquiryId
        );

        System.assertEquals(
            'Loan enquiry created successfully.',
            responses[0].message
        );

        System.assertEquals(
            'Loan enquiry created successfully.',
            responses[1].message
        );
    }
}