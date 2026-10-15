# HELP-2: Can't create WarehouseShare / warehouse team can't access shared drive

| Field | Value |
|---|---|
| Jira key | HELP-2 |
| Type | Incident (Report a system problem) |
| Priority | Medium (urgency Medium, impact Moderate/Limited) |
| Affected | Warehouse team (tested as maria.santos on WS01) |
| Status | Resolved |

## Symptom
Setting up the Warehouse shared folder failed in PowerShell. Once the share was created, warehouse users still couldn't open it, and the `H:` drive never appeared in File Explorer.

## Internal notes
**Note 1: Share creation fails**
```
New-SmbShare -Name WarehouseShare -Path C:\Shares\WarehouseShare -FullAccess "LAB\SEC-Warehouse-Staff"
Error: "No mapping between account names and security IDs was done." (System Error 1332)
Folder created fine; failure is on the permission. Windows can't resolve the group name to a SID.
```

**Note 2: Workaround**
```
Created the share through the GUI (Properties → Sharing → Advanced Sharing).
Check Names resolved the group and the share was created.
```

**Note 3: Root cause 1 — group name typo**
```
Get-SmbShareAccess -Name WarehouseShare → AccountName: LAB\SEC-Warhouse-Staff
Group was created with a typo ("Warhouse"). PowerShell needs an exact match; GUI Check
Names found the near match.
Impact: bulk user script targets SEC-Warehouse-Staff, so no warehouse users were in the group.
Fix: renamed group (SamAccountName + CN) to SEC-Warehouse-Staff. Share permission follows
the SID, so no change needed on the share. Added the 5 warehouse users.
```

**Note 4: Root cause 2 — missing NTFS permissions**
```
maria.santos gets "You do not have permission to access" on \\DC01\WarehouseShare.
Share permissions include the group; NTFS permissions on the folder do not.
Fix: icacls C:\Shares\WarehouseShare /grant "LAB\SEC-Warehouse-Staff:(OI)(CI)M"
Maria can now open the share and create files.
```

**Note 5: Root cause 3 — drive map path typo**
```
Share opens by path, but H: doesn't map. gpresult shows GPO-Warehouse-DriveMap applied.
Event log: 0x80070043 (network name cannot be found).
Drive map Location was \\DC01\WarehousesShare (extra "s").
Fix: corrected to \\DC01\WarehouseShare.
```

**Note 6: Verified**
```
maria.santos signs in on WS01 → H: (Warehouse) mapped, opens, test file saves.
```

## Customer reply
```
Hi,

The Warehouse shared folder is now set up, and everyone on the warehouse team has access.
Starting with your next sign-in, it will show up as the H: drive in File Explorer.

If you don't see the H: drive after signing in, or you get an "access denied" message,
reply to this ticket and we'll take care of it.

Thanks,
IT Help Desk
```

## Evidence
![HELP-2 in Jira](../screenshots/34-jira-help2.png)
![Group created with a typo](../screenshots/14-groups-created.png)
![Drive map path typo](../screenshots/25-drivemap-typo.png)

## Resolution
| # | Root cause | Fix |
|---|---|---|
| 1 | Group created as "SEC-Warhouse-Staff" | Renamed group, re-added users |
| 2 | NTFS permissions didn't include the group | Granted Modify with icacls |
| 3 | Drive map path typo ("WarehousesShare") | Corrected path in GPO |

**Lesson:** verify names right after creating them, check both share and NTFS permissions, and browse to paths instead of typing them.
