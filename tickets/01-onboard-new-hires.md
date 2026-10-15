# HELP-1: Onboard 10 new hires from HR list

| Field | Value |
|---|---|
| Jira key | HELP-1 |
| Type | Service request (Onboard new employees) |
| Priority | Medium |
| Requester | HR |
| Status | Resolved |

## Request
HR sent a list of 10 new hires across Warehouse, Office, and IT. Each needs an AD account in their department's OU and membership in their department's security group.

## Internal notes
**Note 1: Prep**
```
Converted HR list to C:\lab\users.csv (FirstName, LastName, Department, Title).
Confirmed department groups exist: SEC-Warehouse-Staff, SEC-Office-Staff.
SEC-IT-Staff was missing; the script builds the group name as SEC-<Department>-Staff,
so IT users would have failed. Created SEC-IT-Staff first.
```

**Note 2: Preview**
```
Ran BulkUser_creation.ps1 with -WhatIf. Output showed all 10 already existed from earlier
testing. Removed the test accounts and re-ran the preview. All 10 targeted the
correct OU (OU=<Department>,OU=LAB-Users,DC=lab,DC=local) and group.
```

**Note 3: Created**
```
Ran the script for real. 10 created, 0 skipped, 0 failed.
Accounts set to change password at first logon.
Added marcus.johnson to SEC-IT-Helpdesk (needed for workstation RDP access).
```

**Note 4: Verified**
```
Get-ADUser -SearchBase per department OU confirmed placement.
Get-ADGroupMember per department group confirmed membership.
```

## Customer reply
```
Hi,

All 10 new hire accounts are set up and ready. Each person will sign in with their
first.last username and the temporary password we'll give them on day one. They'll be
asked to choose their own password at first sign-in.

Let us know if anyone's department or title needs to change.

Thanks,
IT Help Desk
```

## Screenshot
![HELP-1 in Jira](../screenshots/33-jira-help1.png)

## Resolution
Accounts created by script from CSV, previewed first, placed by department, verified in AD.
