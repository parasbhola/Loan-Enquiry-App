import { LightningElement, wire } from 'lwc';
import createLoanEnquiry from '@salesforce/apex/LoanEnquiryController.createLoanEnquiry';

import {
    publish,
    MessageContext
} from 'lightning/messageService';

import LOAN_ENQUIRY_SELECTED from '@salesforce/messageChannel/Loan_Enquiry_Selected__c';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LoanEnquiryForm extends LightningElement {

    applicantName = '';
    loanAmount;
    loanPurpose = '';

    @wire(MessageContext)
    messageContext;

    loanPurposeOptions = [
        { label: 'Home Purchase', value: 'Home Purchase' },
        { label: 'Refinance', value: 'Refinance' },
        { label: 'Vehicle', value: 'Vehicle' },
        { label: 'Equipment', value: 'Equipment' },
        { label: 'Other', value: 'Other' }
    ];

    handleChange(event) {
        const fieldName = event.target.name;
        this[fieldName] = event.target.value;
    }

    async handleSave() {

        // Client-side validation
        if (!this.loanAmount || Number(this.loanAmount) <= 0) {

            this.showToast(
                'Validation Error',
                'Loan Amount must be greater than zero.',
                'error'
            );

            return;
        }

        try {

            const loanEnquiryId = await createLoanEnquiry({
                applicantName: this.applicantName,
                loanAmount: Number(this.loanAmount),
                loanPurpose: this.loanPurpose
            });

            // Publish Loan Enquiry Id through LMS
            publish(
                this.messageContext,
                LOAN_ENQUIRY_SELECTED,
                {
                    Loan_Enquiry_Id__c: loanEnquiryId
                }
            );

            this.showToast(
                'Success',
                'Loan Enquiry created successfully.',
                'success'
            );

            // Reset form
            this.applicantName = '';
            this.loanAmount = null;
            this.loanPurpose = '';

        } catch (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    getErrorMessage(error) {

        return error?.body?.message ||
            error?.message ||
            'Something went wrong.';
    }
}