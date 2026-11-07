# DNS and DHCP Configuration

## 1. Overview

DNS and DHCP are essential network services in the lab environment.

Both services run on the Windows Server 2022 domain controller `DC01`.

- **DNS (Domain Name System)** resolves hostnames to IP addresses and provides Active Directory service records.
- **DHCP (Dynamic Host Configuration Protocol)** automatically assigns IP addresses and network configuration to client machines.

These services allow domain computers to discover the domain controller and communicate with other lab machines.

## 2. Network Configuration

### DNS Information

| Parameter | Value |
|---|---|
| DNS Server | DC01 |
| DNS Server IP | `192.168.10.10` |
| Forward Lookup Zone | `contoso.local` |
| Reverse Lookup Zone | `10.168.192.in-addr.arpa` |
| FOG01 IP | `192.168.10.20` |

### DHCP Scope Information

| Parameter | Value |
|---|---|
| Scope Name | LABNET |
| Network | `192.168.10.0/24` |
| Start IP | `192.168.10.100` |
| End IP | `192.168.10.200` |
| Subnet Mask | `255.255.255.0` |
| DNS Server | `192.168.10.10` |
| DNS Domain | `contoso.local` |

## 3. DNS Configuration

### 3.1 GUI Configuration

Open DNS Manager:

1. Open Server Manager.
2. Select Tools.
3. Click DNS.
4. Expand `DC01`.
5. Expand Forward Lookup Zones.
6. Open `contoso.local`.

### Forward Lookup Zone

The forward lookup zone contains DNS records for domain computers and services.

Important records include:

| Hostname | IP Address | Record Type |
|---|---|---|
| DC01 | `192.168.10.10` | A |
| FOG01 | `192.168.10.20` | A |
| Client hostnames | DHCP-assigned addresses | A |

Active Directory also registers service records, including LDAP and Kerberos SRV records.

### Create an A Record

1. Open Forward Lookup Zones.
2. Right-click `contoso.local`.
3. Select New Host (A or AAAA).
4. Enter the computer name.
5. Enter its IPv4 address.
6. Optionally select Create associated pointer (PTR) record.
7. Click Add Host.

Only create records that do not already exist.

### Reverse Lookup Zone

A reverse lookup zone resolves IP addresses to hostnames.

The lab uses:

`10.168.192.in-addr.arpa`

To create the zone:

1. Right-click Reverse Lookup Zones.
2. Select New Zone.
3. Choose Primary Zone.
4. Enable Active Directory integration if offered.
5. Select the appropriate replication scope.
6. Choose IPv4 Reverse Lookup Zone.
7. Enter network ID `192.168.10`.
8. Complete the wizard.

### Create a PTR Record

A PTR record maps an IP address to a hostname.

The lab contains a PTR record for:

| IP Address | Hostname |
|---|---|
| `192.168.10.10` | `DC01.contoso.local` |

To create it:

1. Open the reverse lookup zone.
2. Right-click the zone.
3. Select New Pointer (PTR).
4. Enter the last octet of the IP address: `10`.
5. Enter `DC01.contoso.local`.
6. Confirm the operation.

## 4. DNS PowerShell Configuration

Run these commands on `DC01` using an elevated PowerShell session.

### Verify DNS Zones

```powershell
Get-DnsServerZone |
    Select-Object ZoneName, ZoneType, IsDsIntegrated
```

### Display Forward Lookup Records

```powershell
Get-DnsServerResourceRecord -ZoneName "contoso.local" |
    Select-Object HostName, RecordType, Timestamp
```

### Create an A Record

Example for FOG01, if the record does not already exist:

```powershell
Add-DnsServerResourceRecordA `
    -Name "FOG01" `
    -ZoneName "contoso.local" `
    -IPv4Address "192.168.10.20"
```

### Verify Reverse Lookup Records

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "10.168.192.in-addr.arpa"
```

### Create a PTR Record

Example for DC01, if the record does not already exist:

```powershell
Add-DnsServerResourceRecordPtr `
    -Name "10" `
    -ZoneName "10.168.192.in-addr.arpa" `
    -PtrDomainName "DC01.contoso.local"
```

## 5. DHCP Configuration

### 5.1 GUI Configuration

Open DHCP Manager:

1. Open Server Manager.
2. Select Tools.
3. Click DHCP.
4. Expand `DC01`.
5. Expand IPv4.
6. Open the `LABNET` scope.

### Address Pool

The DHCP address pool defines the range of addresses available to clients.

Configured range:

`192.168.10.100 – 192.168.10.200`

To view it:

1. Expand IPv4.
2. Expand LABNET.
3. Select Address Pool.

### Address Leases

Address Leases displays IP addresses currently assigned to DHCP clients.

To view leases:

1. Expand LABNET.
2. Select Address Leases.
3. Review assigned IP addresses, hostnames, and lease information.

### Scope Options

Scope Options define additional network settings distributed to clients.

The following options are configured:

| Option | Name | Value |
|---|---|---|
| 006 | DNS Servers | `192.168.10.10` |
| 015 | DNS Domain Name | `contoso.local` |
| 066 | Boot Server Host Name | `192.168.10.20` |
| 067 | Bootfile Name | `undionly.kpxe` |

Options 066 and 067 are used for PXE network booting in the FOG deployment environment.

To view the settings:

1. Expand LABNET.
2. Select Scope Options.
3. Review the configured options.

### DHCP Server Bindings

DHCP must be bound to the network interface connected to the lab network.

The lab uses:

- Interface: `Ethernet 2`
- IP address: `192.168.10.10`
- DHCP Binding: Enabled

To view the configuration:

1. Right-click the DHCP server `DC01`.
2. Select Properties.
3. Open the Advanced tab.
4. Click Bindings.
5. Verify that the lab network interface is enabled.

## 6. DHCP PowerShell Configuration

### Display DHCP Scopes

```powershell
Get-DhcpServerv4Scope
```

### Create a DHCP Scope

Example configuration for a new scope:

```powershell
$Scope = Get-DhcpServerv4Scope `
    -ScopeId "192.168.10.0" `
    -ErrorAction SilentlyContinue

if (-not $Scope) {
    Add-DhcpServerv4Scope `
        -Name "LABNET" `
        -StartRange "192.168.10.100" `
        -EndRange "192.168.10.200" `
        -SubnetMask "255.255.255.0" `
        -State Active
}
else {
    Write-Host "DHCP scope LABNET already exists."
}
```

### Configure DHCP Scope Options

These commands configure the options for the LABNET scope:

```powershell
$ScopeId = "192.168.10.0"

# DNS server
Set-DhcpServerv4OptionValue `
    -ScopeId $ScopeId `
    -DnsServer "192.168.10.10"

# DNS domain name
Set-DhcpServerv4OptionValue `
    -ScopeId $ScopeId `
    -DnsDomain "contoso.local"

# PXE boot server
Set-DhcpServerv4OptionValue `
    -ScopeId $ScopeId `
    -OptionId 66 `
    -Value "192.168.10.20"

# PXE boot file
Set-DhcpServerv4OptionValue `
    -ScopeId $ScopeId `
    -OptionId 67 `
    -Value "undionly.kpxe"
```

These commands change the scope configuration. Run them only when the values need to be configured or corrected.

### Display DHCP Scope Options

```powershell
Get-DhcpServerv4OptionValue -ScopeId "192.168.10.0"
```

### Display DHCP Leases

```powershell
Get-DhcpServerv4Lease -ScopeId "192.168.10.0"
```

### Verify DHCP Bindings

```powershell
Get-DhcpServerv4Binding
```

## 7. Verification and Troubleshooting

### Verify DNS Resolution

Run these commands from a machine using the lab DNS server:

```powershell
nslookup DC01.contoso.local
nslookup FOG01.contoso.local
```

To check a reverse lookup:

```powershell
nslookup -type=PTR 192.168.10.10
```

### Verify Active Directory SRV Records

```powershell
nslookup -type=SRV _ldap._tcp.dc._msdcs.contoso.local
```

This checks whether the domain controller's LDAP service record can be found through DNS.

### Verify Client Network Configuration

```powershell
ipconfig /all
```

Check:

- IPv4 address belongs to `192.168.10.0/24`.
- Subnet mask is `255.255.255.0`.
- DNS server is `192.168.10.10`.
- DNS suffix is `contoso.local`.

### Renew a DHCP Lease

```powershell
ipconfig /release
ipconfig /renew
```

These commands release and request a DHCP address. Do not run them during remote access if losing the network connection could interrupt your session.

### Flush DNS Cache

```powershell
ipconfig /flushdns
```

This clears the local DNS resolver cache.

## 8. Screenshots

The following screenshots document the DNS and DHCP configuration:

### DHCP

| Screenshot | Description |
|---|---|
| `06-dhcp-address-pool.png` | DHCP address pool |
| `07-dhcp-address-leases.png` | Active DHCP leases |
| `08-dhcp-scope-options.png` | DHCP scope options |
| `09-dhcp-server-bindings.png` | DHCP interface bindings |

### DNS

| Screenshot | Description |
|---|---|
| `10-dns-forward-lookup-zone.png` | Forward lookup zone |
| `11-dns-host-records.png` | DNS A records |
| `12-dns-srv-records.png` | Active Directory SRV records |
| `13-dns-resolution-tests.png` | DNS resolution tests |

## 9. Summary

DNS and DHCP provide the foundation for network communication and domain services in the lab.

DNS resolves hostnames and provides Active Directory service records. DHCP automatically assigns IP addresses and distributes DNS and PXE boot configuration.

Both services are managed through graphical administration tools and PowerShell.
