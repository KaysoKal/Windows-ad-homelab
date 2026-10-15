# Create-OUs.ps1
# Builds the OU structure. Run on DC01. Add -WhatIf to preview first.

$domain = "DC=lab,DC=local"

# Top-level OUs
"LAB-Users","LAB-Computers","LAB-Groups","LAB-ServiceAccounts","LAB-Disabled" |
    ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path $domain }

# Department OUs for users
"Warehouse","Office","IT" |
    ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path "OU=LAB-Users,$domain" }

# Computer OUs by type
"Warehouse-Workstations","Office-Workstations","Handhelds" |
    ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path "OU=LAB-Computers,$domain" }

# Check the result
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName

# Send new computers and users to OUs (which accept GPO links) instead of default containers
redircmp "OU=LAB-Computers,$domain"
redirusr "OU=LAB-Users,$domain"
