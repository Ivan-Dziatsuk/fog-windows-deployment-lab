# Group Policy Management

## 1. Overview

Group Policy is a Windows feature used to centrally manage user and computer settings in an Active Directory environment.

In this lab, Group Policy is used to manage Windows security settings, audit policies, and computer configuration.

Group Policy Objects (GPOs) are managed through Group Policy Management Console (GPMC) and can be linked to domains or Organizational Units.

The domain controller is `DC01`, running Windows Server 2022.

## 2. Group Policy Environment

### Domain Information

| Parameter | Value |
|---|---|
| Domain | `contoso.local` |
| Domain Controller | `DC01` |
| Domain Controller IP | `192.168.10.10` |
| Computer OU | `IT-Computers` |
| Computer OU DN | `OU=IT-Computers,DC=contoso,DC=local` |

### Existing Group Policy Objects

The following GPOs were observed in the Group Policy Results output on the domain-joined test computer:

| GPO Name | Purpose |
|---|---|
| Default Domain Policy | Default domain-wide settings |
| GPO-Defender Baseline | Microsoft Defender configuration |
| GPO - Security Audit | Advanced security auditing |
| GPO - Windows Update | Windows Update management |
| IT-Computers-Policy | Computer policies for the IT-Computers OU |

The exact settings of each GPO should be verified in Group Policy Management before making changes.

## 3. GUI Configuration

### Open Group Policy Management

1. Open Server Manager on `DC01`.
2. Select Tools.
3. Click Group Policy Management.
4. Expand Forest.
5. Expand Domains.
6. Expand `contoso.local`.

The console displays the domain structure, Organizational Units, and linked Group Policy Objects.

### View GPO Links

1. Expand `contoso.local`.
2. Select the `IT-Computers` OU.
3. Open the Linked Group Policy Objects tab.
4. Review the linked policies.
5. Check which GPOs are inherited from the parent domain.

The `IT-Computers-Policy` GPO is linked to the `IT-Computers` OU.

### Create a New GPO

1. Right-click the target domain or Organizational Unit.
2. Select Create a GPO in this domain, and Link it here.
3. Enter a descriptive GPO name.
4. Click OK.

A new GPO can also be created separately in Group Policy Objects and linked later.

### Edit a GPO

1. Locate the required GPO.
2. Right-click it.
3. Select Edit.
4. Navigate through Computer Configuration or User Configuration.
5. Configure the required policy settings.
6. Close the editor.

Computer Configuration applies to computer accounts, while User Configuration applies to user accounts.

## 4. GPO-Defender Baseline

This GPO contains a Microsoft Defender Antivirus setting for potentially unwanted applications (PUA).

### Configuration Path

Open Group Policy Management and edit:

`GPO-Defender Baseline`

Navigate to:

```text
Computer Configuration
  → Policies
    → Administrative Templates
      → Windows Components
        → Microsoft Defender Antivirus
          → MpEngine
```

Open:

`Configure detection for potentially unwanted applications`

### Configured Setting

| Parameter | Value |
|---|---|
| Policy | Configure detection for potentially unwanted applications |
| State | Enabled |
| Detection Action | Block |

This configuration enables Microsoft Defender PUA protection in Block mode.

### Verify Defender Configuration

Run on the domain-joined Windows test computer:

```powershell
Get-MpPreference |
    Select-Object PUAProtection
```

Expected value:

| Value | Meaning |
|---|---|
| 0 | Disabled |
| 1 | Block |
| 2 | Audit |

The observed configuration changed from Audit (`2`) to Block (`1`).

## 5. GPO - Security Audit

This GPO is used to manage Windows Advanced Audit Policy settings.

Audit policies allow Windows to record security-related events in the Security event log.

### Configuration Path

Edit:

`GPO - Security Audit`

Navigate to:

```text
Computer Configuration
  → Policies
    → Windows Settings
      → Security Settings
        → Advanced Audit Policy Configuration
          → System Audit Policies
```

The following policy areas were used during configuration:

### Logon/Logoff

Relevant audit settings:

- Audit Logon
- Audit Logoff
- Audit Account Lockout

These settings help monitor authentication activity and account lockout events.

### Account Management

Relevant audit settings:

- Audit User Account Management
- Audit Security Group Management

These settings help monitor changes to user accounts and security groups.

The effective state of each audit subcategory should be checked on the target computer before claiming that every setting is enabled.

### Verify Audit Policy

Run on the Windows test computer:

```powershell
auditpol /get /category:*
```

This displays the effective Advanced Audit Policy configuration.

### Review Security Events

1. Open Event Viewer.
2. Expand Windows Logs.
3. Select Security.
4. Review authentication and account management events.

Useful event IDs include:

| Event ID | Description |
|---|---|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4634 | Account logged off |
| 4647 | User initiated logoff |
| 4740 | User account locked out |
| 4720 | User account created |
| 4726 | User account deleted |
| 4728 | Member added to a global security group |
| 4732 | Member added to a local security group |

Event generation depends on the effective audit policy and the activity performed.

## 6. GPO - Windows Update

This GPO is used for Windows Update-related computer settings.

### Configuration Path

Edit:

`GPO - Windows Update`

Navigate to:

```text
Computer Configuration
  → Policies
    → Administrative Templates
      → Windows Components
        → Windows Update
```

Review the available policy settings and their current states.

The exact Windows Update policy values should be documented after checking the GPO in Group Policy Management.

### Verify the GPO

Use Group Policy Results to check whether the GPO is applied to the target computer.

The presence of a GPO in the applied policy list confirms that it was processed, but does not by itself prove a specific Windows Update setting is active.

## 7. PowerShell Configuration and Management

Run these commands on `DC01` using an elevated PowerShell session with the Group Policy module available.

### Display All GPOs

```powershell
Get-GPO -All |
    Select-Object DisplayName, GpoStatus, Id
```

### Display a Specific GPO

```powershell
Get-GPO -Name "GPO-Defender Baseline" |
    Format-List DisplayName, Id, GpoStatus,
        CreationTime, ModificationTime
```

### Create a New GPO

Example of creating a new GPO only if it does not already exist:

```powershell
$GpoName = "GPO-Example"

$ExistingGPO = Get-GPO `
    -Name $GpoName `
    -ErrorAction SilentlyContinue

if (-not $ExistingGPO) {
    New-GPO -Name $GpoName
}
else {
    Write-Host "GPO already exists: $GpoName"
}
```

This is a reusable example and does not create or modify any of the existing lab GPOs.

### Check GPO Inheritance

```powershell
Get-GPInheritance `
    -Target "OU=IT-Computers,DC=contoso,DC=local"
```

This displays linked GPOs and inheritance information for the selected OU.

### Export GPO Reports

Create a directory for reports:

```powershell
New-Item `
    -Path "C:\Temp" `
    -ItemType Directory `
    -Force
```

Export an HTML report containing all GPOs:

```powershell
Get-GPOReport `
    -All `
    -ReportType Html `
    -Path "C:\Temp\GPO-Report.html"
```

The report can be opened in a web browser for further inspection.

## 8. Verification on a Windows Client

These commands are run on a domain-joined Windows test computer.

### Check Computer Policy Results

```powershell
gpresult /r /scope computer
```

This displays the computer policies applied to the machine.

### Generate an HTML Group Policy Report

```powershell
gpresult /h C:\Temp\gpresult.html /scope computer /f
```

Open the resulting HTML file in a browser to inspect applied policies and policy details.

### Update Group Policy

```powershell
gpupdate /force
```

This requests a refresh of both computer and user Group Policy settings.

Some policy changes may require a restart or logoff before they take effect.

## 9. Screenshots

The following screenshots document Group Policy configuration and verification:

| Screenshot | Description |
|---|---|
| `44-gpo-management-console.png` | Group Policy Management Console |
| `45-gpo-organizational-unit-links.png` | GPO links on the IT-Computers OU |
| `46-gpo-defender-baseline.png` | Microsoft Defender PUA policy |
| `47-gpo-security-audit.png` | Advanced Audit Policy configuration |
| `48-gpo-windows-update.png` | Windows Update GPO |
| `49-gpo-powershell-list.png` | GPO inventory through PowerShell |
| `50-gpo-resultant-policy.png` | Applied computer policies from gpresult |

Only include screenshots that reflect the actual configuration.

## 10. Summary

Group Policy provides centralized management of Windows computer settings in the `contoso.local` domain.

The lab includes policies for Microsoft Defender, security auditing, Windows Update, and computer configuration.

GPOs are managed through Group Policy Management Console and PowerShell. Their application is verified using `gpresult`, while individual security settings are checked directly on the target computer.
