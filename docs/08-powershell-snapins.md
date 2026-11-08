# FOG Snapins and PowerShell Automation

![FOG Project](https://img.shields.io/badge/FOG-1.6.0-E95420?style=flat-square)
![FOG Client](https://img.shields.io/badge/FOG_Client-0.13.0-183A61?style=flat-square)
![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE?style=flat-square)
![Windows](https://img.shields.io/badge/TARGET-Windows_11-0078D4?style=flat-square)

## Overview

I used FOG Snapins to test remote PowerShell script execution on Windows clients.

The FOG Client communicates with the FOG server and processes assigned tasks. This allows scripts to run on managed computers without manually opening PowerShell on every machine.

During the lab, I tested two main use cases: creating a test file and collecting Windows system information.

## Environment

| Parameter | Value |
|---|---|
| FOG Server | FOG01 |
| FOG Server IP | 192.168.10.20 |
| FOG Version | 1.6.0 (build 5644) |
| Installation Channel | Beta |
| FOG Client Version | 0.13.0 |
| Target OS | Windows 11 Pro |
| Script Language | PowerShell |

## Configuring a Snapin

To create a Snapin in the FOG management interface:

1. Open the FOG web interface.
2. Navigate to Snapin Management.
3. Select Create New Snapin.
4. Enter a name and description.
5. Upload the PowerShell script.
6. Configure the executable and arguments.
7. Save the Snapin.

### PowerShell Execution

The following execution configuration was used:

```text
powershell.exe -ExecutionPolicy Bypass -NoProfile -File
```

| Parameter | Purpose |
|---|---|
| powershell.exe | Starts Windows PowerShell |
| -ExecutionPolicy Bypass | Bypasses execution policy for this process |
| -NoProfile | Prevents loading the user's PowerShell profile |
| -File | Executes the specified script file |

The execution policy option applies to the PowerShell process. It does not permanently change the computer's execution policy.

### Assigning a Snapin

After creating a Snapin, it must be assigned to a host.

1. Open Host Management.
2. Select the target Windows computer.
3. Open its Snapins configuration.
4. Select the required Snapin.
5. Save the host configuration.
6. Make sure the FOG Client is installed and running.
7. Wait for the client to receive and execute the task.

## Test File Snapin

The first test was a simple PowerShell script that created a directory and saved a result file on the target computer.

File name: FOG-Test.ps1

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

The script creates C:\FOG-Test if it does not already exist and writes the computer name and execution date to Result.txt.

### Checking the Result

Run on the target Windows computer:

```powershell
Test-Path "C:\FOG-Test\Result.txt"
```

To display the contents:

```powershell
Get-Content "C:\FOG-Test\Result.txt"
```

The test was successful. The result file was created on the Windows client and contained the expected information.

![Test File Snapin](https://img.shields.io/badge/RESULT-SUCCESS-238636?style=flat-square)

## Windows Inventory Snapin

The second Snapin collects basic hardware and operating system information using Windows CIM classes.

I used it to generate a local inventory report on the target computer.

File name: Windows-Inventory.ps1

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

The report is saved locally as C:\FOG-Inventory.txt.

### Checking the Report

Check whether the file exists:

```powershell
Test-Path "C:\FOG-Inventory.txt"
```

Display the report:

```powershell
Get-Content "C:\FOG-Inventory.txt"
```

The inventory Snapin executed successfully and generated the report on the Windows client.

![Inventory Snapin](https://img.shields.io/badge/RESULT-SUCCESS-238636?style=flat-square)

## Software Deployment Experiment

I also tested the use of FOG Snapins for software deployment.

The experiment verified that a Snapin could execute a PowerShell script and create a local test file. However, it did not install an actual application.

| Test | Result |
|---|---|
| PowerShell script execution | Successful |
| Test file creation | Successful |
| Actual application installation | Not demonstrated |

This was a test of Snapin execution, not a completed software deployment.

## Troubleshooting

### FOG Hostname Changer

I attempted to change a Windows computer name using the FOG Hostname Changer.

The operation did not complete successfully. The FOG log displayed:

```text
Users still logged in and enforce is disabled, delaying any further actions
```

The hostname change was delayed because users were still logged in and the enforcement setting was disabled.

I did not consider this operation successfully implemented.

### Manual Domain Joining

For domain joining, I used PowerShell separately instead of an automated FOG Snapin.

The following example joins a Windows client to contoso.local and places its computer account in the IT-Computers OU.

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

The command requires valid domain credentials and connectivity to DC01.

It is a manual administration procedure, separate from FOG Snapin execution.

## Screenshots

The following screenshots document the Snapin configuration and tests.

| Screenshot | Description |
|---|---|
| 37-fog-inventory-task.png | FOG Inventory Snapin task running on the Windows client |
| 38-fog-inventory-success.png | Successful completion of the Inventory Snapin task |
| 39-fog-inventory-report.png | PowerShell output displaying the generated inventory report using Get-Content |

Only include screenshots that actually exist and reflect the corresponding tests.

## Summary

I used FOG Snapins to execute PowerShell scripts on Windows clients.

Two working examples were demonstrated: creating a test file remotely and collecting basic Windows inventory information.

I also investigated automatic hostname changes through the FOG Client and documented the issue encountered during testing.

Domain joining remained a separate manual procedure using PowerShell.
