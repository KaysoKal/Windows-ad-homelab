# BulkUser_creation.ps1
# Creates AD users from users.csv, places each in their department OU,
# and adds them to their department's security group (SEC-<Department>-Staff).
# Run on DC01. Skips anyone who already exists, so it's safe to re-run.

$users = Import-Csv C:\lab\users.csv
$pw    = Read-Host "Temporary password for new users" -AsSecureString

foreach ($u in $users) {
    $sam = "$($u.FirstName).$($u.LastName)".ToLower()

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Warning "$sam exists - skipping"
        continue
    }

    New-ADUser -Name "$($u.FirstName) $($u.LastName)" `
        -GivenName $u.FirstName -Surname $u.LastName `
        -SamAccountName $sam -UserPrincipalName "$sam@lab.local" `
        -Department $u.Department -Title $u.Title `
        -Path "OU=$($u.Department),OU=LAB-Users,DC=lab,DC=local" `
        -AccountPassword $pw -ChangePasswordAtLogon $true -Enabled $true

    Add-ADGroupMember -Identity "SEC-$($u.Department)-Staff" -Members $sam
    Write-Host "Created $sam"
}
