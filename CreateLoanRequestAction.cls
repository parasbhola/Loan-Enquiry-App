public with sharing class CreateLoanRequestAction {

    public class Request {

        @InvocableVariable(
            required=true
            description='Applicant name for the loan enquiry'
        )
        public String applicantName;

        @InvocableVariable(
            required=true
            description='Loan amount requested by the applicant'
        )
        public Decimal loanAmount;

        @InvocableVariable(
            description='Purpose of the loan'
        )
        public String loanPurpose;
    }

    public class Response {

        @InvocableVariable(
            description='ID of the newly created loan enquiry'
        )
        public String loanEnquiryId;

        @InvocableVariable(
            description='Result message for the loan enquiry creation'
        )
        public String message;
    }

    @InvocableMethod(
        label='Create Loan Request'
        description='Creates a new loan enquiry and starts the external verification process.'
    )
    public static List<Response> createLoanRequest(
        List<Request> requests
    ) {

        List<Response> responses = new List<Response>();

        for (Request request : requests) {

            Response response = new Response();

            try {

                Id enquiryId =
                    LoanEnquiryController.createLoanEnquiry(
                        request.applicantName,
                        request.loanAmount,
                        request.loanPurpose
                    );

                // Convert Salesforce Id to String for Agentforce output
                response.loanEnquiryId = String.valueOf(enquiryId);

                response.message =
                    'Loan enquiry created successfully.';

            } catch (Exception e) {

                response.message =
                    'Failed to create loan enquiry: ' + e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }
}