# PXE Network Boot Configuration

![PXE](https://img.shields.io/badge/PXE-Network_Boot-183A61?style=flat-square)
![DHCP](https://img.shields.io/badge/DHCP-DC01-0078D4?style=flat-square)
![TFTP](https://img.shields.io/badge/TFTP-FOG01-E95420?style=flat-square)
![iPXE](https://img.shields.io/badge/Bootloader-iPXE-238636?style=flat-square)

## Overview

I configured PXE boot to start Windows virtual machines directly from the network instead of using their local disks.

The setup uses Windows DHCP on DC01 and FOG Project on FOG01. This keeps address assignment separate from the deployment service.

I tested the complete boot process, including DHCP configuration, TFTP file transfer, iPXE startup, and the FOG boot menu.

## PXE Infrastructure

| Component | Hostname | IP Address | Role |
|---|---|---|---|
| DHCP Server | DC01 | 192.168.10.10 | Assigns IP addresses and PXE options |
| TFTP / PXE Server | FOG01 | 192.168.10.20 | Provides the network boot file |
| PXE Client | Windows VM | DHCP | Starts network boot |

### DHCP Boot Options

The LABNET scope on DC01 contains two additional options for PXE booting.

| Option | Name | Value |
|---|---|---|
| 066 | Boot Server Host Name | 192.168.10.20 |
| 067 | Bootfile Name | undionly.kpxe |

The boot file undionly.kpxe is used for Legacy BIOS PXE booting.

## How PXE Boot Works

The process starts when a Windows VM attempts to boot from its network adapter.

1. The client sends a DHCP request.
2. DC01 assigns an IP address and provides the network configuration.
3. The client receives DHCP options 066 and 067.
4. The client contacts FOG01 at 192.168.10.20.
5. TFTP transfers undionly.kpxe to the client.
6. The iPXE bootloader starts.
7. iPXE communicates with FOG and retrieves the network boot configuration.
8. The FOG boot menu appears.

This allows a client to start the FOG environment without using its local Windows installation.

## VirtualBox Configuration

The PXE client must use the same internal VirtualBox network as DC01 and FOG01.

### Network Adapter

1. Shut down the Windows client VM.
2. Open VirtualBox Manager.
3. Select the required virtual machine.
4. Open Settings → Network.
5. Enable the network adapter.
6. Set Attached to: Internal Network.
7. Select the same internal network used by the lab servers.
8. Save the settings.

### Boot Order

To make the VM attempt network boot first:

1. Open the virtual machine Settings.
2. Select System → Motherboard.
3. Locate Boot Order.
4. Enable Network.
5. Move Network above Hard Disk.
6. Save the changes.

### Firmware Mode

The current PXE configuration uses undionly.kpxe, which is intended for Legacy BIOS.

The VM must therefore use a compatible BIOS firmware configuration. UEFI network boot requires a different boot file and corresponding DHCP settings.

## DHCP Configuration on DC01

DHCP is managed centrally on DC01.

The PXE options are configured at the LABNET scope level.

### Configure Through DHCP Manager

1. Open Server Manager.
2. Select Tools → DHCP.
3. Expand DC01.
4. Expand IPv4.
5. Expand LABNET.
6. Select Scope Options.
7. Check options 066 and 067.

The values should point to FOG01 and the correct network boot file.

### Configure Through PowerShell

Run in an elevated PowerShell session on DC01.

```powershell
$ScopeId = "192.168.10.0"

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

These commands modify the existing DHCP scope options. They are included as configuration examples and do not need to be executed again when the settings are already correct.

To display the configured options:

```powershell
Get-DhcpServerv4OptionValue -ScopeId $ScopeId
```

## TFTP Configuration on FOG01

TFTP (Trivial File Transfer Protocol) is used to transfer the initial boot file from FOG01 to the PXE client.

The boot file used in this lab is:

undionly.kpxe

Its location on FOG01 is:

/tftpboot/undionly.kpxe

### Check the Boot File

```bash
sudo ls -lh /tftpboot/undionly.kpxe
```

### Check the TFTP Service

```bash
sudo systemctl status tftpd-hpa --no-pager
```

To check whether a TFTP listener is present:

```bash
sudo ss -lunp | grep ':69'
```

TFTP uses UDP port 69 for the initial request. The file transfer itself uses additional negotiated UDP ports.

## PXE Testing

I tested PXE boot using a Windows virtual machine connected to the internal network.

The client successfully completed the following steps:

| Test | Result |
|---|---|
| DHCP address assignment | Successful |
| DHCP PXE options | Configured |
| TFTP boot file transfer | Successful |
| iPXE startup | Successful |
| FOG boot menu | Successfully displayed |

The test confirmed that DC01 and FOG01 work together to provide network boot functionality.

## FOG Host Registration

After reaching the FOG boot menu, I also tested host registration.

The registration process allows a Windows computer to be added to the list of managed hosts in FOG.

### Registration Procedure

1. Start the client using PXE.
2. Wait for the FOG boot menu.
3. Select the host registration option.
4. Follow the registration prompts.
5. Open the FOG management interface.
6. Navigate to Hosts.
7. Check that the registered computer appears in the list.

Host registration was successfully tested in the lab.

## Troubleshooting

### Client Does Not Receive an IP Address

Possible causes include:

- The DHCP scope is inactive.
- The DHCP server is not bound to the internal network adapter.
- The client is connected to the wrong VirtualBox network.
- The DHCP service is unavailable.

Useful commands on DC01:

```powershell
Get-DhcpServerv4Scope

Get-DhcpServerv4Binding

Get-DhcpServerv4Lease -ScopeId "192.168.10.0"
```

### Client Receives an IP but Does Not Download the Boot File

Check the following:

- Option 066 points to 192.168.10.20.
- Option 067 contains undionly.kpxe.
- The TFTP service is running on FOG01.
- The boot file exists in /tftpboot.
- The client is using the correct internal network.

Useful commands on FOG01:

```bash
sudo systemctl status tftpd-hpa --no-pager

sudo ls -lh /tftpboot/undionly.kpxe
```

### FOG Boot Menu Does Not Appear

If iPXE starts but the FOG menu does not appear, check:

- Whether FOG01 is reachable from the client.
- Whether the Apache service is running.
- Whether the client can communicate with the FOG server.
- Whether the correct firmware mode and boot file are being used.

Check Apache on FOG01:

```bash
sudo systemctl status apache2 --no-pager
```

### BIOS and UEFI Compatibility

The current lab uses undionly.kpxe for Legacy BIOS.

A client using UEFI firmware may fail to start with this boot file. In that case, the boot file and DHCP configuration must match the firmware mode.

## Screenshots

The following screenshots document the PXE configuration and testing.

| Screenshot | Description |
|---|---|
| 20-pxe-client-boot.png | Windows client booting from the network (PXE boot process) |
| 21-pxe-host-registration-menu.png | FOG menu with the option to register a new host |

The DHCP scope options are also documented in 08-dhcp-scope-options.png in the DNS and DHCP section.

Only include screenshots that actually exist in the repository.

## Summary

I configured PXE boot using Windows DHCP Server on DC01 and FOG Project on FOG01.

The Windows client successfully received its network configuration, downloaded undionly.kpxe through TFTP, started iPXE, and displayed the FOG boot menu.

I also tested host registration, which allowed the client to appear in the FOG management interface.
