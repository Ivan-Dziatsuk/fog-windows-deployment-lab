# Active Directory Domain Services

![Active Directory](https://img.shields.io/badge/ACTIVE_DIRECTORY-contoso.local-0969DA?style=flat-square)
![Domain Controller](https://img.shields.io/badge/DOMAIN_CONTROLLER-DC01-0078D4?style=flat-square)
![Operating System](https://img.shields.io/badge/WINDOWS_SERVER-2022-0078D4?style=flat-square)

## Overview

I set up Active Directory Domain Services on DC01 to manage users, computers, and authentication in the lab.

The domain is contoso.local. I organized domain objects into separate Organizational Units so that users, computers, groups, and servers are easier to manage.

The environment is also used to practice joining Windows clients to the domain, moving computer accounts between OUs, and checking domain connectivity.

## Domain Information

| Parameter | Value |
|---|---|
| Domain Name | contoso.local |
| Domain Controller | DC01 |
| Domain Controller IP | 192.168.10.10 |
| Operating System | Windows Server 2022 |
| Domain Functional Level | Windows Server 2016 |
| Forest Functional Level | Windows Server 2016 |
| DNS Server | DC01 |

The domain and forest functional levels are set to Windows Server 2016. This does not mean that the domain controller is running Windows Server 2016; the actual operating system on DC01 is Windows Server 2022.

## Organizational Units

I created the following OU structure to keep the domain objects organized.

| Organizational Unit | Purpose |
|---|---|
| Domain Controllers | Domain controller computer accounts |
| Groups | Security and distribution groups |
| Servers | Server computer accounts |
| IT-Users | IT department user accounts |
| IT-Computers | IT workstation computer accounts |

This structure also makes it easier to link Group Policy Objects to specific groups of computers or users.

## Managing Users and Computers

### Domain User

One of the domain accounts created in the lab is Client1.

| Parameter | Value |
|---|---|
| Name | Client1 |
| SamAccountName | client1 |
| User Principal Name | client1@contoso.local |
| Organizational Unit | IT-Users |
| Account Status | Enabled |

The Client1 account is a domain user account stored in IT-Users. It should not be confused with a computer account.

### Creating a User Through Active Directory Users and Computers

1. Open Server Manager on DC01.
2. Select Tools → Active Directory Users and Computers.
3. Expand contoso.local.
4. Open the IT-Users OU.
5. Right-click the OU and select New → User.
6. Enter the user's name and logon name.
7. Set an account password.
8. Configure the required password options.
9. Finish the wizard.

### Managing Computer Accounts

Computer accounts are stored separately from user accounts.

In this lab, workstation computer accounts are organized in IT-Computers.

To move a computer account into the correct OU:

1. Open Active Directory Users and Computers.
2. Locate the required computer account.
3. Right-click the account and select Move.
4. Select IT-Computers.
5. Confirm the operation.

Separating users and computers into different OUs makes it possible to manage their policies independently.

## PowerShell Administration

I also use PowerShell to inspect and manage Active Directory objects. The following examples can be run on DC01 with the Active Directory module available.

### Domain and Forest Information

```powershell
Get-ADDomain
Get-ADForest
```

These commands display domain settings, forest settings, and functional levels.

### List Organizational Units

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName
```

### Create an Organizational Unit

The following example checks whether an OU already exists before creating it.

```powershell
$OUName = "IT-Users"
$DomainDN = "DC=contoso,DC=local"

$ExistingOU = Get-ADOrganizationalUnit `
    -Filter "Name -eq '$OUName'" `
    -SearchBase $DomainDN

if (-not $ExistingOU) {
    New-ADOrganizationalUnit `
        -Name $OUName `
        -Path $DomainDN
}
else {
    Write-Host "OU already exists: $OUName"
}
```

This is a reusable example. The IT-Users OU is already present in the lab.

### Create a Domain User

Example of creating an additional account:

```powershell
$Password = Read-Host "Enter password" -AsSecureString

New-ADUser `
    -Name "User2" `
    -SamAccountName "user2" `
    -UserPrincipalName "user2@contoso.local" `
    -Path "OU=IT-Users,DC=contoso,DC=local" `
    -AccountPassword $Password `
    -Enabled $true
```

This example creates User2. It does not recreate or modify the existing Client1 account.

### List Domain Users

```powershell
Get-ADUser -Filter * |
    Select-Object Name, SamAccountName, Enabled
```

### List Domain Computers

```powershell
Get-ADComputer -Filter * |
    Select-Object Name, DistinguishedName
```

### Move a Computer to an OU

Before moving a computer, check its current Distinguished Name:

```powershell
Get-ADComputer -Identity "COMPUTER-NAME" |
    Select-Object Name, DistinguishedName
```

Then use its actual Distinguished Name:

```powershell
Move-ADObject `
    -Identity "CN=COMPUTER-NAME,CN=Computers,DC=contoso,DC=local" `
    -TargetPath "OU=IT-Computers,DC=contoso,DC=local"
```

Replace COMPUTER-NAME and the source Distinguished Name with the actual values from your domain.

## Domain Joining and Verification

Windows clients can be joined to the domain through the Windows system settings or PowerShell.

The following example joins a computer to contoso.local and places its computer account directly in IT-Computers.

```powershell
Add-Computer `
    -DomainName "contoso.local" `
    -OUPath "OU=IT-Computers,DC=contoso,DC=local" `
    -Credential "contoso\Administrator" `
    -Restart
```

This operation requires valid domain credentials and connectivity to DC01.

### Check Domain Membership

Run on the Windows client:

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

### Verify Secure Channel

```powershell
Test-ComputerSecureChannel -Verbose
```

This checks the secure channel between the domain-joined computer and its domain controller.

The domain membership and Secure Channel were tested on WIN11-TEST.

### Find the Domain Controller

```powershell
nltest /dsgetdc:contoso.local
```

This command checks whether a domain controller can be discovered for contoso.local.

## Verification on DC01

The following commands can be used to inspect the current Active Directory configuration.

### Domain Information

```powershell
Get-ADDomain |
    Select-Object DNSRoot, DomainMode, PDCEmulator
```

### Forest Information

```powershell
Get-ADForest |
    Select-Object RootDomain, ForestMode
```

### Organizational Units

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName
```

### Existing Client1 Account

```powershell
Get-ADUser -Identity "client1" -Properties Enabled, UserPrincipalName |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled
```

### Computer Accounts

```powershell
Get-ADComputer -Filter * |
    Select-Object Name, DistinguishedName
```

## Screenshots

The following screenshots document the Active Directory configuration:

| Screenshot | Description |
|---|---|
| 01-ad-domain.png | Domain structure in Active Directory Users and Computers |
| 02-ad-organizational-units.png | Organizational Unit structure |
| 03-ad-users.png | Domain user accounts, including Client1 |
| 04-ad-computers.png | Domain computer accounts |
| 05-ad-powershell.png | PowerShell domain and OU verification |

Only screenshots showing actual lab configuration should be included.

## Summary

DC01 provides centralized identity and computer management through Active Directory.

I organized the domain into separate OUs, created domain accounts, managed computer objects, and joined Windows 11 clients to the domain.

Both Active Directory Users and Computers and PowerShell are used for administration. Domain membership and Secure Channel connectivity were also tested on WIN11-TEST.
