public with sharing class GetLoanDocumentsAction {

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
        public String documents;

        @InvocableVariable
        public String message;
    }


    @InvocableMethod(
        label='Get Loan Documents'
        description='Retrieves documents associated with a loan enquiry.'
    )
    public static List<Response> getLoanDocuments(
        List<Request> requests
    ) {

        List<Response> responses =
            new List<Response>();

        Set<Id> loanIds =
            new Set<Id>();

        for (Request request : requests) {

            if (request.loanEnquiryId != null) {

                loanIds.add(
                    request.loanEnquiryId
                );
            }
        }


        Map<Id, List<Loan_Document__c>> documentsByLoan =
            new Map<Id, List<Loan_Document__c>>();

        if (!loanIds.isEmpty()) {

            List<Loan_Document__c> documents = [
                SELECT Id,
                       Name,
                       Document_Name__c,
                       Document_Type__c,
                       Uploaded_Date__c,
                       Loan_Enquiry__c
                FROM Loan_Document__c
                WHERE Loan_Enquiry__c IN :loanIds
                ORDER BY Uploaded_Date__c DESC
            ];


            SObjectAccessDecision decision =
                Security.stripInaccessible(
                    AccessType.READABLE,
                    documents
                );


            List<Loan_Document__c> accessibleDocuments =
                (List<Loan_Document__c>)
                decision.getRecords();


            for (Loan_Document__c documentRecord :
                 accessibleDocuments) {

                if (!documentsByLoan.containsKey(
                    documentRecord.Loan_Enquiry__c
                )) {

                    documentsByLoan.put(
                        documentRecord.Loan_Enquiry__c,
                        new List<Loan_Document__c>()
                    );
                }

                documentsByLoan.get(
                    documentRecord.Loan_Enquiry__c
                ).add(documentRecord);
            }
        }


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
                !documentsByLoan.containsKey(
                    request.loanEnquiryId
                )
            ) {

                response.documents =
                    'No documents found.';

                response.message =
                    'No loan documents were found for this enquiry.';

            }
            else {

                List<String> documentDetails =
                    new List<String>();

                for (
                    Loan_Document__c documentRecord :
                    documentsByLoan.get(
                        request.loanEnquiryId
                    )
                ) {

                    String detail =
                        'Document: ' +
                        documentRecord.Document_Name__c;

                    if (
                        documentRecord.Document_Type__c != null
                    ) {

                        detail +=
                            ' | Type: ' +
                            documentRecord.Document_Type__c;
                    }

                    if (
                        documentRecord.Uploaded_Date__c != null
                    ) {

                        detail +=
                            ' | Uploaded: ' +
                            String.valueOf(
                                documentRecord.Uploaded_Date__c
                            );
                    }

                    documentDetails.add(detail);
                }


                response.documents =
                    String.join(
                        documentDetails,
                        '\n'
                    );

                response.message =
                    'Loan documents retrieved successfully.';
            }


            responses.add(response);
        }


        return responses;
    }
}