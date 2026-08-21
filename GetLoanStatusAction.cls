public with sharing class GetLoanStatusAction {

    public class Request {
        @InvocableVariable(
            required=true
            description='Loan Enquiry record Id'
        )
        public Id loanEnquiryId;
    }

    public class Response {
        @InvocableVariable
        public Id loanEnquiryId;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String externalCheckStatus;

        @InvocableVariable
        public String externalCheckResult;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Get Loan Status'
        description='Retrieves the current status and external check status of a loan enquiry.'
    )
    public static List<Response> getLoanStatus(
        List<Request> requests
    ) {

        List<Response> responses = new List<Response>();

        Set<Id> loanIds = new Set<Id>();

        for (Request request : requests) {
            if (request.loanEnquiryId != null) {
                loanIds.add(request.loanEnquiryId);
            }
        }

        Map<Id, Loan_Enquiry__c> enquiriesById =
            new Map<Id, Loan_Enquiry__c>();

        if (!loanIds.isEmpty()) {

            List<Loan_Enquiry__c> enquiries = [
                SELECT Id,
                       Status__c,
                       External_Check_Status__c,
                       External_Check_Result__c
                FROM Loan_Enquiry__c
                WHERE Id IN :loanIds
            ];

            SObjectAccessDecision decision =
                Security.stripInaccessible(
                    AccessType.READABLE,
                    enquiries
                );

            List<Loan_Enquiry__c> accessibleEnquiries =
                (List<Loan_Enquiry__c>) decision.getRecords();

            for (Loan_Enquiry__c enquiry : accessibleEnquiries) {
                enquiriesById.put(enquiry.Id, enquiry);
            }
        }

        for (Request request : requests) {

            Response response = new Response();

            response.loanEnquiryId = request.loanEnquiryId;

            if (request.loanEnquiryId == null) {

                response.message =
                    'Loan Enquiry Id is required.';

            } else if (
                !enquiriesById.containsKey(request.loanEnquiryId)
            ) {

                response.message =
                    'Loan Enquiry was not found or is not accessible.';

            } else {

                Loan_Enquiry__c enquiry =
                    enquiriesById.get(request.loanEnquiryId);

                response.status =
                    enquiry.Status__c;

                response.externalCheckStatus =
                    enquiry.External_Check_Status__c;

                response.externalCheckResult =
                    enquiry.External_Check_Result__c;

                response.message =
                    'Loan status retrieved successfully.';
            }

            responses.add(response);
        }

        return responses;
    }
}