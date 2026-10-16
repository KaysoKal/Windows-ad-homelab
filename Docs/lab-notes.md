# Lab Notes

Notes I kept while building the lab, in the order I did the work. Written in plain language so I can come back to them later.

---

## Part 1: Hyper-V and the domain controller

### Virtual machines and switches
- Created the VMs through Hyper-V Manager.
- Created **LabNet**, an internal virtual switch so the VMs can talk to each other (and to my laptop) but not the internet.
- The **Default Switch** already exists in Hyper-V. It reaches the internet through NAT, so I gave DC01 a second adapter on it for Windows updates:
```powershell
Add-VMNetworkAdapter -VMName DC01 -SwitchName "Default Switch" -Name "Internet"
  ```
- **Tip:** removing a VM does **not** delete its virtual hard disk. The .vhdx file stays on the drive until you delete it yourself.

### Static IP for DC01
DC01 needs a permanent address so WS01 and WS02 can always find it.
```powershell
New-NetIPAddress -InterfaceAlias "LabNet" -IPAddress 192.168.10.10 -PrefixLength 24
```
`-PrefixLength 24` = subnet mask 255.255.255.0 (how much of the address is the network part).

### DNS: the phone book
DC01 is going to be the phone book for `lab.local`, so it points DNS at itself:
```powershell
Set-DnsClientServerAddress -InterfaceAlias "LabNet" -ServerAddresses 127.0.0.1
```

### Keeping the internet adapter out of DNS
- **Why:** DC01 has two adapters. If both register, DNS stores two addresses for DC01 and hands them out in turns (round robin).
- Lab computers can only reach the LabNet address, so sometimes they'd be sent to an address they can't reach → random login failures.
- The internet adapter still works for DC01; it just isn't listed in DNS.
```powershell
Set-DnsClient -InterfaceAlias "Default Switch" -RegisterThisConnectionsAddress $false
```

### Testing the internet connection
```powershell
Test-NetConnection www.google.com -Port 443
```
Better than `ping`. Ping is waving at a house from the street; testing port 443 is knocking on the front door. Ping says a packet got there; port 443 says I can actually use the service.

### Installing AD and creating the domain
```powershell
Install-WindowsFeature -Name AD-Domain-Services,DHCP -IncludeManagementTools
Install-ADDSForest -DomainName "lab.local" -DomainNetbiosName "LAB" -InstallDns
```
- `Install-ADDSForest` builds a brand-new forest, a brand-new AD from nothing. (A forest is the biggest container in AD; mine has one domain.)
- `-DomainName "lab.local"` is the full domain name.
- `-DomainNetbiosName "LAB"` is the short, older-style name. It's why logins look like `LAB\Administrator`.
- `-InstallDns` sets up the phone book on DC01 too.

**Verify the promotion:**
```
nltest /dsgetdc:lab.local
```
Shows which machine is the domain controller, plus the forest and address.

### Problem after promotion: ghost DNS record
Promotion builds a new phone book and can add the internet adapter's address back into it, even after I turned registration off. I removed it in `dnsmgmt.msc` (right-click → Properties → remove the address), then checked:
```powershell
Get-DnsServerResourceRecord -ZoneName "lab.local" -RRType A
```

### DNS forwarders
If DC01 doesn't know a name (like google.com), it asks an outside DNS server and passes the answer back.
```powershell
Add-DnsServerForwarder -IPAddress 8.8.8.8,1.1.1.1
```

### DHCP in three steps
1. **Authorize:** puts DC01 on AD's approved list. A Windows DHCP server won't hand out any addresses until AD says it's allowed.
   ```powershell
   Add-DhcpServerInDC -DnsName DC01.lab.local -IPAddress 192.168.10.10
   ```
2. **Scope:** the range of addresses to hand out.
   ```powershell
   Add-DhcpServerv4Scope -Name "LAB-Scope" -StartRange 192.168.10.100 -EndRange 192.168.10.200 -SubnetMask 255.255.255.0 -State Active
   ```
3. **Options:** extra info clients get with their address, like which DNS server to use.
   ```powershell
   Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -DnsServer 192.168.10.10 -DnsDomain lab.local
   ```

**Clearing Server Manager's yellow "DHCP configuration required" flag** (shows up even after configuring by hand):
```powershell
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
Restart-Service DhcpServer
```

---

## Part 2: The golden image

### Reference machine
Created `C:\Company\build-info.txt` and turned on RDP in Settings, so I could later confirm deployed machines came from the image.

### Sysprep
- Sysprep prepares a Windows install for deployment by **removing PC-specific information** but keeping Windows and everything installed.
- **`/generalize`** strips the unique identity (SID and computer name).
- **`/oobe`** makes the next boot run the setup screens again, so each copy asks for its own name and account.
- Run it from Win+R: `C:\Windows\System32\Sysprep\sysprep.exe`

### Capturing the image
The VM's disk was a checkpoint file (.avhdx), so I used **Edit Disk → Merge** to combine it with its parent into a single new .vhdx, then set it to read-only as the golden image.

---

## Part 3: OUs, groups, and users

### OU structure
```powershell
$domain = "DC=lab,DC=local"        # saves lab.local in a variable

"LAB-Users","LAB-Computers","LAB-Groups","LAB-ServiceAccounts","LAB-Disabled" | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path $domain
}
```
A list of names → `ForEach-Object` loops through them → `$_` is the current name.

Folders inside LAB-Users work the same way; only the path changes:
```powershell
"Warehouse","Office","IT" | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path "OU=LAB-Users,$domain"
}
```
**Pattern:** `list of things | ForEach-Object { do something with $_ }`

**Verify:**
```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name,DistinguishedName
```

### Redirecting the default containers
When a computer joins the domain, AD drops it into a built-in folder called **Computers** by default. New users go into the built-in **Users** folder. Those are containers (CN=), and containers can't have GPOs linked to them. Redirect both to OUs:
```powershell
redircmp "OU=LAB-Computers,$domain"    # new computers go here
redirusr "OU=LAB-Users,$domain"        # new users go here
```
Check the built-in containers (they start with CN=):
```powershell
Get-ADObject -Filter 'ObjectClass -eq "container"' -SearchScope OneLevel -SearchBase "DC=lab,DC=local" |
    Select-Object Name,DistinguishedName
```

### Security groups
```powershell
$groupPath = "OU=LAB-Groups,DC=lab,DC=local"

"SEC-Warehouse-Staff","SEC-Office-Staff","SEC-IT-Helpdesk","SEC-Drive-Warehouse" | ForEach-Object {
    New-ADGroup -Name $_ -GroupScope Global -GroupCategory Security -Path $groupPath
}
```
Same idea as the GUI: `New-ADGroup` = new group, `-GroupScope` = Global, `-GroupCategory` = Security, plus the OU path.

**Verify:**
```powershell
Get-ADGroup -Filter * -SearchBase $groupPath | Select-Object Name,GroupScope,GroupCategory
```

### The new hire CSV
```powershell
New-Item -ItemType Directory -Path C:\lab -Force

@"
FirstName,LastName,Department,Title
John,Walker,Warehouse,Warehouse Associate
Maria,Santos,Warehouse,Forklift Operator
...
"@ | Out-File -FilePath C:\lab\users.csv -Encoding UTF8

Import-Csv C:\lab\users.csv
```
- `@" ... "@` = a block of text across multiple lines
- `Out-File` saves the text as users.csv
- `Import-Csv` reads it back as a table

### Bulk user script
See [`scripts/BulkUser_creation.ps1`](../scripts/BulkUser_creation.ps1).

- `$users = Import-Csv ...` loads all 10 rows into a variable.
- The temporary password is turned into a **SecureString**, the protected format AD requires. AD won't accept a plain password.
- The **backtick** `` ` `` at the end of a line means "this command continues on the next line." It must be the very last character; a space after it breaks the script.

**New-ADUser parameter → ADUC box**

| Parameter | What it is |
|---|---|
| `-Name` | Full/display name (Maria Santos) |
| `-GivenName` / `-Surname` | First / last name |
| `-SamAccountName` | Logon name (maria.santos) |
| `-UserPrincipalName` | Email-style logon (maria.santos@lab.local) |
| `-Department` / `-Title` | Organization tab |
| `-Path` | Which OU it goes in (the folder you'd right-click) |
| `-AccountPassword` | Password (must be a SecureString) |
| `-ChangePasswordAtLogon` | "Must change password" checkbox |
| `-Enabled $true` | Account turned on |
| `-WhatIf` | Preview only, nothing created |

**The trick:** `-Path "OU=$($u.Department),OU=LAB-Users,..."` lets the department column pick the OU, and `SEC-$($u.Department)-Staff` picks the group. One line handles every department.

**Notes:**
- `-WhatIf` still shows errors on `Add-ADGroupMember`, because the user doesn't exist yet during a preview. Normal.
- `Write-Host "Created $sam"` just prints text. It doesn't check whether anything worked, and it prints even during `-WhatIf`.

### Termination script
Tested on a dummy account first (`test.user`, added to SEC-IT-Helpdesk and SEC-IT-Staff). See [`scripts/Terminate-User.ps1`](../scripts/Terminate-User.ps1).

1. Disable the account
2. Reset the password
3. Remove every group except Domain Users
4. Move the account to LAB-Disabled
5. Log it

**Parameters I keep seeing**

| Parameter | Meaning |
|---|---|
| `-Identity` | Which object (user, group, computer) |
| `-Members` | Who to add/remove (group commands) |
| `-Reset` | Admin password reset, no old password needed |
| `-NewPassword` | The new password (must be a SecureString) |
| `-Confirm:$false` | Don't ask "are you sure?" |
| `-TargetPath` | Where to move something |
| `-Path` | Which file or folder |
| `-Value` | What text to write |
| `-ne` / `-eq` | Not equal / equal |
| `\|` | Hand the result to the next command |

---

## Part 4: Workstations

### Deploying from the image
Copied the golden image to a new VM so it starts at the setup screen instead of a full Windows install.

### DHCP reservation
Joined the new computer to the network and reserved an IP for it. At this point DNS pointed at DC01, but the computer was **not** a domain member, so DC01 didn't manage it yet.
```powershell
Add-DhcpServerv4Reservation -ScopeId 192.168.10.0 -IPAddress 192.168.10.150 -ClientId <MAC address>
```

### Joining the domain
```powershell
Add-Computer -DomainName lab.local -Credential (Get-Credential LAB\Administrator) -Restart
```
Being on the network isn't the same as being on the domain: on the network = inside the building; domain-joined = has an employee badge.

---

## Part 5: Group Policy

### Creating and linking GPOs
```powershell
$d = "DC=lab,DC=local"

New-GPO -Name "GPO-Password-Policy"    | New-GPLink -Target $d
New-GPO -Name "GPO-Screen-Lock"        | New-GPLink -Target "OU=LAB-Computers,$d"
New-GPO -Name "GPO-USB-Block"          | New-GPLink -Target "OU=Warehouse-Workstations,OU=LAB-Computers,$d"
New-GPO -Name "GPO-Warehouse-DriveMap" | New-GPLink -Target "OU=Warehouse,OU=LAB-Users,$d"
New-GPO -Name "GPO-Printer-Deploy"     | New-GPLink -Target "OU=Office,OU=LAB-Users,$d"
```
- `New-GPO` creates an empty GPO.
- `|` hands it to the next command.
- `New-GPLink -Target` attaches it to an OU.
- Can also do all of this in `gpmc.msc`.

### Warehouse shared folder
Created the folder, shared it, and mapped it as H: with a GPO. Signed in as maria.santos and ran `gpupdate /force` to test.

The drive didn't show up at first. Maria wasn't in SEC-Warehouse-Staff, because the group name had been misspelled when it was created. The full runbook is in [`runbook-department-share.md`](runbook-department-share.md), and the whole troubleshooting story is in [ticket HELP-2](../tickets/02-warehouse-share-access.md).

### RDP enabled and scoped by policy
One GPO (*GPO-RDP-Workstations*) linked to LAB-Computers, created in `gpmc.msc`:
1. **Turn RDP on:** Computer Configuration → Policies → Administrative Templates → Windows Components → Remote Desktop Services → Remote Desktop Session Host → Connections
2. **Open the firewall:** Computer Configuration → Policies → Administrative Templates → Network → Network Connections → Windows Defender Firewall → Domain Profile → allow inbound Remote Desktop exceptions, limited to the lab subnet
3. **Decide who's allowed:** add the IT Helpdesk security group to the local Remote Desktop Users group

Also make sure the laptop's internal (LabNet) adapter is active, or you can't reach the VMs to test.

### BitLocker with AD key escrow
Install the feature that adds the BitLocker Recovery tab to ADUC:
```powershell
Install-WindowsFeature RSAT-Feature-Tools-BitLocker-BdeAducExt
```
GPO setting: Computer Configuration → Policies → Administrative Templates → Windows Components → BitLocker Drive Encryption → Operating System Drives → **Choose how BitLocker-protected operating system drives can be recovered**.

On the client:
```powershell
gpupdate /force
gpresult /r /scope computer     # is the escrow GPO applied?
Get-Tpm                         # TpmReady : True = good

# 1. Add the recovery password first (creates the 48-digit recovery key)
Add-BitLockerKeyProtector -MountPoint C: -RecoveryPasswordProtector

# 2. Confirm both Tpm and RecoveryPassword exist
(Get-BitLockerVolume C:).KeyProtector | Select-Object KeyProtectorType, KeyProtectorId

# 3. Back up the recovery password to AD
$id = ((Get-BitLockerVolume C:).KeyProtector | Where-Object KeyProtectorType -eq RecoveryPassword).KeyProtectorId
Backup-BitLockerKeyProtector -MountPoint C: -KeyProtectorId $id

# 4. Start encryption
manage-bde -on C: -em xts_aes256 -used -s

# 5. Verify
Get-BitLockerVolume C: | Select-Object VolumeStatus, EncryptionPercentage, KeyProtector
```
- **TPM** = the everyday key. It unlocks the drive automatically at boot after checking nothing was tampered with.
- **Recovery password** = the spare key, stored in AD for emergencies.

---

## PowerShell tips I picked up

### How a command is built
Every cmdlet is **Verb-Noun**: the verb is the action, the noun is the thing. `Get-ADUser` = get (action) a user (thing).

| Verb | Means |
|---|---|
| `Get` | Read and show |
| `New` | Create |
| `Set` | Change something that exists |
| `Add` | Put into |
| `Remove` | Delete or take out |
| `Start` / `Stop` | Turn on / off |
| `Enable` / `Disable` | Switch an account or feature on / off |

After the command come the details: a **parameter** (the dash part, the placeholder) and its **argument** (the actual value).
```powershell
New-ADUser -Name "Maria Santos"
#          ^parameter ^argument
```
The dash marks a parameter, **not** a variable.

### DNS records
- **A** = name → IP (`dc01` → 192.168.10.10). Created automatically when DC01 was promoted.
- **CNAME** = nickname → real name (`dc` → `dc01.lab.local`). Never automatic.
- **SRV** = service → server + port (`_ldap._tcp` → dc01:389). How computers find the DC.
- View: `Get-DnsServerResourceRecord -ZoneName "lab.local"` (add `-RRType A` to filter)
- Help desk clue: can't find the domain or random sign-in failures → check DNS first.
- 
### The building blocks

| Symbol | What it does |
|---|---|
| `$name` | A variable: stores a value to reuse |
| `=` | Assigns a value to a variable |
| `.` | Reaches into an object and grabs one property: `$user.Name` |
| `\|` | Pipe: the left command produces objects and hands them to the right command |
| `$true` / `$false` | Yes / no values |
| `-eq` `-ne` `-lt` `-gt` | Equal, not equal, less than, greater than |
| `` ` `` | Backtick: "this command isn't done, it continues on the next line" (must be the last character) |
| `$_` | "The current item" inside a pipe loop |

### Loops
```powershell
# Loop over a list you already have
foreach ($item in $collection) {
    # do something with $item
}

# Loop over whatever the pipe hands you
"Warehouse","Office","IT" | ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path "OU=LAB-Users,DC=lab,DC=local" }
```

### Reading a CSV two ways
```powershell
Import-Csv C:\lab\users.csv     # shows it as a table with columns
Get-Content C:\lab\users.csv    # shows the raw text exactly as typed
```

### Finding commands
- **Ctrl+Space** lists options for a command, like `?` on a Cisco device.
- `Get-Command *dhcp*` finds commands by keyword.
- `Get-Help <command> -Examples` shows working examples.

### Objects and Select-Object
An object is one thing with a list of facts about it, like a contact card in your phone:
- The card = the object (Maria)
- The labels on the card = properties (Name, Enabled, LockedOut)

| You want | Use |
|---|---|
| A few facts as a table | `Select-Object Name, Enabled` |
| One fact, just the value | `(Get-ADUser maria.santos).Enabled` |
| Every fact on the card | `Select-Object *` or `-Properties *` |
| List all property names | `\| Get-Member -MemberType Property` |

**Text tools vs. object cmdlets:** older tools (`ipconfig`, `nslookup`, `ping`, `net use`, `icacls`, `manage-bde`) print text I read myself. Cmdlets with Verb-Noun names hand back objects I can pick fields from.

**In one sentence:** a command hands me cards, and Select-Object picks which lines on the card I want to see.

---

## Help desk command cheat sheet

### Account problems
```powershell
# Check the account first
Get-ADUser <user> -Properties Enabled,LockedOut,LastLogonDate,PasswordLastSet,PasswordExpired,MemberOf

Unlock-ADAccount -Identity <user>                                   # locked out
Enable-ADAccount -Identity <user>                                   # account disabled
Set-ADAccountPassword -Identity <user> -Reset -NewPassword (Read-Host "New password" -AsSecureString)
Set-ADUser -Identity <user> -ChangePasswordAtLogon $true            # make them pick their own
```
If the account looks fine and they still can't sign in, it's usually **DNS or time**: check `nslookup lab.local` and `ipconfig /all`.

| Property | Answers |
|---|---|
| Enabled | Is the account turned on? |
| LockedOut | Locked from too many bad passwords? |
| LastLogonDate | When did they last sign in? |
| PasswordLastSet | When was the password changed? |
| PasswordExpired | Does the password need resetting? |
| MemberOf | What groups are they in? |
| DistinguishedName | Which OU do they live in? |

### Finding people and things
```powershell
Get-ADUser -Filter * -SearchBase "OU=Warehouse,OU=LAB-Users,DC=lab,DC=local" | Select-Object Name
Get-ADUser -Identity <user> -Properties *
```

### Groups and access
```powershell
Get-ADPrincipalGroupMembership -Identity <user> | Select-Object Name    # what groups is this person in?
Get-ADGroupMember -Identity "SEC-Office-Staff" | Select-Object Name    # who is in this group?
Add-ADGroupMember -Identity "SEC-Office-Staff" -Members <user>
Remove-ADGroupMember -Identity "SEC-Office-Staff" -Members <user> -Confirm:$false
```
New group membership only takes effect after the user signs out and back in.

### Offboarding: a random password nobody knows
```powershell
$random = ConvertTo-SecureString ("Xq9!" + [guid]::NewGuid()) -AsPlainText -Force
Set-ADAccountPassword -Identity <user> -Reset -NewPassword $random
```
`[guid]::NewGuid()` generates a long random string, so no one (including IT) knows the new password.

### Group Policy
```powershell
gpupdate /force                 # reapply policy now instead of waiting
gpresult /r                     # which GPOs applied to this user and computer
gpresult /r /scope computer     # computer policies only (run as admin)
gpresult /r /user <user>        # policies for a specific user
gpresult /h report.html         # full readable report, open it in a browser
```

### Auditing accounts
```powershell
Get-ADUser -Filter {Enabled -eq $false} | Select-Object Name                   # disabled accounts
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 | Select-Object Name    # stale, 90+ days
Search-ADAccount -LockedOut | Select-Object Name                                # currently locked out
Search-ADAccount -PasswordExpired | Select-Object Name                          # expired passwords
```

### Health checks and diagnostics
```powershell
Get-Service DHCPServer,DNS,NTDS | Select-Object Name,Status    # core DC services running?
Test-NetConnection dc01.lab.local -Port 445                    # can I reach file sharing (SMB)?
Get-NetIPConfiguration                                         # IP, gateway, DNS at a glance
Clear-DnsClientCache                                           # flush stale DNS answers
```
On the DC, if something domain-wide feels wrong:
```powershell
dcdiag /v | Select-String "failed"    # run DC health tests, show only failures
nltest /dsgetdc:lab.local             # which DC answers for the domain?
repadmin /replsummary                 # replication health (matters with 2+ DCs)
```

### Putting a computer in the right OU before it joins
Pre-stage the computer object so it lands in the right OU (and gets the right GPOs) the moment it joins:
```powershell
New-ADComputer -Name "WS02" -Path "OU=Office-Workstations,OU=LAB-Computers,DC=lab,DC=local"
```
Or redirect every new computer with `redircmp`, as in Part 3.

### Checkpoints
```powershell
Checkpoint-VM -Name DC01 -SnapshotName "Promoted-Clean"    # run on the Hyper-V host
```
A checkpoint is like saving in a video game: a quick undo before a patch or risky change. For a real domain controller, restore from **backup** instead of rolling back a snapshot, because rolling back can break replication. Snapshot = short-term undo; backup = real recovery.

