# Screenshots

Every screenshot from the build, in order. Passwords and recovery keys are blacked out.

## Domain controller and network

**Renamed the server to DC01**

![Renamed the server to DC01](../screenshots/01-dc01-rename.png)

**Named the adapters LabNet and Default Switch**

![Named the adapters LabNet and Default Switch](../screenshots/02-dc01-adapters.png)

**Added a second NIC on the Default Switch for internet access**

![Added a second NIC on the Default Switch for internet access](../screenshots/03-dc01-second-nic.png)

**Static lab IP, and DNS registration turned off on the internet adapter**

![Static lab IP, and DNS registration turned off on the internet adapter](../screenshots/04-dc01-ip-dns-register.png)

**Internet test with Test-NetConnection on port 443**

![Internet test with Test-NetConnection on port 443](../screenshots/05-dc01-internet-test.png)

**Domain controller verified with nltest; DHCP authorized in AD**

![Domain controller verified with nltest; DHCP authorized in AD](../screenshots/06-dc01-promoted-nltest.png)

**Ghost DNS record (172.x) before and after cleanup**

![Ghost DNS record (172.x) before and after cleanup](../screenshots/07-dns-ghost-record.png)

**DNS forwarders added and outside name resolution tested**

![DNS forwarders added and outside name resolution tested](../screenshots/08-dns-forwarders.png)

**DHCP scope created**

![DHCP scope created](../screenshots/09-dhcp-scope.png)

**Server Manager flag cleared; core services running**

![Server Manager flag cleared; core services running](../screenshots/10-dhcp-services.png)

## Reference image

**Reference machine firmware and TPM check**

![Reference machine firmware and TPM check](../screenshots/11-ref01-tpm-secureboot.png)

## Identity

**OU structure created and verified**

![OU structure created and verified](../screenshots/12-ou-structure.png)

**Default computer and user containers redirected to OUs**

![Default computer and user containers redirected to OUs](../screenshots/13-redirection.png)

**Security groups created (note the SEC-Warhouse-Staff typo that caused HELP-2)**

![Security groups created (note the SEC-Warhouse-Staff typo that caused HELP-2)](../screenshots/14-groups-created.png)

**New hire CSV**

![New hire CSV](../screenshots/15-users-csv.png)

**Bulk user script and output**

![Bulk user script and output](../screenshots/16-bulk-users.png)

**Termination script run on a test user**

![Termination script run on a test user](../screenshots/17-termination-script.png)

## Workstations

**WS01 gets its reserved address, 192.168.10.150**

![WS01 gets its reserved address, 192.168.10.150](../screenshots/18-dhcp-reservation-ws01.png)

**Domain join failed on a typo (Adminstrator), then retried**

![Domain join failed on a typo (Adminstrator), then retried](../screenshots/19-domain-join-typo.png)

## Group Policy

**GPOs created and linked with PowerShell**

![GPOs created and linked with PowerShell](../screenshots/20-gpo-create-script.png)

**GPO links in Group Policy Management**

![GPO links in Group Policy Management](../screenshots/21-gpmc-links.png)

**Password policy settings**

![Password policy settings](../screenshots/22-gpo-password-policy.png)

**Computer policy applied on WS01 (Office-Workstations)**

![Computer policy applied on WS01 (Office-Workstations)](../screenshots/23-gpresult-ws01.png)

**Drive map GPO applied to a warehouse user**

![Drive map GPO applied to a warehouse user](../screenshots/24-gpresult-maria.png)

**Drive map path typo (WarehousesShare) that caused part of HELP-2**

![Drive map path typo (WarehousesShare) that caused part of HELP-2](../screenshots/25-drivemap-typo.png)

## Remote Desktop

**RDP port 3389 reachable on WS01**

![RDP port 3389 reachable on WS01](../screenshots/26-rdp-port-test.png)

**Warehouse user refused remote sign-in**

![Warehouse user refused remote sign-in](../screenshots/27-rdp-refused.png)

## BitLocker

**TPM ready; recovery password added (redacted)**

![TPM ready; recovery password added (redacted)](../screenshots/28-tpm-check.png)

**The two Enable-BitLocker errors**

![The two Enable-BitLocker errors](../screenshots/29-bitlocker-errors.png)

**Recovery password protector added (redacted)**

![Recovery password protector added (redacted)](../screenshots/30-bitlocker-recovery-password.png)

**Key backed up to AD and encryption started**

![Key backed up to AD and encryption started](../screenshots/31-bitlocker-encrypting.png)

**Fully encrypted; recovery key on the computer object in AD (redacted)**

![Fully encrypted; recovery key on the computer object in AD (redacted)](../screenshots/32-bitlocker-ad.png)

## Service desk (Jira)

**HELP-1: onboarding request, resolved**

![HELP-1: onboarding request, resolved](../screenshots/33-jira-help1.png)

**HELP-2: share creation incident**

![HELP-2: share creation incident](../screenshots/34-jira-help2.png)

**HELP-2: internal notes and customer reply**

![HELP-2: internal notes and customer reply](../screenshots/35-jira-help2-notes.png)
