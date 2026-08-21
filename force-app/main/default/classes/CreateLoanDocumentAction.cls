public with sharing class CreateLoanDocumentAction {

    public class Request {

        @InvocableVariable(
            required=true
            description='Loan Enquiry record Id'
        )
        public Id loanEnquiryId;

        @InvocableVariable(
            required=true
            description='Name of the loan document'
        )
        public String documentName;

        @InvocableVariable(
            description='Type of the document'
        )
        public String documentType;

        @InvocableVariable(
            description='Date the document was uploaded'
        )
        public Date uploadedDate;
    }


    public class Response {

        @InvocableVariable
        public Id documentId;

        @InvocableVariable
        public String message;
    }


    @InvocableMethod(
        label='Create Loan Document'
        description='Creates a document record and associates it with a loan enquiry.'
    )
    public static List<Response> createLoanDocument(
        List<Request> requests
    ) {

        List<Response> responses =
            new List<Response>();

        for (Request request : requests) {

            Response response =
                new Response();

            try {

                Id documentId =
                    LoanEnquiryController.createLoanDocument(
                        request.loanEnquiryId,
                        request.documentName,
                        request.documentType,
                        request.uploadedDate
                    );

                response.documentId =
                    documentId;

                response.message =
                    'Loan document created successfully.';

            }
            catch (Exception e) {

                response.message =
                    e.getMessage();
            }

            responses.add(response);
        }

        return responses;
    }
}