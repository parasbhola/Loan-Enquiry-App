@isTest
public class TestDataFactory {

    public static List<Loan_Enquiry__c> createLoanEnquiries(Integer count, Boolean doInsert) {
        List<Loan_Enquiry__c> enquiries = new List<Loan_Enquiry__c>();
        for (Integer i = 0; i < count; i++) {
            enquiries.add(new Loan_Enquiry__c(
                Applicant_Name__c = 'Test Applicant ' + i,
                Loan_Amount__c    = 10000 + (i * 1000),
                Loan_Purpose__c   = 'Home Improvement',
                Status__c         = 'New',
                External_Check_Status__c = 'Pending'
            ));
        }
        if (doInsert) insert enquiries;
        return enquiries;
    }

    public static Loan_Enquiry__c createLoanEnquiry(Boolean doInsert) {
        return createLoanEnquiries(1, doInsert)[0];
    }

    public static List<Loan_Document__c> createLoanDocuments(
        Id loanEnquiryId,
        Integer count,
        Boolean doInsert
    ) {
        List<Loan_Document__c> docs = new List<Loan_Document__c>();
        for (Integer i = 0; i < count; i++) {
            docs.add(new Loan_Document__c(
                Loan_Enquiry__c  = loanEnquiryId,
                Document_Name__c = 'Test Document ' + i,
                Document_Type__c = 'Identity Proof',
                Uploaded_Date__c = Date.today().addDays(-i)
            ));
        }
        if (doInsert) insert docs;
        return docs;
    }
}
