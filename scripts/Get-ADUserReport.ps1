
# Get-ADUserReport.ps1
# Collects information about Active Directory users and exports it to CSV.

Write-Host "`n=== ACTIVE DIRECTORY USER REPORT ===" -ForegroundColor Cyan

# 1. Import Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

# 2. Get domain information
$Domain = Get-ADDomain
$DomainDN = $Domain.DistinguishedName

# 3. Get all domain users
$Users = Get-ADUser -Filter * `
    -SearchBase $DomainDN `
    -Properties Enabled, LastLogonDate, PasswordLastSet, Department, Title, Description

# 4. Build user report
$UserReport = foreach ($User in $Users) {
    [PSCustomObject]@{
        Name              = $User.Name
        SamAccountName    = $User.SamAccountName
        UserPrincipalName = $User.UserPrincipalName
        Enabled           = $User.Enabled
        LastLogonDate     = $User.LastLogonDate
        PasswordLastSet   = $User.PasswordLastSet
        Department        = $User.Department
        Title             = $User.Title
        Description       = $User.Description
        DistinguishedName = $User.DistinguishedName
    }
}

# 5. Export report to CSV
$Desktop = [Environment]::GetFolderPath("Desktop")

$FileName = "ADUserReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$OutputPath = Join-Path $Desktop $FileName

$UserReport | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

# 6. Display results
$UserReport | Format-Table Name, SamAccountName, Enabled, LastLogonDate -AutoSize

Write-Host "`nTotal users found: $($Users.Count)" -ForegroundColor Cyan
Write-Host "Report saved to: $OutputPath" -ForegroundColor Green