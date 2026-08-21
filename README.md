# Loan Enquiry & Underwriting Mini-App

A Salesforce mini-application demonstrating a loan enquiry and underwriting workflow using Apex, LWC, Lightning Message Service, Queueable Apex, Experience Cloud, Agentforce, security enforcement, automation, and Apex testing.

---

## 1. Overview

This project implements a Salesforce-based Loan Enquiry & Underwriting Mini-App using synthetic/sample data.

The solution demonstrates:

- Salesforce custom objects and relationships
- Lightning Web Components
- Lightning Message Service (LMS)
- Apex controllers and Invocable Actions
- Named Credential-based external callout
- Queueable Apex with failure handling and retry
- External callout audit logging
- Bulk-safe automation
- CRUD/FLS enforcement
- Agentforce
- Experience Cloud
- Apex unit testing

---

# 2. Data Model

The solution uses three custom objects.

### Loan_Enquiry__c

Stores the main loan enquiry information.

Key fields:

- Applicant Name
- Loan Amount
- Loan Purpose
- Status
- External Check Result
- External Check Status

### Loan_Document__c

Stores documents associated with a Loan Enquiry.

Key fields:

- Loan Enquiry
- Document Name
- Document Type
- Uploaded Date

`Loan_Document__c` is related to `Loan_Enquiry__c` so that multiple documents can be associated with a single loan enquiry.

### Loan_External_Check_Log__c

Stores an audit trail for every external verification attempt.

Key fields include:

- Loan Enquiry
- Attempt Number
- Attempt Date
- Status
- Error Message
- Response

Both successful and failed external check attempts are logged.

---

# 3. Lightning Web Components

## loanEnquiryForm

The component allows the user to:

- Enter Applicant Name
- Enter Loan Amount
- Select Loan Purpose
- Create a Loan Enquiry

Client-side validation ensures that the Loan Amount is greater than zero.

After successfully creating the Loan Enquiry, the component publishes the newly created record Id through Lightning Message Service.

## loanDocumentPanel

The component subscribes to the Lightning Message Service channel.

After receiving the Loan Enquiry Id, it:

- Retrieves related Loan Documents
- Displays existing documents
- Allows the user to create new Loan Documents
- Updates the UI without a page reload

The two LWCs communicate using LMS rather than parent-child `@api` communication.

---

# 4. Apex Architecture

The main Apex classes are:

| Class | Purpose |
|---|---|
| `LoanEnquiryController` | Creates Loan Enquiries, retrieves Loan Documents, creates Loan Documents and retrieves Loan status |
| `CreateLoanRequestAction` | Invocable action for creating a Loan Enquiry |
| `GetLoanStatusAction` | Invocable action for retrieving Loan status |
| `LoanExternalCheckQueueable` | Performs external verification and handles retry |
| `LoanEnquiryTriggerHandler` | Handles high-value loan automation |
| `GetExternalCheckAction` | Retrieves external check information |
| `CreateLoanDocumentAction` | Creates Loan Document records |
| `GetLoanDocumentsAction` | Retrieves Loan Document records |

---

# 5. External Check Integration

After a Loan Enquiry is created, an asynchronous Queueable Apex job performs the external verification.

The integration uses a Salesforce Named Credential:

`callout:JSONPlaceholder/users/1`

The endpoint is not hardcoded as a full URL inside Apex.

### Successful Callout

When the external API returns a successful response:

1. The response is parsed.
2. `External_Check_Result__c` is populated.
3. `External_Check_Status__c` is set to `Success`.
4. A successful attempt is recorded in `Loan_External_Check_Log__c`.

### Failed Callout

When the API returns an HTTP error or an exception occurs:

1. The failure is caught.
2. The Loan Enquiry is marked as `Pending` on the first attempt.
3. The failure is recorded in `Loan_External_Check_Log__c`.
4. A Queueable retry is submitted.

If the second attempt fails:

1. The Loan Enquiry is marked as `Failed`.
2. The second failed attempt is logged.
3. No further retry is performed.

### Retry Design

The implementation performs one retry.

The retry logic is implemented through Queueable Apex. In a production implementation, this could be extended with configurable retry/backoff policies using scheduled processing or event-driven orchestration.

---

# 6. External Check Audit Logging

Every external verification attempt is stored in:

`Loan_External_Check_Log__c`

The log provides an auditable history independent of the current Loan Enquiry status.

For example:

| Attempt | Status | Result |
|---|---|---|
| 1 | Failed | External system unavailable |
| 2 | Success | External check completed |

This allows administrators or support teams to understand what happened during each external verification attempt.

---

# 7. Automation

An Apex Trigger Handler is used for high-value Loan Enquiries.

When:

`Loan Amount > 500,000`

the following automation occurs:

1. Status is changed to `Under Review`.
2. A Task is created for the Loan Enquiry owner.
3. Task subject:

`Manual review required — high value loan.`

### Why Apex Trigger?

Apex was selected because the requirement involves record-level processing and the implementation can be kept bulk-safe and reusable through a dedicated trigger handler.

The trigger handler does not perform SOQL or DML inside loops.

---

# 8. Bulk Safety

Bulk processing is explicitly tested.

The test class inserts:

`200 Loan_Enquiry__c`

records in a single DML operation.

The test verifies:

- All 200 records are created.
- High-value loans are changed to `Under Review`.
- Normal loans remain `New`.
- Review Tasks are created only for high-value loans.

The implementation avoids SOQL/DML operations inside loops.

---

# 9. Security

CRUD and Field-Level Security are enforced using Salesforce security mechanisms.

`Security.stripInaccessible()` is used for relevant read, create, and update operations.

This ensures that fields the current user does not have access to are not unintentionally exposed or modified.

For an Experience Cloud authenticated user, record-level access should additionally be enforced through Salesforce sharing.

The production design would use the authenticated user's Contact/Account relationship and appropriate sharing rules or Apex managed sharing so that a community user can only access Loan Enquiries they are authorized to view.

Client-side filtering is not considered a security mechanism.

---

# 10. Experience Cloud

A small LWR Experience Cloud site was created for authenticated users.

The user authenticates first and then accesses the Loan Enquiry functionality.

An authenticated user approach was selected instead of Guest access because Loan Enquiry information contains customer/application data and should not be publicly accessible.

The Experience Cloud user should be restricted through Salesforce object permissions and record-level sharing so that the user can only access authorized Loan Enquiry records.

---

# 11. Agentforce

A minimal Agentforce implementation was created.

### Topic

Loan Enquiry Status

### Action

Get Loan Status

The action retrieves:

- Loan Enquiry Status
- External Check Status
- External Check Result

The agent was tested through the Agentforce preview with sample loan enquiries.

The implementation was intentionally kept to one topic and one action as requested by the exercise.

---

# 12. Apex Testing

The test suite covers:

- Apex controllers
- Invocable Actions
- Queueable Apex
- Successful callout
- Failed callout
- Retry behaviour
- External Check audit logging
- Trigger automation
- 200-record bulk processing

`HttpCalloutMock` is used to simulate external API responses.

Both successful and failed callout scenarios are tested.

The tests do not use:

`@IsTest(SeeAllData=true)`

All required test data is created inside the test context.

The target is 85%+ Apex code coverage while also validating functional behaviour.

---

# 13. Slack Integration – Conceptual Design

If Slack notifications were required whenever a Loan Enquiry moves to `Under Review`, I would keep the Salesforce transaction independent of the external Slack request.

The status transition could publish a Platform Event or enqueue an asynchronous integration job.

A dedicated integration process could consume the event and send the Slack notification using a secure credential.

The integration should include:

- Retry handling
- Error logging
- Idempotency
- Monitoring

This ensures that a Slack failure does not prevent the Loan Enquiry transaction from completing successfully.

---

# 14. Design Decisions & Trade-offs

The implementation prioritizes standard Salesforce functionality, bulk-safe Apex, security enforcement, asynchronous callout processing, and a simple audit trail.

Queueable Apex was selected for the external check because the callout should not block the synchronous Loan Enquiry creation transaction.

The one-retry approach keeps the implementation simple while demonstrating failure handling.

With more time, I would improve:

- Configurable retry/backoff policies
- Integration monitoring
- More detailed security tests
- More granular Experience Cloud sharing
- Additional Agentforce capabilities
- Improved UI/UX
- More comprehensive negative test scenarios

---

# 15. Additional Idea

One potential enhancement would be a **Loan Enquiry Readiness Score**.

The system could evaluate whether a loan application contains the required information and supporting documents before it moves into underwriting.

For example, it could check:

- Applicant information
- Loan amount
- Loan purpose
- Required documents
- Missing documents
- Current application status

The result could be displayed as a simple readiness status such as `Ready`, `Incomplete`, or `Action Required`.

This could reduce manual follow-up between brokers and customers.

The rules could be stored in Custom Metadata so that business users can change document requirements without modifying Apex code. Agentforce could also use the same readiness information to explain what is missing and guide the customer through the next step.

---

# 16. Project Structure

```text
force-app/
└── main/
    └── default/
        ├── classes/
        ├── triggers/
        ├── lwc/
        ├── objects/
        ├── lightningMessageChannels/
        ├── permissionsets/
        └── experiences/
