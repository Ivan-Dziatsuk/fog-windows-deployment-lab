# FOG Snapins and PowerShell Automation

## 1. Overview

FOG Snapins provide a way to execute scripts and deploy files or applications to managed Windows computers.

In this lab, PowerShell scripts are used to test remote task execution and collect basic Windows system information.

The FOG Client communicates with the FOG server and processes assigned Snapin tasks on the target computer.

### Environment Information

| Parameter | Value |
|---|---|
| FOG Server | FOG01 |
| FOG Server IP | 192.168.10.20 |
| FOG Project Version | 1.6.0 (build 5644) |
| Installation Channel | Beta |
| FOG Client Version | 0.13.0 |
| Target OS | Windows 11 Pro |
| Script Language | PowerShell |

## 2. FOG Snapin Configuration

### Create a Snapin

1. Open the FOG web management interface.
2. Navigate to Snapin Management.
3. Select Create New Snapin.
4. Enter a Snapin name.
5. Add a description.
6. Select the PowerShell script file.
7. Configure the executable and arguments.
8. Save the Snapin.

### PowerShell Execution Settings

The following execution configuration was used:

```text
powershell.exe -ExecutionPolicy Bypass -NoProfile -File
```

| Parameter | Purpose |
|---|---|
| `powershell.exe` | Starts Windows PowerShell |
| `-ExecutionPolicy Bypass` | Bypasses the execution policy for this process |
| `-NoProfile` | Prevents loading the user's PowerShell profile |
| `-File` | Executes the specified script file |

`-ExecutionPolicy Bypass` applies to this PowerShell process. It does not permanently change the system execution policy.

### Assign a Snapin to a Host

1. Open Host Management.
2. Select the target Windows computer.
3. Open its Snapins configuration.
4. Select the required Snapin.
5. Save the host configuration.
6. Make sure the FOG Client is installed and running on the target computer.
7. Wait for the client to receive and execute the task.

## 3. Test File Snapin

The first successful test verified that FOG could execute a PowerShell script on a Windows client.

### Script

File name:

`FOG-Test.ps1`

```powershell
$Path = "C:\FOG-Test"

New-Item -Path $Path -ItemType Directory -Force |
    Out-Null

@"
FOG TASK SUCCESS
Computer: $env:COMPUTERNAME
Date: $(Get-Date)
"@ | Out-File "$Path\Result.txt" -Encoding UTF8
```

### Script Explanation

- `$Path` stores the destination directory.
- `New-Item` creates the directory if it does not exist.
- `-Force` allows the command to reuse an existing directory.
- `Out-Null` suppresses unnecessary command output.
- `Out-File` writes the result to a text file.
- `$env:COMPUTERNAME` records the computer name.
- `Get-Date` records the execution date and time.

### Verification

Run on the target Windows computer:

```powershell
Test-Path "C:\FOG-Test\Result.txt"
```

Display the file contents:

```powershell
Get-Content "C:\FOG-Test\Result.txt"
```

Expected result: the file exists and contains the success message, computer name, and execution date.

**Lab result: Successful.**

## 4. Windows Inventory Snapin

The Windows Inventory Snapin collects basic system information using PowerShell and Windows CIM classes.

The resulting report is saved locally on the target computer.

### Script

File name:

`Windows-Inventory.ps1`

```powershell
$Computer = Get-CimInstance Win32_ComputerSystem
$OS = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor |
    Select-Object -First 1

$Network = Get-CimInstance Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPEnabled }

$Disks = Get-CimInstance Win32_LogicalDisk `
    -Filter "DriveType=3"

$Report = [PSCustomObject]@{
    ComputerName = $Computer.Name
    Domain       = $Computer.Domain
    Manufacturer = $Computer.Manufacturer
    Model        = $Computer.Model
    CPU          = $CPU.Name
    RAM_GB       = [math]::Round(
        $Computer.TotalPhysicalMemory / 1GB, 1
    )
    Windows      = $OS.Caption
    WindowsBuild = $OS.BuildNumber
    IPAddress    = (
        $Network.IPAddress |
        Where-Object { $_ -match '^\d+\.' }
    ) -join ', '
    Disks        = ($Disks.DeviceID -join ', ')
    FreeSpaceGB  = (
        $Disks | ForEach-Object {
            "$($_.DeviceID): $([math]::Round($_.FreeSpace / 1GB, 1)) GB free"
        }
    ) -join '; '
}

$Report | Format-List |
    Out-File "C:\FOG-Inventory.txt"
```

### Information Collected

| Information | CIM Class / Property |
|---|---|
| Computer name | Win32_ComputerSystem.Name |
| Domain or workgroup | Win32_ComputerSystem.Domain |
| Manufacturer | Win32_ComputerSystem.Manufacturer |
| Model | Win32_ComputerSystem.Model |
| CPU | Win32_Processor.Name |
| Installed RAM | Win32_ComputerSystem.TotalPhysicalMemory |
| Windows version | Win32_OperatingSystem.Caption |
| Windows build | Win32_OperatingSystem.BuildNumber |
| IP addresses | Win32_NetworkAdapterConfiguration.IPAddress |
| Disk information | Win32_LogicalDisk |

### Verification

Check whether the report exists:

```powershell
Test-Path "C:\FOG-Inventory.txt"
```

Display the inventory report:

```powershell
Get-Content "C:\FOG-Inventory.txt"
```

**Lab result: Successful.** The inventory report was generated on the Windows client.

## 5. Software Deployment Test

A separate experiment was performed to test the use of FOG Snapins for software deployment.

The test script created a local test file.

This verified that a Snapin could execute a PowerShell script, but it did not install an actual application.

### Lab Result

| Test | Result |
|---|---|
| PowerShell script execution | Successful |
| Test file creation | Successful |
| Actual software installation | Not demonstrated |

This experiment is not considered a successful software installation deployment.

## 6. Troubleshooting

### FOG Hostname Changer

An attempt was made to change a Windows computer name using the FOG Hostname Changer.

The operation did not complete successfully.

The FOG log displayed the following message:

```text
Users still logged in and enforce is disabled, delaying any further actions
```

This indicated that the hostname change was being delayed because users were still logged in and the enforcement setting was disabled.

The hostname change is not considered successfully implemented in this lab.

### Manual Domain Joining

Domain joining is performed manually using PowerShell rather than through an automated FOG Snapin.

Example:

```powershell
$Credential = Get-Credential `
    -UserName "contoso\Administrator" `
    -Message "Enter domain credentials"

Add-Computer `
    -DomainName "contoso.local" `
    -OUPath "OU=IT-Computers,DC=contoso,DC=local" `
    -Credential $Credential `
    -Restart
```

This command requires valid domain credentials and a reachable domain controller.

It is a manual administration procedure, not an automatically executed FOG Snapin.

## 7. Screenshots

The following screenshots document the FOG Snapin experiments:

| Screenshot | Description |
|---|---|
| `37-fog-snapin-management.png` | FOG Snapin Management interface |
| `38-fog-test-snapin.png` | Test File Snapin configuration |
| `39-fog-test-snapin-result.png` | Successful test file on Windows client |
| `40-fog-inventory-snapin.png` | Windows Inventory Snapin configuration |
| `41-fog-inventory-report.png` | Generated Windows inventory report |
| `42-fog-software-deployment-test.png` | Software Deployment Test result |
| `43-fog-hostname-changer-log.png` | Hostname Changer troubleshooting message |

Only include screenshots that actually exist. Do not create screenshots to represent tests that were not performed.

## 8. Summary

FOG Snapins were used to execute PowerShell scripts on Windows clients.

Two successful use cases were demonstrated:

- Creating a test file remotely through a Snapin.
- Collecting basic Windows system information and generating an inventory report.

The automatic hostname change experiment was unsuccessful and is documented as a troubleshooting example.

Domain joining remains a separate manual procedure using PowerShell.
