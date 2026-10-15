# Create-GPOs.ps1
# Creates GPOs and links each one where it should apply. Run on DC01.
# Settings inside each GPO are configured afterward in the Group Policy Management Editor.
# (GPO-Password-Policy is linked at the domain root, since password rules only work there.)

$d = "DC=lab,DC=local"

New-GPO -Name "GPO-Screen-Lock"        | New-GPLink -Target "OU=LAB-Computers,$d"
New-GPO -Name "GPO-USB-Block"          | New-GPLink -Target "OU=Warehouse-Workstations,OU=LAB-Computers,$d"
New-GPO -Name "GPO-Warehouse-DriveMap" | New-GPLink -Target "OU=Warehouse,OU=LAB-Users,$d"
New-GPO -Name "GPO-Printer-Deploy"     | New-GPLink -Target "OU=Office,OU=LAB-Users,$d"

Get-GPO -All | Select-Object DisplayName, GpoStatus
