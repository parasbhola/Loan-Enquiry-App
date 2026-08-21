User u = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId()];
if (u.UserRoleId == null) {
    List<UserRole> roles = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
    UserRole r;
    if (roles.isEmpty()) {
        r = new UserRole(Name = 'Portal Account Owner', DeveloperName = 'Portal_Account_Owner');
        insert r;
    } else {
        r = roles[0];
    }
    u.UserRoleId = r.Id;
    update u;
    System.debug('ASSIGNED ROLE ' + r.Id);
} else {
    System.debug('ROLE ALREADY SET ' + u.UserRoleId);
}
