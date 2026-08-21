User u = [SELECT Id FROM User WHERE Username = 'loan.test@loanapprover.demo' LIMIT 1];
PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Loan_Portal_User' LIMIT 1];
if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :u.Id AND PermissionSetId = :ps.Id] == 0) {
    insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
}
System.debug('DONE ' + u.Id);
