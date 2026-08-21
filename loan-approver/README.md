# Loan Approver Project

## Overview
The Loan Approver project is designed to facilitate the processing of loan enquiries within a Salesforce environment. It utilizes Lightning Message Channels to enable communication between different components of the application.

## Files Included
- **Loan_Enquiry_Selected.messageChannel-meta.xml**: This file defines a Lightning Message Channel named "Loan Enquiry Selected". It includes a field `Loan_Enquiry_Id__c`, which represents the Loan Enquiry record Id.
  
- **sfdx-project.json**: This configuration file is used for Salesforce DX. It specifies the project structure, including package directories and other metadata settings required for deployment.

## Setup Instructions
1. Clone the repository to your local machine.
2. Navigate to the project directory.
3. Ensure you have Salesforce CLI installed and authenticated to your Salesforce org.
4. Run the following command to deploy the metadata:
   ```
   sfdx force:source:deploy -p force-app/main/default
   ```

## Deployment Instructions
To deploy the project to your Salesforce org, use the Salesforce CLI commands as follows:
1. Authenticate to your Salesforce org:
   ```
   sfdx force:auth:web:login -a YourAlias
   ```
2. Deploy the source:
   ```
   sfdx force:source:deploy -p force-app/main/default
   ```

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.