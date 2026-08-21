@IsTest
private class LoanEnquiryControllerTest {

    // --------------------------------------------------
    // TEST DATA
    // --------------------------------------------------

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
                '{"id":1,"name":"Controller Test User","username":"testuser"}'
            );

            return response;
        }
    }


    // --------------------------------------------------
    // CREATE LOAN ENQUIRY
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanEnquiry() {

        Test.setMock(
            HttpCalloutMock.class,
            new SuccessMock()
        );

        Test.startTest();

        Id loanId =
            LoanEnquiryController.createLoanEnquiry(
                'John Test',
                300000,
                'Home Purchase'
            );

        Test.stopTest();

        Loan_Enquiry__c loan = [
            SELECT Id,
                   Applicant_Name__c,
                   Loan_Amount__c,
                   Loan_Purpose__c,
                   Status__c,
                   External_Check_Status__c,
                   External_Check_Result__c
            FROM Loan_Enquiry__c
            WHERE Id = :loanId
        ];

        System.assertEquals(
            'John Test',
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

        System.assertEquals(
            'Success',
            loan.External_Check_Status__c
        );

        System.assert(
            loan.External_Check_Result__c.contains(
                'Controller Test User'
            )
        );
    }


    // --------------------------------------------------
    // INVALID APPLICANT NAME
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanEnquiryWithoutApplicantName() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            LoanEnquiryController.createLoanEnquiry(
                '',
                300000,
                'Home Purchase'
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for blank Applicant Name.'
        );
    }


    // --------------------------------------------------
    // INVALID LOAN AMOUNT
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanEnquiryWithInvalidAmount() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            LoanEnquiryController.createLoanEnquiry(
                'John Test',
                0,
                'Home Purchase'
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for invalid Loan Amount.'
        );
    }


    // --------------------------------------------------
    // GET DOCUMENTS
    // --------------------------------------------------

    @IsTest
    static void testGetLoanDocuments() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Loan_Document__c documentRecord =
            new Loan_Document__c(
                Loan_Enquiry__c = loan.Id,
                Document_Name__c = 'Test Payslip',
                Document_Type__c = 'Payslip',
                Uploaded_Date__c = Date.today()
            );

        insert documentRecord;

        Test.startTest();

        List<Loan_Document__c> documents =
            LoanEnquiryController.getLoanDocuments(
                loan.Id
            );

        Test.stopTest();

        System.assertEquals(
            1,
            documents.size()
        );

        System.assertEquals(
            'Test Payslip',
            documents[0].Document_Name__c
        );
    }


    // --------------------------------------------------
    // GET DOCUMENTS - NULL ID
    // --------------------------------------------------

    @IsTest
    static void testGetLoanDocumentsWithNullId() {

        Test.startTest();

        List<Loan_Document__c> documents =
            LoanEnquiryController.getLoanDocuments(null);

        Test.stopTest();

        System.assertEquals(
            0,
            documents.size()
        );
    }


    // --------------------------------------------------
    // CREATE DOCUMENT
    // --------------------------------------------------

    @IsTest
    static void testCreateLoanDocument() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Test.startTest();

        Id documentId =
            LoanEnquiryController.createLoanDocument(
                loan.Id,
                'Bank Statement',
                'Bank Statement',
                Date.today()
            );

        Test.stopTest();

        Loan_Document__c documentRecord = [
            SELECT Id,
                   Loan_Enquiry__c,
                   Document_Name__c,
                   Document_Type__c,
                   Uploaded_Date__c
            FROM Loan_Document__c
            WHERE Id = :documentId
        ];

        System.assertEquals(
            loan.Id,
            documentRecord.Loan_Enquiry__c
        );

        System.assertEquals(
            'Bank Statement',
            documentRecord.Document_Name__c
        );

        System.assertEquals(
            'Bank Statement',
            documentRecord.Document_Type__c
        );

        System.assertEquals(
            Date.today(),
            documentRecord.Uploaded_Date__c
        );
    }


    // --------------------------------------------------
    // CREATE DOCUMENT - NULL LOAN ENQUIRY
    // --------------------------------------------------

    @IsTest
    static void testCreateDocumentWithoutLoanEnquiry() {

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            LoanEnquiryController.createLoanDocument(
                null,
                'Test Document',
                'Other',
                Date.today()
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for missing Loan Enquiry.'
        );
    }


    // --------------------------------------------------
    // CREATE DOCUMENT - BLANK NAME
    // --------------------------------------------------

    @IsTest
    static void testCreateDocumentWithoutName() {

        Loan_Enquiry__c loan = [
            SELECT Id
            FROM Loan_Enquiry__c
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();

        try {

            LoanEnquiryController.createLoanDocument(
                loan.Id,
                '',
                'Other',
                Date.today()
            );

        } catch (AuraHandledException e) {

            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(
            true,
            exceptionThrown,
            'Expected exception for blank Document Name.'
        );
    }
    
    // --------------------------------------------------
// GET LOAN STATUS - SUCCESS
// --------------------------------------------------

@IsTest
static void testGetLoanStatus() {

    Loan_Enquiry__c loan = [
        SELECT Id,
               Applicant_Name__c,
               Loan_Amount__c,
               Loan_Purpose__c,
               Status__c,
               External_Check_Status__c,
               External_Check_Result__c
        FROM Loan_Enquiry__c
        LIMIT 1
    ];

    Test.startTest();

    Loan_Enquiry__c result =
        LoanEnquiryController.getLoanStatus(loan.Id);

    Test.stopTest();

    System.assertNotEquals(
        null,
        result,
        'Expected a Loan Enquiry record.'
    );

    System.assertEquals(
        loan.Id,
        result.Id
    );

    System.assertEquals(
        'Test Applicant',
        result.Applicant_Name__c
    );

    System.assertEquals(
        300000,
        result.Loan_Amount__c
    );

    System.assertEquals(
        'Home Purchase',
        result.Loan_Purpose__c
    );

    System.assertEquals(
        'New',
        result.Status__c
    );

    System.assertEquals(
        'Pending',
        result.External_Check_Status__c
    );
}


// --------------------------------------------------
// GET LOAN STATUS - NULL ID
// --------------------------------------------------

@IsTest
static void testGetLoanStatusWithNullId() {

    Boolean exceptionThrown = false;

    Test.startTest();

    try {

        LoanEnquiryController.getLoanStatus(null);

    } catch (AuraHandledException e) {

        exceptionThrown = true;
    }

    Test.stopTest();

    System.assertEquals(
        true,
        exceptionThrown,
        'Expected exception when Loan Enquiry ID is null.'
    );
}


// --------------------------------------------------
// GET LOAN STATUS - RECORD NOT FOUND
// --------------------------------------------------

@IsTest
static void testGetLoanStatusRecordNotFound() {

    Id fakeLoanId = 'a01000000000001AAA';

    Boolean exceptionThrown = false;

    Test.startTest();

    try {

        LoanEnquiryController.getLoanStatus(fakeLoanId);

    } catch (AuraHandledException e) {

        exceptionThrown = true;
    }

    Test.stopTest();

    System.assertEquals(
        true,
        exceptionThrown,
        'Expected exception when Loan Enquiry does not exist.'
    );
}
    
}