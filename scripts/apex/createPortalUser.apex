Contact con = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email = 'loan.portal.user@example.com' LIMIT 1];
Profile p = [SELECT Id FROM Profile WHERE Name = 'Customer Community User' LIMIT 1];

List<User> existing = [SELECT Id FROM User WHERE ContactId = :con.Id LIMIT 1];
User u;
if (existing.isEmpty()) {
    u = new User(
        ContactId = con.Id,
        ProfileId = p.Id,
        Username = 'loan.portal.user@loanapprover.demo',
        Alias = 'lpuser',
        Email = con.Email,
        FirstName = con.FirstName,
        LastName = con.LastName,
        CommunityNickname = 'loanportaluser',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        IsActive = true
    );
    insert u;
} else {
    u = existing[0];
}

PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Loan_Portal_User' LIMIT 1];
List<PermissionSetAssignment> psa = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :u.Id AND PermissionSetId = :ps.Id];
if (psa.isEmpty()) {
    insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
}

System.debug('PORTAL USER ' + u.Id + ' USERNAME loan.portal.user@loanapprover.demo');
