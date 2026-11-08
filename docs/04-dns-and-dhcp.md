# DNS and DHCP Configuration

![DNS](https://img.shields.io/badge/DNS-DC01-0969DA?style=flat-square)
![DHCP](https://img.shields.io/badge/DHCP-LABNET-238636?style=flat-square)
![Active Directory](https://img.shields.io/badge/DOMAIN-contoso.local-0078D4?style=flat-square)
![Network](https://img.shields.io/badge/NETWORK-192.168.10.0%2F24-238636?style=flat-square)

## Overview

Both DNS and DHCP run on DC01 (Windows Server 2022). They provide the network services needed by the domain computers.

DNS resolves computer names and maintains the service records required by Active Directory. DHCP assigns IP addresses and provides clients with their network configuration.

Keeping both services on the domain controller makes it easier to manage the lab from one place.

## Network Configuration

The internal network uses the following configuration:

| Parameter | Value |
|---|---|
| DNS Server | DC01 |
| DNS Server IP | 192.168.10.10 |
| Forward Lookup Zone | contoso.local |
| Reverse Lookup Zone | 10.168.192.in-addr.arpa |
| FOG01 Internal IP | 192.168.10.20 |
| DHCP Scope | LABNET |
| Address Range | 192.168.10.100 – 192.168.10.200 |
| Subnet Mask | 255.255.255.0 |

## DNS Configuration

### Forward Lookup Zone

The forward lookup zone contoso.local contains DNS records for the domain and lab servers.

Some of the important records are:

| Hostname | IP Address | Record Type |
|---|---|---|
| DC01 | 192.168.10.10 | A |
| FOG01 | 192.168.10.20 | A |
| Windows client hostnames | DHCP-assigned addresses | A |

Active Directory also maintains service records (SRV) used by domain clients to locate services such as LDAP and Kerberos.

### Managing DNS Through DNS Manager

To open DNS Manager:

1. Open Server Manager on DC01.
2. Select Tools → DNS.
3. Expand DC01.
4. Expand Forward Lookup Zones.
5. Select contoso.local.

To create a new A record:

1. Right-click contoso.local.
2. Select New Host (A or AAAA).
3. Enter the computer name.
4. Enter its IPv4 address.
5. Optionally select Create associated pointer (PTR) record.
6. Click Add Host.

I only create records that do not already exist, to avoid duplicate entries.

### Reverse Lookup Zone

The reverse lookup zone is used to resolve IP addresses back to hostnames.

For the 192.168.10.0/24 network, the zone is:

10.168.192.in-addr.arpa

To create it through DNS Manager:

1. Right-click Reverse Lookup Zones.
2. Select New Zone.
3. Choose Primary Zone.
4. Enable Active Directory integration if offered.
5. Select the appropriate replication scope.
6. Choose IPv4 Reverse Lookup Zone.
7. Enter the network ID 192.168.10.
8. Complete the wizard.

### PTR Records

A PTR record maps an IP address to a hostname.

The lab has a PTR record for the domain controller:

| IP Address | Hostname |
|---|---|
| 192.168.10.10 | DC01.contoso.local |

To create a PTR record:

1. Open the reverse lookup zone.
2. Right-click the zone.
3. Select New Pointer (PTR).
4. Enter the last octet of the IP address: 10.
5. Enter DC01.contoso.local.
6. Confirm the operation.

## DNS PowerShell Commands

I also use the DNS Server PowerShell module to inspect and manage records on DC01.

### List DNS Zones

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

Example for FOG01, only if the record does not already exist:

```powershell
Add-DnsServerResourceRecordA `
    -Name "FOG01" `
    -ZoneName "contoso.local" `
    -IPv4Address "192.168.10.20"
```

### Display Reverse Lookup Records

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "10.168.192.in-addr.arpa"
```

### Create a PTR Record

Example for DC01, only if the record does not already exist:

```powershell
Add-DnsServerResourceRecordPtr `
    -Name "10" `
    -ZoneName "10.168.192.in-addr.arpa" `
    -PtrDomainName "DC01.contoso.local"
```

## DHCP Configuration

DHCP runs on DC01 and provides IP addresses to machines connected to the internal network.

The main scope is named LABNET.

### Scope Configuration

| Parameter | Value |
|---|---|
| Scope Name | LABNET |
| Network | 192.168.10.0/24 |
| Start IP | 192.168.10.100 |
| End IP | 192.168.10.200 |
| Subnet Mask | 255.255.255.0 |
| DNS Server | 192.168.10.10 |
| DNS Domain | contoso.local |

### Managing DHCP Through DHCP Manager

To open DHCP Manager:

1. Open Server Manager.
2. Select Tools → DHCP.
3. Expand DC01.
4. Expand IPv4.
5. Open the LABNET scope.

The DHCP console contains several useful sections:

- Address Pool — defines the range of available IP addresses.
- Address Leases — shows addresses currently assigned to clients.
- Scope Options — contains additional network configuration distributed to clients.

### DHCP Address Pool

The configured address range is:

192.168.10.100 – 192.168.10.200

To view the pool:

1. Expand IPv4.
2. Expand LABNET.
3. Select Address Pool.

### Address Leases

Address Leases displays the IP addresses currently assigned to DHCP clients.

To view the leases:

1. Expand LABNET.
2. Select Address Leases.
3. Review assigned addresses, hostnames, and lease information.

### Scope Options

The following options are configured for the LABNET scope:

| Option | Name | Value |
|---|---|---|
| 006 | DNS Servers | 192.168.10.10 |
| 015 | DNS Domain Name | contoso.local |
| 066 | Boot Server Host Name | 192.168.10.20 |
| 067 | Bootfile Name | undionly.kpxe |

Options 006 and 015 provide the DNS settings used by clients.

Options 066 and 067 provide the information required for PXE booting through FOG.

To view the settings:

1. Expand LABNET.
2. Select Scope Options.
3. Review the configured options.

### DHCP Server Bindings

DHCP must be enabled on the network interface connected to the internal lab network.

The interface used in this lab is:

| Parameter | Value |
|---|---|
| Interface | Ethernet 2 |
| IP Address | 192.168.10.10 |
| DHCP Binding | Enabled |

To check the configuration:

1. Right-click the DHCP server DC01.
2. Select Properties.
3. Open the Advanced tab.
4. Click Bindings.
5. Verify that the internal network interface is enabled.

## DHCP PowerShell Commands

The DHCP Server PowerShell module can be used to manage the scope and its options.

### Display DHCP Scopes

```powershell
Get-DhcpServerv4Scope
```

### Create a DHCP Scope

The following example creates LABNET only if the scope does not already exist.

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

These commands configure the DNS and PXE options for LABNET.

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

These commands modify the existing scope options. Use them when configuring or correcting the values, not just for viewing the current settings.

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

## DNS and DHCP Troubleshooting

### Check DNS Resolution

Run these commands from a machine using DC01 as its DNS server.

```powershell
nslookup DC01.contoso.local
nslookup FOG01.contoso.local
```

To check reverse resolution:

```powershell
nslookup -type=PTR 192.168.10.10
```

### Check Active Directory SRV Records

```powershell
nslookup -type=SRV _ldap._tcp.dc._msdcs.contoso.local
```

This checks whether the client can locate the domain controller's LDAP service through DNS.

### Check Client Network Configuration

```powershell
ipconfig /all
```

Check that:

- The IPv4 address belongs to 192.168.10.0/24.
- The subnet mask is 255.255.255.0.
- The DNS server is 192.168.10.10.
- The DNS suffix is contoso.local.

### Renew a DHCP Lease

```powershell
ipconfig /release
ipconfig /renew
```

These commands release the current address and request a new DHCP configuration.

### Clear the DNS Cache

```powershell
ipconfig /flushdns
```

This clears the local DNS resolver cache.

## Screenshots

The following screenshots document the DNS and DHCP configuration.

### DHCP

| Screenshot | Description |
|---|---|
| 06-dhcp-address-pool.png | DHCP address pool |
| 07-dhcp-address-leases.png | Active DHCP leases |
| 08-dhcp-scope-options.png | DHCP scope options |
| 09-dhcp-server-bindings.png | DHCP interface bindings |

### DNS

| Screenshot | Description |
|---|---|
| 10-dns-forward-lookup-zone.png | Forward lookup zone |
| 11-dns-host-records.png | DNS A records |
| 12-dns-srv-records.png | Active Directory SRV records |
| 13-dns-resolution-tests.png | DNS resolution tests |

Only include screenshots that show the actual lab configuration.

## Summary

DC01 provides both DNS and DHCP services for the internal network.

DNS handles hostname resolution and Active Directory service records. DHCP assigns addresses to clients and provides the configuration needed for DNS and PXE boot.

I use DNS Manager and DHCP Manager for graphical administration, and PowerShell for configuration, inspection, and troubleshooting.
