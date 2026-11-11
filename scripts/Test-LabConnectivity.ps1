
# Test-LabConnectivity.ps1
# Checks connectivity and essential services in the lab environment.

$Domain   = "contoso.local"
$DCName   = "DC01"
$DCIP     = "192.168.10.10"
$FOGName  = "FOG01"
$FOGIP    = "192.168.10.20"
$DnsServer = $DCIP

$Results = @()

function Add-Result {
    param (
        [string]$Check,
        [string]$Target,
        [bool]$Success,
        [string]$Details
    )

    $Status = if ($Success) { "PASS" } else { "FAIL" }

    $script:Results += [PSCustomObject]@{
        Status  = $Status
        Check   = $Check
        Target  = $Target
        Details = $Details
    }
}

Write-Host "`n=== LAB CONNECTIVITY CHECK ===" -ForegroundColor Cyan

# 1. Check DNS resolution
foreach ($Server in @(
    @{ Name = "$DCName.$Domain"; ExpectedIP = $DCIP },
    @{ Name = "$FOGName.$Domain"; ExpectedIP = $FOGIP }
)) {
    try {
        $Record = Resolve-DnsName -Name $Server.Name `
            -Server $DnsServer -Type A -ErrorAction Stop |
            Where-Object { $_.Type -eq "A" } |
            Select-Object -First 1

        $CorrectIP = $Record.IPAddress -eq $Server.ExpectedIP

        Add-Result "DNS" $Server.Name $CorrectIP `
            "Resolved IP: $($Record.IPAddress); expected: $($Server.ExpectedIP)"
    }
    catch {
        Add-Result "DNS" $Server.Name $false $_.Exception.Message
    }
}

# 2. Check essential DC01 TCP ports
foreach ($Port in @(53, 88, 389, 445)) {
    $Test = Test-NetConnection -ComputerName $DCIP `
        -Port $Port -WarningAction SilentlyContinue

    Add-Result "TCP port" "$DCName : $Port" `
        $Test.TcpTestSucceeded "TCP connectivity"
}

# 3. Check FOG web interface
$FogTest = Test-NetConnection -ComputerName $FOGIP `
    -Port 80 -WarningAction SilentlyContinue

Add-Result "TCP port" "$FOGName : 80" `
    $FogTest.TcpTestSucceeded "FOG HTTP interface"

# 4. Check domain secure channel
$Computer = Get-CimInstance Win32_ComputerSystem

if ($Computer.PartOfDomain -and $Computer.Domain -eq $Domain) {
    try {
        $SecureChannel = Test-ComputerSecureChannel -ErrorAction Stop

        Add-Result "Domain secure channel" $Domain `
            $SecureChannel "Computer: $($Computer.Name)"
    }
    catch {
        Add-Result "Domain secure channel" $Domain `
            $false $_.Exception.Message
    }
}
else {
    Write-Host "Secure channel check skipped: computer is not domain-joined." `
        -ForegroundColor Yellow
}

# 5. Display results
Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan

$Results | Format-Table -AutoSize -Wrap

$Failed = @($Results | Where-Object Status -eq "FAIL").Count

if ($Failed -eq 0) {
    Write-Host "All checks passed." -ForegroundColor Green
}
else {
    Write-Host "$Failed check(s) failed." -ForegroundColor Red
}
