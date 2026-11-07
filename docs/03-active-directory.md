# Active Directory Domain Services

## 1. Overview

Active Directory Domain Services (AD DS) provides centralized authentication, authorization, and management of users and computers in the lab environment.

The domain controller is `DC01`, running Windows Server 2022.

### Domain Information

| Parameter | Value |
|---|---|
| Domain Name | `contoso.local` |
| Domain Controller | `DC01` |
| Domain Controller IP | `192.168.10.10` |
| Domain Functional Level | Windows Server 2016 |
| Forest Functional Level | Windows Server 2016 |
| DNS Server | `DC01` |

## 2. Organizational Unit Structure

The domain contains the following Organizational Units:

| OU | Purpose |
|---|---|
| Domain Controllers | Domain controller computer accounts |
| Groups | Security and distribution groups |
| Servers | Server computer accounts |
| IT-Users | IT department user accounts |
| IT-Computers | IT workstation computer accounts |

This structure helps organize domain objects and allows Group Policy to be applied to specific organizational units.

## 3. GUI Configuration

### Open Active Directory Users and Computers

1. Open Server Manager.
2. Select Tools.
3. Click Active Directory Users and Computers.
4. Expand the `contoso.local` domain.

### Create an Organizational Unit

1. Right-click `contoso.local`.
2. Select New → Organizational Unit.
3. Enter the OU name.
4. Click OK.
5. Repeat for the required organizational units.

### Create a Domain User

The existing domain user account:

| Parameter | Value |
|---|---|
| Name | `Client1` |
| SamAccountName | `client1` |
| User Principal Name | `client1@contoso.local` |
| Organizational Unit | `IT-Users` |
| Account Status | Enabled |

To create another domain user:

1. Open the `IT-Users` OU.
2. Right-click the empty area.
3. Select New → User.
4. Enter the user's first name and logon name.
5. Click Next.
6. Set a password.
7. Configure the required password options.
8. Click Finish.

### Manage Computer Accounts

1. Open Active Directory Users and Computers.
2. Locate the computer account.
3. Right-click the account and select Move.
4. Select the destination OU, for example `IT-Computers`.
5. Confirm the operation.

## 4. PowerShell Configuration

Run these commands on the domain controller with the Active Directory PowerShell module available.

### Verify Domain Configuration

```powershell
Get-ADDomain
Get-ADForest
```

### Display Organizational Units

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName
```

### Create an Organizational Unit

The following example creates an OU only if it does not already exist.

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

### Create a Domain User

Example of creating an additional domain user:

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

This is an example for creating an additional account. The existing `client1` account has already been created.

### Display Domain Users

```powershell
Get-ADUser -Filter * |
    Select-Object Name, SamAccountName, Enabled
```

### Display Domain Computers

```powershell
Get-ADComputer -Filter * |
    Select-Object Name, DistinguishedName
```

### Move a Computer to an OU

Example:

```powershell
Move-ADObject `
    -Identity "CN=COMPUTER-NAME,CN=Computers,DC=contoso,DC=local" `
    -TargetPath "OU=IT-Computers,DC=contoso,DC=local"
```

Replace `COMPUTER-NAME` with the actual computer account name. Check its current Distinguished Name before running this command.

## 5. Verification

The following checks are performed directly on the domain controller.

### Verify Domain Configuration

```powershell
Get-ADDomain |
    Select-Object DNSRoot, DomainMode, PDCEmulator
```

### Verify Forest Configuration

```powershell
Get-ADForest |
    Select-Object RootDomain, ForestMode
```

### Verify Organizational Units

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName
```

### Verify the Existing Client1 User

```powershell
Get-ADUser -Identity "client1" -Properties Enabled, UserPrincipalName |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled
```

### Verify Computer Accounts

```powershell
Get-ADComputer -Filter * |
    Select-Object Name, DistinguishedName
```

### Verify Domain Controller Discovery

```powershell
nltest /dsgetdc:contoso.local
```

This command checks whether the domain controller can be discovered for the domain.

## 6. Screenshots

The following screenshots document the Active Directory configuration:

| Screenshot | Description |
|---|---|
| `01-ad-domain.png` | Domain structure in Active Directory Users and Computers |
| `02-ad-organizational-units.png` | Organizational Unit structure |
| `03-ad-users.png` | Domain user accounts, including Client1 |
| `04-ad-computers.png` | Domain computer accounts |
| `05-ad-powershell.png` | PowerShell domain and OU verification |

## 7. Summary

Active Directory provides centralized identity and computer management for the lab.

The domain structure separates users, computers, servers, and groups into dedicated organizational units.

Both graphical management tools and PowerShell are used to configure and verify the environment.

Client domain-joining and Secure Channel verification will be documented separately after a new Windows client is prepared and connected to the domain.
