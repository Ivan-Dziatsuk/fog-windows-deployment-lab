# SMB File Server Configuration

## 1. Overview

SMB (Server Message Block) is a network file-sharing protocol used to provide access to shared folders and files.

In this lab, Windows Server 2022 (`DC01`) is configured as a file server.

The shared folder is used to demonstrate centralized file access management through:

- SMB Share Permissions
- NTFS Permissions
- Active Directory security groups
- Permission inheritance
- Effective Access verification

## 2. File Server Information

| Parameter | Value |
|---|---|
| File Server | `DC01` |
| Operating System | Windows Server 2022 |
| Server IP | `192.168.10.10` |
| Shared Folder | `C:\Shares\IT-Share` |
| Share Name | `IT-Share` |
| UNC Path | `\\DC01\IT-Share` |

### Folder Structure

The shared directory contains three subfolders:

```text id="smbtree"
C:\Shares\IT-Share
│
├── Public
│
├── Helpdesk
│
└── Admin
```

Each folder has a separate access configuration.

## 3. Share Permissions

Share Permissions control access when users connect to a folder through the network.

The following permissions are configured for the `IT-Share` SMB share:

| Security Principal | Share Permission |
|---|---|
| Employees | Change |
| Helpdesk | Change |
| IT-Admins | Full Control |
| Domain Admins | Full Control |

### Configure Share Permissions Using GUI

1. Open Server Manager.
2. Select File and Storage Services.
3. Select Shares.
4. Locate `IT-Share`.
5. Right-click the share and select Properties.
6. Open the Permissions section.
7. Select Customize permissions.
8. Open the Share tab.
9. Review or configure the required groups and permissions.
10. Apply the changes.

### Share Permission Levels

| Permission | Description |
|---|---|
| Read | View files and folders |
| Change | Read, create, modify, and delete files |
| Full Control | Includes Read and Change permissions and allows management of share permissions |

Share Permissions apply to network access through the SMB share. They do not replace NTFS permissions.

## 4. NTFS Permissions

NTFS permissions control access to files and folders on the filesystem.

Unlike Share Permissions, NTFS permissions also apply to local access.

The lab uses separate access permissions for each subfolder.

### Configured NTFS Permissions

| Folder | Security Principal | NTFS Permission |
|---|---|---|
| Public | Employees | Modify |
| Helpdesk | Helpdesk | Modify |
| Admin | IT-Admins | Full Control |

These permissions demonstrate how access can be separated according to department responsibilities.

### Configure NTFS Permissions Using GUI

1. Open File Explorer on `DC01`.
2. Navigate to `C:\Shares\IT-Share`.
3. Right-click the required folder.
4. Select Properties.
5. Open the Security tab.
6. Select Advanced for detailed permission management.
7. Review the existing permission entries.
8. Add or modify the required security group.
9. Select the appropriate permission level.
10. Apply the changes.

Repeat this process for the `Public`, `Helpdesk`, and `Admin` folders.

### Permission Inheritance

NTFS supports permission inheritance.

Permissions configured on a parent folder can be inherited by its child files and folders.

Inheritance can be reviewed and managed through:

`Folder Properties → Security → Advanced`

The actual inherited and explicit permission entries should be checked before modifying them.

**Important:** The permissions listed above describe the configured group entries. Other inherited permissions, group memberships, and explicit Deny entries can also affect a user's effective access.

## 5. PowerShell Configuration

Run these commands on `DC01` using an elevated PowerShell session.

### Create the Shared Folder Structure

The following commands create the directory structure if it does not already exist.

```powershell id="smbfolders"
$BasePath = "C:\Shares\IT-Share"

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

### Create an SMB Share

Example configuration for a new share:

```powershell id="smbcreate"
New-SmbShare `
    -Name "IT-Share" `
    -Path "C:\Shares\IT-Share" `
    -ChangeAccess "CONTOSO\Employees", "CONTOSO\Helpdesk" `
    -FullAccess "CONTOSO\IT-Admins", "CONTOSO\Domain Admins"
```

This command creates a new share. Do not run it if `IT-Share` already exists.

### Display SMB Shares

```powershell id="smbdisplay"
Get-SmbShare |
    Select-Object Name, Path, Description
```

### Display Share Permissions

```powershell id="smbaccess"
Get-SmbShareAccess -Name "IT-Share"
```

### Configure NTFS Permissions

The following commands add the specified permissions to the existing folders.

```powershell id="smbacl"
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

Explanation:

| Parameter | Meaning |
|---|---|
| `/grant` | Adds an Allow permission |
| `(OI)` | Object Inherit — applies to files |
| `(CI)` | Container Inherit — applies to subfolders |
| `M` | Modify |
| `F` | Full Control |

These commands add permissions; they do not remove other existing Allow or Deny entries. Review the resulting ACL before assuming these are the only permissions.

### Display NTFS Permissions

```powershell id="smbshowacl"
icacls "C:\Shares\IT-Share\Public"
icacls "C:\Shares\IT-Share\Helpdesk"
icacls "C:\Shares\IT-Share\Admin"
```

## 6. Verification

### Verify the SMB Share

```powershell id="smbverify"
Get-SmbShare -Name "IT-Share" |
    Select-Object Name, Path, Description
```

### Verify Share Permissions

```powershell id="smbverifyaccess"
Get-SmbShareAccess -Name "IT-Share"
```

### Verify NTFS Permissions

```powershell id="smbverifyacl"
icacls "C:\Shares\IT-Share"
icacls "C:\Shares\IT-Share\Public"
icacls "C:\Shares\IT-Share\Helpdesk"
icacls "C:\Shares\IT-Share\Admin"
```

### Test Network Access

From a Windows client, use:

```powershell id="smbtest"
Test-Path "\\DC01\IT-Share"
```

Display the shared folder contents:

```powershell id="smbcontents"
Get-ChildItem "\\DC01\IT-Share"
```

These commands test access using the current Windows security context. A failed `Test-Path` does not by itself distinguish between a missing path and an access or connectivity problem.

### Connect to the Share

Open File Explorer and enter:

```text id="smbunc"
\\DC01\IT-Share
```

Alternatively, map the shared folder to a network drive:

```powershell id="smbmap"
New-PSDrive `
    -Name "IT" `
    -PSProvider FileSystem `
    -Root "\\DC01\IT-Share" `
    -Persist
```

## 7. Effective Access and Troubleshooting

Windows evaluates both Share Permissions and NTFS Permissions when a user accesses a folder through an SMB share.

The effective network access is limited by the permissions granted at both layers.

For example:

- Share permission: Change
- NTFS permission: Modify
- Effective access: Modify-level file access, limited by both permission layers.

An Allow permission at one layer cannot override a restriction imposed by the other layer.

### Factors Affecting Effective Access

- Active Directory group membership.
- Inherited NTFS permissions.
- Explicit Allow and Deny entries.
- Share-level permissions.
- The user's current Windows logon security token.

A user who has recently been added to a security group may need to sign out and sign in again to refresh the group membership in the logon token.

### Verify Effective Access Using GUI

1. Open the folder Properties.
2. Select the Security tab.
3. Open Advanced.
4. Select Effective Access.
5. Select a user or group.
6. Click View effective access.
7. Review the resulting permissions.

### Important Troubleshooting Checks

When a user cannot access a shared folder, check:

1. Whether the user belongs to the correct Active Directory security group.
2. Whether the SMB share permissions allow access.
3. Whether NTFS permissions allow access.
4. Whether inheritance or explicit Deny permissions affect access.
5. Whether the user has refreshed their logon session after group membership changes.

## 8. Screenshots

The following screenshots document the SMB file server configuration:

| Screenshot | Description |
|---|---|
| `51-smb-folder-structure.png` | IT-Share folder structure |
| `52-smb-share-properties.png` | SMB share properties |
| `53-smb-share-permissions.png` | Share permissions |
| `54-smb-public-ntfs.png` | Public folder NTFS permissions |
| `55-smb-helpdesk-ntfs.png` | Helpdesk folder NTFS permissions |
| `56-smb-admin-ntfs.png` | Admin folder NTFS permissions |
| `57-smb-powershell-acl.png` | PowerShell ACL verification |
| `58-smb-effective-access.png` | Effective Access configuration |
| `59-smb-client-access.png` | Shared folder access from a Windows client |

Only include screenshots that reflect the actual configuration and tests performed.

## 9. Summary

An SMB file share was configured on Windows Server 2022 using the path `C:\Shares\IT-Share`.

The share contains separate folders for Public, Helpdesk, and Admin access.

Share Permissions and NTFS Permissions were configured to demonstrate layered access control.

PowerShell and graphical administration tools were used to manage and verify the file server configuration.
