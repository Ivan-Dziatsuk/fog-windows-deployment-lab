# PXE Network Boot Configuration

## 1. Overview

PXE (Preboot Execution Environment) allows a computer to boot from a network instead of starting an operating system from its local disk.

In this lab, PXE is used to start the FOG Project boot environment and perform network-based host registration and operating system deployment.

The PXE infrastructure consists of:

- **DC01** — provides DHCP configuration.
- **FOG01** — provides TFTP and FOG network boot services.
- **Windows client VM** — acts as the PXE boot client.

## 2. PXE Infrastructure

| Component | Hostname | IP Address | Responsibility |
|---|---|---|---|
| DHCP Server | DC01 | 192.168.10.10 | Assigns IP addresses and PXE boot options |
| PXE / TFTP Server | FOG01 | 192.168.10.20 | Provides the network boot file |
| PXE Client | Windows VM | DHCP | Starts network boot |

### DHCP PXE Options

The DHCP scope `LABNET` contains the following PXE settings:

| Option | Name | Value |
|---|---|---|
| 066 | Boot Server Host Name | 192.168.10.20 |
| 067 | Bootfile Name | undionly.kpxe |

The boot file `undionly.kpxe` is used for Legacy BIOS PXE booting.

UEFI clients may require a different boot file and DHCP configuration. The configuration documented here is the one tested in this lab.

## 3. PXE Boot Process

The PXE boot process follows these steps:

1. The client starts and requests network configuration using DHCP.
2. DC01 responds with an available IP address and network settings.
3. The client receives DHCP PXE options 066 and 067.
4. The client contacts FOG01 at `192.168.10.20`.
5. The client downloads `undionly.kpxe` using TFTP.
6. The downloaded iPXE bootloader starts.
7. iPXE communicates with the FOG server and retrieves the network boot configuration.
8. The FOG boot menu appears.
9. The administrator can select an available network boot action.

### Communication Flow

```text
PXE Client
    |
    | DHCP Discovery / Request
    v
DC01 - DHCP Server
192.168.10.10
    |
    | DHCP Response:
    | IP configuration
    | Option 066: 192.168.10.20
    | Option 067: undionly.kpxe
    |
    v
FOG01 - TFTP Server
192.168.10.20
    |
    | Transfers undionly.kpxe
    v
PXE Client
    |
    | iPXE starts
    |
    | Retrieves boot configuration
    v
FOG Network Boot Menu
```

## 4. VirtualBox Client Configuration

The Windows client VM must be connected to the same internal VirtualBox network as DC01 and FOG01.

### Configure Network Adapter

1. Shut down the virtual machine.
2. Open VirtualBox Manager.
3. Select the Windows client VM.
4. Open Settings → Network.
5. Enable the network adapter.
6. Set Attached to: Internal Network.
7. Select the same internal network used by the lab servers.
8. Save the configuration.

### Configure Boot Order

1. Open the virtual machine Settings.
2. Select System → Motherboard.
3. Locate Boot Order.
4. Enable Network.
5. Move Network above Hard Disk when testing PXE boot.
6. Save the changes.

### Firmware Compatibility

The current lab configuration uses `undionly.kpxe`, which is intended for Legacy BIOS PXE booting.

The client VM must therefore use a compatible BIOS firmware configuration.

UEFI network boot requires a different boot file and corresponding configuration.

## 5. DHCP Configuration

DHCP is managed centrally on DC01.

The following options are configured at the `LABNET` scope level.

### GUI Configuration

1. Open Server Manager.
2. Select Tools → DHCP.
3. Expand DC01.
4. Expand IPv4.
5. Expand LABNET.
6. Select Scope Options.
7. Verify that options 066 and 067 contain the FOG server address and boot filename.

### PowerShell Configuration

Run on DC01 in an elevated PowerShell session.

```powershell
$ScopeId = "192.168.10.0"

# Configure PXE boot server
Set-DhcpServerv4OptionValue `
    -ScopeId $ScopeId `
    -OptionId 66 `
    -Value "192.168.10.20"

# Configure PXE boot file
Set-DhcpServerv4OptionValue `
    -ScopeId $ScopeId `
    -OptionId 67 `
    -Value "undionly.kpxe"
```

These commands change the existing DHCP scope options. They are included as configuration examples and do not need to be executed again when the settings are already correct.

### Verify DHCP Options

To display the configured options:

```powershell
Get-DhcpServerv4OptionValue -ScopeId $ScopeId
```

## 6. TFTP Configuration

TFTP (Trivial File Transfer Protocol) is used to transfer the initial network boot file from FOG01 to the PXE client.

The boot file used in this lab is:

`undionly.kpxe`

The default FOG TFTP directory is:

`/tftpboot`

### Verify the Boot File

Run on FOG01:

```bash
sudo ls -lh /tftpboot/undionly.kpxe
```

This checks whether the boot file exists in the TFTP directory.

### Verify TFTP Service

```bash
sudo systemctl status tftpd-hpa --no-pager
```

To check whether a TFTP listener is present:

```bash
sudo ss -lunp | grep ':69'
```

TFTP uses UDP port 69 for its initial requests. File transfer then uses additional UDP ports.

## 7. PXE Boot Testing

The PXE boot process was tested using a Windows virtual machine connected to the lab's internal network.

### Test Procedure

1. Start the PXE client VM.
2. Select network boot if required.
3. Observe the DHCP network configuration process.
4. Verify that the client receives an address from the LABNET scope.
5. Observe the TFTP transfer of `undionly.kpxe`.
6. Verify that iPXE starts.
7. Confirm that the FOG network boot menu appears.

### Test Results

| Test | Expected Result | Lab Result |
|---|---|---|
| DHCP address assignment | Client receives an address from LABNET | Successful |
| DHCP PXE options | Boot server and boot filename are provided | Configured |
| TFTP boot file transfer | undionly.kpxe is downloaded | Successful |
| iPXE startup | iPXE boot environment starts | Successful |
| FOG boot menu | FOG menu is displayed | Successful |

## 8. FOG Host Registration

FOG supports registering a client computer as a managed host.

Host registration allows the server to identify and manage a computer in the FOG management interface.

### Registration Procedure

1. Start the client using PXE.
2. Wait for the FOG boot menu.
3. Select the host registration option.
4. Follow the registration prompts.
5. Open the FOG web management interface.
6. Navigate to Hosts.
7. Verify that the registered host appears in the list.

Host registration was successfully tested in this lab.

## 9. Troubleshooting

### Client Does Not Receive an IP Address

Possible causes:

- DHCP scope is inactive.
- DHCP server is not bound to the internal network adapter.
- Client is connected to the wrong VirtualBox network.
- DHCP service is unavailable.

Useful commands on DC01:

```powershell
Get-DhcpServerv4Scope

Get-DhcpServerv4Binding

Get-DhcpServerv4Lease -ScopeId "192.168.10.0"
```

### Client Receives an IP but Does Not Download the Boot File

Check:

- DHCP option 066 points to `192.168.10.20`.
- DHCP option 067 contains `undionly.kpxe`.
- The TFTP service is running.
- The boot file exists in `/tftpboot`.

Useful commands on FOG01:

```bash
sudo systemctl status tftpd-hpa --no-pager

sudo ls -lh /tftpboot/undionly.kpxe
```

### FOG Boot Menu Does Not Appear

Check:

- The iPXE bootloader starts successfully.
- FOG01 is reachable from the client.
- Apache is running.
- The client uses a firmware mode compatible with the configured PXE boot file.

```bash
sudo systemctl status apache2 --no-pager
```

### Firmware Compatibility Issues

If the client does not start the expected bootloader, check whether it uses Legacy BIOS or UEFI firmware.

The current lab uses `undionly.kpxe` for Legacy BIOS. UEFI clients require a compatible boot file and DHCP configuration.

## 10. Screenshots

The following screenshots document the PXE configuration and testing:

| Screenshot | Description |
|---|---|
| `20-pxe-client-network.png` | VirtualBox client network configuration |
| `21-pxe-client-boot-order.png` | VirtualBox network boot configuration |
| `22-pxe-client-dhcp.png` | Client receives an IP address during PXE startup |
| `23-pxe-tftp-boot.png` | TFTP boot file transfer and iPXE startup |
| `24-pxe-fog-menu.png` | FOG network boot menu |
| `25-pxe-host-registration.png` | Successful host registration |

The DHCP scope options are documented separately in `08-dhcp-scope-options.png`.

## 11. Summary

PXE network booting was configured using Windows DHCP Server on DC01 and FOG Project on FOG01.

The client successfully received its network configuration, downloaded `undionly.kpxe` through TFTP, started iPXE, and displayed the FOG boot menu.

FOG host registration was also successfully tested in this lab.
