# Group Policy Management

![Active Directory](https://img.shields.io/badge/ACTIVE_DIRECTORY-contoso.local-0969DA?style=flat-square)
![Group Policy](https://img.shields.io/badge/GROUP_POLICY-GPMC-0078D4?style=flat-square)
![Windows Server](https://img.shields.io/badge/WINDOWS_SERVER-2022-0078D4?style=flat-square)

## Overview

I use Group Policy to manage computer settings centrally in the contoso.local domain.

The GPOs are managed on DC01 through Group Policy Management Console (GPMC). They are used to organize computer configuration, manage Microsoft Defender settings, and work with Windows security auditing and Windows Update.

One of the settings I configured and verified was Microsoft Defender potentially unwanted application (PUA) protection in Block mode.

## Domain Environment

| Parameter | Value |
|---|---|
| Domain | contoso.local |
| Domain Controller | DC01 |
| DC01 IP Address | 192.168.10.10 |
| Operating System | Windows Server 2022 |
| Computer OU | IT-Computers |
| OU Distinguished Name | OU=IT-Computers,DC=contoso,DC=local |

### Existing Group Policy Objects

The following GPOs appeared in Group Policy Results on the domain-joined test computer:

| GPO Name | Purpose |
|---|---|
| Default Domain Policy | Default domain-wide settings |
| GPO-Defender Baseline | Microsoft Defender configuration |
| GPO - Security Audit | Security auditing |
| GPO - Windows Update | Windows Update management |
| IT-Computers-Policy | Computer policies for the IT-Computers OU |

The IT-Computers-Policy GPO is linked to the IT-Computers OU.

The appearance of a GPO in the applied policy list confirms that it was processed by the computer. It does not automatically confirm that every setting inside that GPO is configured as expected.

## Managing Group Policy

### Open Group Policy Management

On DC01:

1. Open Server Manager.
2. Select Tools.
3. Open Group Policy Management.
4. Expand Forest.
5. Expand Domains.
6. Select contoso.local.

The console displays the domain structure, Organizational Units, GPO links, and policy inheritance.

### View GPO Links

To check policies linked to a particular OU:

1. Expand contoso.local.
2. Select the IT-Computers OU.
3. Open the Linked Group Policy Objects tab.
4. Review the linked policies.
5. Check which policies are inherited from the parent domain.

### Create a New GPO

1. Right-click the target domain or Organizational Unit.
2. Select Create a GPO in this domain, and Link it here.
3. Enter a descriptive name.
4. Click OK.

A GPO can also be created separately under Group Policy Objects and linked to an OU later.

### Edit an Existing GPO

1. Locate the required GPO.
2. Right-click it.
3. Select Edit.
4. Open Computer Configuration or User Configuration.
5. Navigate to the required policy setting.
6. Make the necessary changes.

Computer Configuration applies to computer accounts, while User Configuration applies to user accounts.

## Microsoft Defender Baseline

I used GPO-Defender Baseline to configure potentially unwanted application (PUA) detection in Microsoft Defender Antivirus.

### Policy Location

Open GPO-Defender Baseline in Group Policy Management and navigate to:

```text
Computer Configuration
  → Policies
    → Administrative Templates
      → Windows Components
        → Microsoft Defender Antivirus
          → MpEngine
```

Open the policy:

Configure detection for potentially unwanted applications

### Configured Value

| Setting | Value |
|---|---|
| Policy State | Enabled |
| Detection Action | Block |
| PUAProtection | 1 |

This enables Defender PUA protection in Block mode.

### Check the Effective Configuration

Run on the domain-joined Windows test computer:

```powershell
Get-MpPreference |
    Select-Object PUAProtection
```

The PUAProtection property uses the following values:

| Value | Meaning |
|---|---|
| 0 | Disabled |
| 1 | Block |
| 2 | Audit |

During the lab, the setting was changed from Audit (2) to Block (1) through Group Policy and its effective value was checked on the Windows test computer.

## Security Auditing

I also created a GPO named GPO - Security Audit to work with Windows Advanced Audit Policy.

Audit policies control which security-related activities Windows records in the Security event log.

### Policy Location

Open GPO - Security Audit and navigate to:

```text
Computer Configuration
  → Policies
    → Windows Settings
      → Security Settings
        → Advanced Audit Policy Configuration
          → System Audit Policies
```

The main audit categories relevant to this lab include:

**Logon/Logoff**

- Audit Logon
- Audit Logoff
- Audit Account Lockout

**Account Management**

- Audit User Account Management
- Audit Security Group Management

These categories help monitor authentication activity, account lockouts, and changes to users and security groups.

The effective state of individual audit subcategories should be checked before assuming that every setting is enabled.

### Check Effective Audit Policy

Run on a Windows client:

```powershell
auditpol /get /category:*
```

This displays the currently effective Advanced Audit Policy configuration.

### Review Security Events

To inspect generated events:

1. Open Event Viewer.
2. Expand Windows Logs.
3. Select Security.
4. Review the recorded events.

Some useful Windows Security event IDs are:

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

Events are generated according to the effective audit configuration and the activity performed on the system.

## Windows Update Policy

A separate GPO named GPO - Windows Update is present in the lab.

Its purpose is to manage Windows Update-related computer settings.

### Policy Location

Open GPO - Windows Update and navigate to:

```text
Computer Configuration
  → Policies
    → Administrative Templates
      → Windows Components
        → Windows Update
```

The individual policy values should be reviewed in GPMC before documenting specific update behavior.

### Check Policy Application

Use Group Policy Results on the target computer to check whether this GPO appears in the applied policy list.

The presence of the GPO confirms that it was processed, but does not by itself establish which Windows Update settings are enabled.

## PowerShell Administration

I also use the Group Policy PowerShell module to inspect GPOs, check inheritance, and generate reports.

Run these commands on DC01 in an elevated PowerShell session.

### List All GPOs

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

The following example checks whether a GPO already exists before creating it.

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

This is a reusable example. It does not create or modify any of the existing lab GPOs.

### Check GPO Inheritance

```powershell
Get-GPInheritance `
    -Target "OU=IT-Computers,DC=contoso,DC=local"
```

This displays linked GPOs and inheritance information for the selected OU.

### Export GPO Reports

Create a directory for the reports:

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

The generated report can be opened in a browser to inspect the GPO configuration.

## Checking Policies on a Windows Client

The following commands are run on a domain-joined Windows test computer.

### Display Applied Computer Policies

```powershell
gpresult /r /scope computer
```

This displays the GPOs applied to the computer.

### Generate an HTML Report

```powershell
gpresult /h C:\Temp\gpresult.html /scope computer /f
```

Open the generated report in a browser to inspect the applied policies and policy details.

### Refresh Group Policy

```powershell
gpupdate /force
```

This requests a refresh of computer and user Group Policy settings.

Some changes require a restart or logoff before they take effect.

## Screenshots

The following screenshots document the Group Policy configuration and testing:

| Screenshot | Description |
|---|---|
| 40-gpo-management-console.png | Group Policy Management Console |
| 41-gpo-resultant-policy.png | Applied computer policies from gpresult |

Only include screenshots that reflect the actual lab configuration.

## Summary

I used Group Policy to manage computer settings in the contoso.local domain.

The lab includes policies for Microsoft Defender, security auditing, Windows Update, and the IT-Computers OU.

The Defender PUA setting was changed from Audit to Block mode and verified on the domain-joined Windows test computer.

I also used GPMC and PowerShell to inspect GPOs, review inheritance, and check which policies were applied.
