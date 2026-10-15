# Terminate-User.ps1
# Offboards one user. Change $name, then run on DC01.

$name = "test.user"

# 1. Disable the account
Disable-ADAccount -Identity $name

# 2. Reset the password so the old one no longer works
$newPw = Read-Host "New password for $name" -AsSecureString
Set-ADAccountPassword -Identity $name -Reset -NewPassword $newPw

# 3. Remove every group except Domain Users
$groups = Get-ADPrincipalGroupMembership $name | Where-Object Name -ne "Domain Users"
foreach ($g in $groups) {
    Remove-ADGroupMember -Identity $g -Members $name -Confirm:$false
}

# 4. Move the account to the disabled OU
Get-ADUser $name | Move-ADObject -TargetPath "OU=LAB-Disabled,DC=lab,DC=local"

# 5. Log it, including removed groups, so it can be reversed if needed
Add-Content -Path C:\lab\termination-log.txt -Value "$(Get-Date) - terminated $name - groups removed: $($groups.Name -join ', ')"

Write-Host "Done: $name terminated"
