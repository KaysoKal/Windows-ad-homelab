# Runbook: Create a Department File Share

Reusable for any department. Swap the folder, share, and group names.

## On the file server (DC01)

**0. Confirm the group's exact name**
```powershell
Get-ADGroup -Filter "Name -like 'SEC*'" | Select-Object Name
```

**1. Create the folder**
```powershell
New-Item -ItemType Directory -Path C:\Shares\WarehouseShare -Force
```

**2. Share it (share permissions)**
```powershell
New-SmbShare -Name WarehouseShare -Path C:\Shares\WarehouseShare -FullAccess "LAB\SEC-Warehouse-Staff"
```

**3. Grant folder permissions (NTFS)**
```powershell
icacls C:\Shares\WarehouseShare /grant "LAB\SEC-Warehouse-Staff:(OI)(CI)M"
```
`M` = Modify (read, write, delete). `(OI)(CI)` = applies to files and subfolders.

**4. Verify both layers**
```powershell
Get-SmbShareAccess -Name WarehouseShare
(Get-Acl C:\Shares\WarehouseShare).Access | Select-Object IdentityReference, FileSystemRights
```
The group must appear in **both** lists.

## Map the drive (Group Policy)
GPO linked to the department's user OU → **User Configuration → Preferences → Windows Settings → Drive Maps → New → Mapped Drive**

| Field | Value |
|---|---|
| Action | Update |
| Location | `\\DC01\WarehouseShare` (use the **...** button to browse) |
| Reconnect | ✅ |
| Label | Warehouse |
| Drive letter | H |

## Test from a workstation (as a department user)

| Check | Command | If it fails |
|---|---|---|
| SMB reachable | `Test-NetConnection DC01 -Port 445` | Network or firewall |
| Can open share | `Test-Path \\DC01\WarehouseShare` | Share/NTFS permissions or group membership |
| Can write | `New-Item \\DC01\WarehouseShare\test.txt -ItemType File` | NTFS is Read, not Modify |
| Drive mapped | `net use` | Drive map GPO path or letter |

New group membership only takes effect after the user **signs out and back in**.
