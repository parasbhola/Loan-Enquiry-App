@IsTest
private class LoanEnquiryTriggerHandlerTest {

    // --------------------------------------------------
    // HIGH VALUE LOAN
    // --------------------------------------------------

    @IsTest
    static void testHighValueLoan() {

        Loan_Enquiry__c loan = new Loan_Enquiry__c(
            Applicant_Name__c = 'High Value Applicant',
            Loan_Amount__c = 600000,
            Loan_Purpose__c = 'Home Purchase',
            Status__c = 'New',
            External_Check_Status__c = 'Pending'
        );

        Test.startTest();

        insert loan;

        Test.stopTest();

        // Verify Status was changed by before-insert handler
        Loan_Enquiry__c result = [
            SELECT Id,
                   Status__c,
                   OwnerId
            FROM Loan_Enquiry__c
            WHERE Id = :loan.Id
        ];

        System.assertEquals(
            'Under Review',
            result.Status__c,
            'High-value loan should be moved to Under Review.'
        );

        // Verify Task was created by after-insert handler
        List<Task> tasks = [
            SELECT Id,
                   Subject,
                   OwnerId,
                   WhatId
            FROM Task
            WHERE WhatId = :loan.Id
        ];

        System.assertEquals(
            1,
            tasks.size(),
            'One manual review Task should be created.'
        );

        System.assertEquals(
            'Manual review required — high value loan.',
            tasks[0].Subject
        );

        System.assertEquals(
            loan.Id,
            tasks[0].WhatId
        );

        // Salesforce assigns the current user as OwnerId
        System.assertEquals(
            UserInfo.getUserId(),
            tasks[0].OwnerId,
            'Task should be owned by the current user.'
        );
    }


    // --------------------------------------------------
    // NORMAL VALUE LOAN
    // --------------------------------------------------

    @IsTest
    static void testNormalValueLoan() {

        Loan_Enquiry__c loan = new Loan_Enquiry__c(
            Applicant_Name__c = 'Normal Applicant',
            Loan_Amount__c = 300000,
            Loan_Purpose__c = 'Home Purchase',
            Status__c = 'New',
            External_Check_Status__c = 'Pending'
        );

        Test.startTest();

        insert loan;

        Test.stopTest();

        // Verify Status was NOT changed
        Loan_Enquiry__c result = [
            SELECT Id,
                   Status__c
            FROM Loan_Enquiry__c
            WHERE Id = :loan.Id
        ];

        System.assertEquals(
            'New',
            result.Status__c,
            'Loan below or equal to 500,000 should remain New.'
        );

        // Verify no review Task was created
        List<Task> tasks = [
            SELECT Id
            FROM Task
            WHERE WhatId = :loan.Id
        ];

        System.assertEquals(
            0,
            tasks.size(),
            'No review Task should be created for a normal loan.'
        );
    }


    // --------------------------------------------------
    // BULK TEST - 200 RECORDS
    // --------------------------------------------------

    @IsTest
    static void testBulkLoanEnquiries() {

        List<Loan_Enquiry__c> loans =
            new List<Loan_Enquiry__c>();

        // ----------------------------------------------
        // 100 NORMAL LOANS
        // ----------------------------------------------

        for (Integer i = 0; i < 100; i++) {

            loans.add(
                new Loan_Enquiry__c(
                    Applicant_Name__c =
                        'Normal Bulk Applicant ' + i,

                    Loan_Amount__c = 300000,

                    Loan_Purpose__c =
                        'Home Purchase',

                    Status__c = 'New',

                    External_Check_Status__c =
                        'Pending'
                )
            );
        }

        // ----------------------------------------------
        // 100 HIGH VALUE LOANS
        // ----------------------------------------------

        for (Integer i = 0; i < 100; i++) {

            loans.add(
                new Loan_Enquiry__c(
                    Applicant_Name__c =
                        'High Value Bulk Applicant ' + i,

                    Loan_Amount__c = 600000,

                    Loan_Purpose__c =
                        'Home Purchase',

                    Status__c = 'New',

                    External_Check_Status__c =
                        'Pending'
                )
            );
        }

        Test.startTest();

        insert loans;

        Test.stopTest();


        // ----------------------------------------------
        // VERIFY 200 RECORDS
        // ----------------------------------------------

        System.assertEquals(
            200,
            loans.size(),
            '200 Loan Enquiries should have been created.'
        );


        // ----------------------------------------------
        // VERIFY HIGH VALUE STATUS
        // ----------------------------------------------

        Integer underReviewCount = [
            SELECT COUNT()
            FROM Loan_Enquiry__c
            WHERE Loan_Amount__c > 500000
            AND Status__c = 'Under Review'
        ];

        System.assertEquals(
            100,
            underReviewCount,
            'All 100 high-value loans should be Under Review.'
        );


        // ----------------------------------------------
        // VERIFY NORMAL STATUS
        // ----------------------------------------------

        Integer newCount = [
            SELECT COUNT()
            FROM Loan_Enquiry__c
            WHERE Loan_Amount__c <= 500000
            AND Status__c = 'New'
        ];

        System.assertEquals(
            100,
            newCount,
            'All 100 normal loans should remain New.'
        );


        // ----------------------------------------------
        // COLLECT HIGH VALUE LOAN IDS
        // ----------------------------------------------

        Set<Id> highValueLoanIds =
            new Set<Id>();

        for (Loan_Enquiry__c loan : loans) {

            if (loan.Loan_Amount__c > 500000) {
                highValueLoanIds.add(loan.Id);
            }
        }

        System.assertEquals(
            100,
            highValueLoanIds.size(),
            'There should be 100 high-value loan records.'
        );


        // ----------------------------------------------
        // VERIFY 100 REVIEW TASKS
        // ----------------------------------------------

        List<Task> reviewTasks = [
            SELECT Id,
                   Subject,
                   OwnerId,
                   WhatId
            FROM Task
            WHERE WhatId IN :highValueLoanIds
            AND Subject =
                'Manual review required — high value loan.'
        ];

        System.assertEquals(
            100,
            reviewTasks.size(),
            '100 review Tasks should be created.'
        );


        // ----------------------------------------------
        // VERIFY TASK OWNERS
        // ----------------------------------------------

        for (Task task : reviewTasks) {

            System.assertEquals(
                UserInfo.getUserId(),
                task.OwnerId,
                'Each review Task should be owned by the current user.'
            );

            System.assert(
                highValueLoanIds.contains(task.WhatId),
                'Task must belong to a high-value Loan Enquiry.'
            );
        }
    }
}