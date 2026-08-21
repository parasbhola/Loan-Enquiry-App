public with sharing class GetExternalCheckAction {

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
        public String externalCheckStatus;

        @InvocableVariable
        public String externalCheckResult;

        @InvocableVariable
        public String message;
    }


    @InvocableMethod(
        label='Get External Check'
        description='Retrieves the external verification status and result for a loan enquiry.'
    )
    public static List<Response> getExternalCheck(
        List<Request> requests
    ) {

        List<Response> responses =
            new List<Response>();

        Set<Id> loanIds =
            new Set<Id>();


        // Collect Loan Enquiry IDs
        for (Request request : requests) {

            if (request.loanEnquiryId != null) {

                loanIds.add(
                    request.loanEnquiryId
                );
            }
        }


        Map<Id, Loan_Enquiry__c> enquiriesById =
            new Map<Id, Loan_Enquiry__c>();


        // Query Loan Enquiries
        if (!loanIds.isEmpty()) {

            List<Loan_Enquiry__c> enquiries = [
                SELECT Id,
                       External_Check_Status__c,
                       External_Check_Result__c
                FROM Loan_Enquiry__c
                WHERE Id IN :loanIds
            ];


            // Enforce Field Level Security
            SObjectAccessDecision decision =
                Security.stripInaccessible(
                    AccessType.READABLE,
                    enquiries
                );


            List<Loan_Enquiry__c> accessibleEnquiries =
                (List<Loan_Enquiry__c>)
                decision.getRecords();


            for (
                Loan_Enquiry__c enquiry :
                accessibleEnquiries
            ) {

                enquiriesById.put(
                    enquiry.Id,
                    enquiry
                );
            }
        }


        // Build responses
        for (Request request : requests) {

            Response response =
                new Response();

            response.loanEnquiryId =
                request.loanEnquiryId;


            if (request.loanEnquiryId == null) {

                response.message =
                    'Loan Enquiry Id is required.';

            }
            else if (
                !enquiriesById.containsKey(
                    request.loanEnquiryId
                )
            ) {

                response.message =
                    'Loan Enquiry was not found or is not accessible.';

            }
            else {

                Loan_Enquiry__c enquiry =
                    enquiriesById.get(
                        request.loanEnquiryId
                    );


                response.externalCheckStatus =
                    enquiry.External_Check_Status__c;

                response.externalCheckResult =
                    enquiry.External_Check_Result__c;

                response.message =
                    'External check information retrieved successfully.';
            }


            responses.add(response);
        }


        return responses;
    }
}