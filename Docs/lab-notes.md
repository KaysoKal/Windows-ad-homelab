# Lab Notes

Notes I kept while building the lab, in the order I did the work. Written in plain language so I can come back to them later.

---

## Hyper-V setup
- Created the VMs through Hyper-V Manager.
- **LabNet** is an internal virtual switch, so the VMs can talk to each other and to my host, but not to the internet or my home network.
- DC01 also has a second adapter on Hyper-V's **Default Switch**, which gives it internet through NAT for Windows updates.
- **Tip:** removing a VM in Hyper-V does **not** delete its virtual hard disk. The .vhdx file stays on the drive until you delete it yourself.

## Static IP for the domain controller
DC01 needs a permanent address so every machine can always find it.
```powershell
New-NetIPAddress -InterfaceAlias "LabNet" -IPAddress 192.168.10.10 -PrefixLength 24
```
`-PrefixLength 24` = subnet mask 255.255.255.0.

## DNS: the phone book
DC01 is going to be the phone book for `lab.local`, so it points to itself:
```powershell
Set-DnsClientServerAddress -InterfaceAlias "LabNet" -ServerAddresses 127.0.0.1
```

## Keeping the internet adapter out of DNS
- DC01 has two adapters. If both register in DNS, DNS stores two addresses for DC01 and hands them out in turns (round robin).
- Lab computers can only reach the LabNet address, so sometimes they'd be sent to an address they can't reach, causing random login failures.
- The internet adapter still works for DC01; it just isn't listed in DNS.
```powershell
Set-DnsClient -InterfaceAlias "externalVMConnection" -RegisterThisConnectionsAddress $false
```

## Testing the internet connection
```powershell
Test-NetConnection www.google.com -Port 443
```
Better than `ping`. Ping is waving at a house from the street; testing port 443 is knocking on the front door to see if the service actually answers.

## Installing AD and creating the domain
```powershell
Install-WindowsFeature -Name AD-Domain-Services,DHCP -IncludeManagementTools
Install-ADDSForest -DomainName "lab.local" -DomainNetbiosName "LAB" -InstallDns
```
- `Install-ADDSForest` builds a brand-new forest (the biggest container in AD). Mine has one domain.
- `-DomainName "lab.local"` is the full domain name.
- `-DomainNetbiosName "LAB"` is the short, older-style name. It's why logins look like `LAB\Administrator`.
- `-InstallDns` sets up the phone book on DC01.

**Verify:**
```
nltest /dsgetdc:lab.local
```
Shows which machine is the domain controller, plus the forest and address.

## Problem after promotion: ghost DNS record
Promotion re-registered the internet adapter's address in the new DNS zone. Removed it in `dnsmgmt.msc` and verified:
```powershell
Get-DnsServerResourceRecord -ZoneName "lab.local" -RRType A
```

## DNS forwarders
If DC01 doesn't know a name (like google.com), it asks an outside DNS server and passes the answer back.

## DHCP in three steps
1. **Authorize:** puts DC01 on AD's approved list. A Windows DHCP server won't hand out addresses until AD allows it.
2. **Scope:** the range of addresses to hand out.
   ```powershell
   Add-DhcpServerv4Scope -Name "LAB-Scope" -StartRange 192.168.10.100 -EndRange 192.168.10.200 -SubnetMask 255.255.255.0 -State Active
   ```
3. **Options:** extra info clients get with their address, like which DNS server to use.
   ```powershell
   Set-DhcpServerv4OptionValue -ScopeId 192.168.10.0 -DnsServer 192.168.10.10 -DnsDomain lab.local
   ```

**Clearing Server Manager's "DHCP configuration required" flag** (shows up even after configuring by hand):
```powershell
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2
```
Then restart the DHCP service.

## Reference image
Created `C:\Company\build-info.txt` and turned on RDP on the reference machine, so I could later confirm deployed machines came from the image.

## Sysprep
Sysprep removes a computer's unique identity (name and SID) but keeps Windows and everything installed, so each copy starts fresh as its own machine.

---

## PowerShell tips I picked up
- **Ctrl+Space** lists options for a command, like `?` on a Cisco device.
- **Objects:** a command hands back "cards" with labeled facts (properties). `Select-Object` picks which facts to show.
- **Which machine to run it on:** the one that owns the thing being changed. AD objects on DC01, VMs on the Hyper-V host, a computer's name on that computer.
- **Script runs but nothing happens?** Check the file's Length. 0 bytes means it's empty.
