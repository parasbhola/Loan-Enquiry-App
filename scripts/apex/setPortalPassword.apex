// Replace REPLACE_ME with a password, then run:
//   sf apex run --file scripts/apex/setPortalPassword.apex --target-org LoanApproverDev
User u = [SELECT Id FROM User WHERE Username = 'loan.portal.user@loanapprover.demo' LIMIT 1];
System.setPassword(u.Id, 'REPLACE_ME');
