import { LightningElement } from 'lwc';
import getLoanStatus from '@salesforce/apex/LoanEnquiryController.getLoanStatus';

export default class LoanStatus extends LightningElement {

    loanEnquiryId;
    loanEnquiry;
    errorMessage;
    isLoading = false;

    handleIdChange(event) {
        this.loanEnquiryId = event.target.value;
        this.errorMessage = undefined;
        this.loanEnquiry = undefined;
    }

    async handleSearch() {

        this.errorMessage = undefined;
        this.loanEnquiry = undefined;

        if (!this.loanEnquiryId) {
            this.errorMessage = 'Please enter a Loan Enquiry ID.';
            return;
        }

        this.isLoading = true;

        try {

            this.loanEnquiry = await getLoanStatus({
                loanEnquiryId: this.loanEnquiryId.trim()
            });

        } catch (error) {

            this.errorMessage =
                error?.body?.message ||
                'Unable to retrieve the Loan Enquiry.';

        } finally {

            this.isLoading = false;
        }
    }
}