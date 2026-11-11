
# Get-SystemInventory.ps1
# Collects basic hardware and operating system information.

Write-Host "`n=== SYSTEM INVENTORY ===" -ForegroundColor Cyan

# 1. Get computer information
$Computer = Get-CimInstance Win32_ComputerSystem

# 2. Get operating system information
$OS = Get-CimInstance Win32_OperatingSystem

# 3. Get network information
$NetworkAdapters = Get-CimInstance Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPEnabled }

$IPv4Addresses = @(
    $NetworkAdapters |
    ForEach-Object { $_.IPAddress } |
    Where-Object {
        $_ -match '^\d{1,3}(\.\d{1,3}){3}$' -and
        $_ -notlike "169.254.*"
    }
) -join "; "

# 4. Get disk information
$Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

$DiskInfo = @(
    foreach ($Disk in $Disks) {
        [PSCustomObject]@{
            Drive     = $Disk.DeviceID
            TotalGB   = [math]::Round($Disk.Size / 1GB, 2)
            FreeGB    = [math]::Round($Disk.FreeSpace / 1GB, 2)
        }
    }
)

$DiskSummary = ($DiskInfo | ForEach-Object {
    "$($_.Drive): $($_.FreeGB) GB free / $($_.TotalGB) GB total"
}) -join "; "

# 5. Build inventory report
$Inventory = [PSCustomObject]@{
    ComputerName = $Computer.Name
    Domain       = $Computer.Domain
    Manufacturer = $Computer.Manufacturer
    Model        = $Computer.Model
    OperatingSystem = $OS.Caption
    Version      = $OS.Version
    Build        = $OS.BuildNumber
    RAM_GB       = [math]::Round($Computer.TotalPhysicalMemory / 1GB, 2)
    IPv4         = $IPv4Addresses
    Disks        = $DiskSummary
    LastBoot     = $OS.LastBootUpTime
    ReportDate   = Get-Date
}

# 6. Export report to CSV
$Desktop = [Environment]::GetFolderPath("Desktop")

$FileName = "SystemInventory_$($Computer.Name)_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

$OutputPath = Join-Path $Desktop $FileName

$Inventory | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

# 7. Display results
$Inventory | Format-List

Write-Host "`nReport saved to: $OutputPath" -ForegroundColor Green