import { LightningElement, wire } from 'lwc';
import {
    subscribe,
    unsubscribe,
    MessageContext
} from 'lightning/messageService';

import LOAN_ENQUIRY_SELECTED
    from '@salesforce/messageChannel/Loan_Enquiry_Selected__c';

import getLoanDocuments
    from '@salesforce/apex/LoanEnquiryController.getLoanDocuments';

import createLoanDocument
    from '@salesforce/apex/LoanEnquiryController.createLoanDocument';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

export default class LoanDocumentPanel extends LightningElement {

    loanEnquiryId;

    documents = [];

    subscription;

    documentName = '';
    documentType = '';
    uploadedDate;

    @wire(MessageContext)
    messageContext;

    documentTypeOptions = [
        { label: 'ID', value: 'ID' },
        { label: 'Payslip', value: 'Payslip' },
        { label: 'Bank Statement', value: 'Bank Statement' },
        { label: 'Other', value: 'Other' }
    ];

    columns = [
        {
            label: 'Document Name',
            fieldName: 'Document_Name__c'
        },
        {
            label: 'Document Type',
            fieldName: 'Document_Type__c'
        },
        {
            label: 'Uploaded Date',
            fieldName: 'Uploaded_Date__c'
        }
    ];

    connectedCallback() {

        this.subscription = subscribe(
            this.messageContext,
            LOAN_ENQUIRY_SELECTED,
            (message) => this.handleMessage(message)
        );
    }

    disconnectedCallback() {

        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    async handleMessage(message) {

        this.loanEnquiryId =
            message.Loan_Enquiry_Id__c;

        await this.loadDocuments();
    }

    async loadDocuments() {

        try {

            this.documents =
                await getLoanDocuments({
                    loanEnquiryId: this.loanEnquiryId
                });

        } catch (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }

    handleChange(event) {

        const fieldName = event.target.name;

        this[fieldName] = event.target.value;
    }

    async handleAddDocument() {

        if (!this.documentName ||
            !this.documentType ||
            !this.uploadedDate) {

            this.showToast(
                'Validation Error',
                'Please complete all document fields.',
                'error'
            );

            return;
        }

        try {

            await createLoanDocument({
                loanEnquiryId: this.loanEnquiryId,
                documentName: this.documentName,
                documentType: this.documentType,
                uploadedDate: this.uploadedDate
            });

            this.showToast(
                'Success',
                'Document added successfully.',
                'success'
            );

            // Clear form
            this.documentName = '';
            this.documentType = '';
            this.uploadedDate = null;

            // Refresh list without page reload
            await this.loadDocuments();

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