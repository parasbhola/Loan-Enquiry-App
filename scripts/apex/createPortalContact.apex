Account acc;
List<Account> existing = [SELECT Id FROM Account WHERE Name = 'Loan Portal Customers' LIMIT 1];
if (existing.isEmpty()) {
    acc = new Account(Name = 'Loan Portal Customers', OwnerId = UserInfo.getUserId());
    insert acc;
} else {
    acc = existing[0];
}

Contact con;
List<Contact> cons = [SELECT Id FROM Contact WHERE Email = 'loan.portal.user@example.com' LIMIT 1];
if (cons.isEmpty()) {
    con = new Contact(
        FirstName = 'Loan',
        LastName = 'Portal User',
        Email = 'loan.portal.user@example.com',
        AccountId = acc.Id
    );
    insert con;
} else {
    con = cons[0];
}

System.debug('ACCOUNT ' + acc.Id + ' CONTACT ' + con.Id);
