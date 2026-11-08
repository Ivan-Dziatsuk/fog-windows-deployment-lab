# SMB File Server Configuration

![SMB](https://img.shields.io/badge/FILE_SHARING-SMB-0078D4?style=flat-square)
![NTFS](https://img.shields.io/badge/PERMISSIONS-NTFS-0969DA?style=flat-square)
![Active Directory](https://img.shields.io/badge/ACCESS_CONTROL-Active_Directory-238636?style=flat-square)
![Windows Server](https://img.shields.io/badge/SERVER-DC01-0078D4?style=flat-square)

## Overview

I configured an SMB file share on DC01 to practice managing access to shared folders through Active Directory security groups.

The share contains three separate folders: Public, Helpdesk, and Admin. Each folder has its own NTFS permissions, so access can be controlled according to the user's group membership.

During this part of the lab, I also worked with share permissions, NTFS ACLs, inheritance, and Effective Access.

## File Server Configuration

| Parameter | Value |
|---|---|
| File Server | DC01 |
| Operating System | Windows Server 2022 |
| Server IP | 192.168.10.10 |
| Shared Folder | C:\Shares\IT-Share |
| Share Name | IT-Share |
| UNC Path | \\DC01\IT-Share |

The shared directory has the following structure:

```text
C:\Shares\IT-Share
│
├── Public
│
├── Helpdesk
│
└── Admin
```

## Share Permissions

Share permissions control access when users connect to a folder over the network.

I configured the following permissions for the IT-Share share:

| Security Principal | Share Permission |
|---|---|
| Employees | Change |
| Helpdesk | Change |
| IT-Admins | Full Control |
| Domain Admins | Full Control |

### Managing Share Permissions Through GUI

1. Open Server Manager on DC01.
2. Select File and Storage Services.
3. Open Shares.
4. Locate IT-Share.
5. Right-click the share and select Properties.
6. Open the Permissions section.
7. Select Customize permissions.
8. Open the Share tab.
9. Review or configure the required groups.
10. Apply the changes.

### Permission Levels

| Permission | What It Allows |
|---|---|
| Read | View files and folders |
| Change | Read, create, modify, and delete files |
| Full Control | Includes Change permissions and additional access rights |

Share permissions apply to network connections. They do not replace NTFS permissions configured on the filesystem.

## NTFS Permissions

NTFS permissions control access directly on files and folders. They apply both to local access and to access through an SMB share.

For this lab, I separated access between the three folders according to department groups.

### Configured Permissions

| Folder | Security Group | NTFS Permission |
|---|---|---|
| Public | Employees | Modify |
| Helpdesk | Helpdesk | Modify |
| Admin | IT-Admins | Full Control |

### Managing NTFS Permissions Through GUI

1. Open File Explorer on DC01.
2. Navigate to C:\Shares\IT-Share.
3. Right-click the required folder.
4. Select Properties.
5. Open the Security tab.
6. Select Advanced.
7. Review the existing permission entries.
8. Add or modify the required security group.
9. Select the appropriate permission level.
10. Apply the changes.

I repeated this process for Public, Helpdesk, and Admin.

### Permission Inheritance

Windows can inherit NTFS permissions from parent folders. This means that permissions configured on a parent directory may also apply to its files and subfolders.

Inheritance can be managed through:

Folder Properties → Security → Advanced

It is important to check inherited and explicit permissions before changing an ACL. Adding a new Allow entry does not automatically remove other permissions.

## PowerShell Configuration

I also used PowerShell to create the directory structure, configure the SMB share, and manage NTFS permissions.

Run these commands on DC01 in an elevated PowerShell session.

### Create the Folder Structure

```powershell
$BasePath = "C:\Shares\IT-Share"

New-Item -Path $BasePath -ItemType Directory -Force |
    Out-Null

$Folders = @(
    "$BasePath\Public",
    "$BasePath\Helpdesk",
    "$BasePath\Admin"
)

foreach ($Folder in $Folders) {
    New-Item -Path $Folder -ItemType Directory -Force |
        Out-Null
}
```

The -Force parameter allows the script to reuse existing directories without failing when they are already present.

### Create the SMB Share

The following is an example for creating the share with the configured access groups.

```powershell
New-SmbShare `
    -Name "IT-Share" `
    -Path "C:\Shares\IT-Share" `
    -ChangeAccess "CONTOSO\Employees", "CONTOSO\Helpdesk" `
    -FullAccess "CONTOSO\IT-Admins", "CONTOSO\Domain Admins"
```

This command creates a new SMB share. Do not run it if IT-Share already exists.

### Display Existing Shares

```powershell
Get-SmbShare |
    Select-Object Name, Path, Description
```

### Display Share Permissions

```powershell
Get-SmbShareAccess -Name "IT-Share"
```

## Configuring NTFS Permissions with icacls

The icacls utility can be used to modify and inspect NTFS Access Control Lists.

The following commands add the required group permissions to the existing folders.

```powershell
# Employees: Modify access to Public
icacls "C:\Shares\IT-Share\Public" `
    /grant "CONTOSO\Employees:(OI)(CI)M"

# Helpdesk: Modify access to Helpdesk
icacls "C:\Shares\IT-Share\Helpdesk" `
    /grant "CONTOSO\Helpdesk:(OI)(CI)M"

# IT-Admins: Full Control over Admin
icacls "C:\Shares\IT-Share\Admin" `
    /grant "CONTOSO\IT-Admins:(OI)(CI)F"
```

### Understanding the icacls Parameters

| Parameter | Meaning |
|---|---|
| /grant | Adds an Allow permission |
| (OI) | Object Inherit — applies to files |
| (CI) | Container Inherit — applies to subfolders |
| M | Modify |
| F | Full Control |

These commands add permissions; they do not remove other existing Allow or Deny entries. Always inspect the resulting ACL before assuming that the listed groups are the only entries.

### Display NTFS Permissions

```powershell
icacls "C:\Shares\IT-Share\Public"
icacls "C:\Shares\IT-Share\Helpdesk"
icacls "C:\Shares\IT-Share\Admin"
```

## Testing the Share

After configuring the share and folder permissions, access can be tested from a Windows client.

### Verify the SMB Share

Run on DC01:

```powershell
Get-SmbShare -Name "IT-Share" |
    Select-Object Name, Path, Description
```

### Verify Share Access Rules

```powershell
Get-SmbShareAccess -Name "IT-Share"
```

### Verify NTFS ACLs

```powershell
icacls "C:\Shares\IT-Share"
icacls "C:\Shares\IT-Share\Public"
icacls "C:\Shares\IT-Share\Helpdesk"
icacls "C:\Shares\IT-Share\Admin"
```

### Access the Share from a Windows Client

Open File Explorer and enter:

```text
\\DC01\IT-Share
```

The same location can be checked through PowerShell:

```powershell
Test-Path "\\DC01\IT-Share"
```

To list the shared folders:

```powershell
Get-ChildItem "\\DC01\IT-Share"
```

These commands use the current Windows security context. A failed access test may indicate a permissions problem, a missing path, or a network connectivity issue.

### Map the Share as a Network Drive

I can also connect to the share using a persistent PowerShell drive:

```powershell
New-PSDrive `
    -Name "IT" `
    -PSProvider FileSystem `
    -Root "\\DC01\IT-Share" `
    -Persist
```

The share then becomes available as the IT: drive in File Explorer.

## Effective Access and Troubleshooting

When a user accesses an SMB share over the network, Windows evaluates both Share Permissions and NTFS Permissions.

The effective network access is limited by the more restrictive result of these two permission layers.

For example:

| Permission Layer | Permission |
|---|---|
| Share | Change |
| NTFS | Modify |
| Effective Access | Modify-level file access |

An Allow entry in one layer cannot override a restriction imposed by the other layer.

### What Can Affect Effective Access?

- Active Directory group membership.
- Inherited NTFS permissions.
- Explicit Allow and Deny entries.
- SMB Share Permissions.
- The user's current Windows logon token.

When a user is added to a security group, they may need to sign out and sign in again before their new group membership is reflected in the logon token.

### Check Effective Access Through GUI

1. Open the folder Properties.
2. Select the Security tab.
3. Open Advanced.
4. Select Effective Access.
5. Choose the required user or group.
6. Click View effective access.
7. Review the resulting permissions.

This helps identify why a user can or cannot access a particular folder.

## Screenshots

The following screenshots document the SMB configuration and permission management.

| Screenshot | Description |
|---|---|
| 42-smb-share-permissions.png | Share permissions |
| 43-smb-ntfs-permissions.png | NTFS security permissions configuration |

Only include screenshots that show the actual configuration and tests performed.

## Summary

I configured an SMB share on DC01 using C:\Shares\IT-Share.

The share contains separate folders for Public, Helpdesk, and Admin. Access is managed through Active Directory groups, SMB Share Permissions, and NTFS permissions.

I also practiced permission inheritance, ACL inspection with icacls, and Effective Access troubleshooting.

This setup provides a practical example of managing shared resources and controlling access in a Windows domain environment.
