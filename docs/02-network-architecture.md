# Network Architecture

## Overview

The lab uses an isolated VirtualBox Internal Network for communication between virtual machines.

The internal network uses the `192.168.10.0/24` subnet.

Virtual machines can also use NAT network adapters for internet access where required.

## Network Configuration

| Parameter | Value |
|---|---|
| Network Type | VirtualBox Internal Network |
| Network Address | `192.168.10.0/24` |
| Subnet Mask | `255.255.255.0` |
| Domain Name | `contoso.local` |
| DNS Server | `192.168.10.10` |
| DHCP Server | `192.168.10.10` |
| PXE Boot Server | `192.168.10.20` |

## Virtual Machines

| Hostname | Operating System | Role | Internal IP |
|---|---|---|---|
| DC01 | Windows Server 2022 | Active Directory, DNS, DHCP | `192.168.10.10` |
| FOG01 | Ubuntu Server 26.04 LTS | FOG Project, PXE, TFTP | `192.168.10.20` |
| WIN11-TEST | Windows 11 Pro | Deployment and domain testing | DHCP |
| Client1 | Windows 11 Pro | Additional domain client and AD administration testing | DHCP |
| WIN11-IMAGE | Windows 11 Pro | Reference machine for image preparation and capture; not domain joined | Not assigned |

## Network Services

### DC01 — Domain Controller

DC01 provides centralized domain and network services:

- Active Directory Domain Services (AD DS).
- DNS name resolution for `contoso.local`.
- DHCP address assignment.
- DHCP options for PXE network boot.

### FOG01 — Deployment Server

FOG01 provides network-based operating system deployment:

- FOG Project management interface.
- TFTP service for PXE boot files.
- iPXE boot environment.
- Windows image storage and deployment.

### WIN11-TEST — Deployment Test Client

WIN11-TEST is used to verify the deployed Windows 11 image and test:

- DHCP address assignment.
- DNS name resolution.
- Active Directory domain membership.
- Group Policy application.
- Windows image deployment.

### Client1 — Additional Windows Client

Client1 is used for additional Windows client administration and Active Directory practice.

It provides an environment for testing domain connectivity, computer account management, and client configuration.

### WIN11-IMAGE — Reference Machine

WIN11-IMAGE is a reference Windows 11 machine used to prepare the operating system before image capture.

Its purpose is to:

- Prepare the Windows 11 reference installation.
- Perform Sysprep before image capture.
- Capture the prepared image using FOG Project.
- Provide a clean reference image for deployment testing.

WIN11-IMAGE is not joined to the Active Directory domain.

## DHCP and PXE Configuration

The DHCP scope is configured on DC01:

| Setting | Value |
|---|---|
| Scope Name | `LABNET` |
| Address Range | `192.168.10.100 - 192.168.10.200` |
| Subnet Mask | `255.255.255.0` |
| Option 006 — DNS Server | `192.168.10.10` |
| Option 015 — DNS Domain Name | `contoso.local` |
| Option 066 — Boot Server Host Name | `192.168.10.20` |
| Option 067 — Bootfile Name | `undionly.kpxe` |

The DHCP server assigns IP configuration to clients and provides the information required to locate the FOG PXE boot server.

## Network Communication Flow

1. A client requests network configuration using DHCP.
2. DC01 assigns an IP address and provides DNS and PXE settings.
3. The client contacts FOG01 to download the PXE boot file using TFTP.
4. The iPXE environment loads the FOG boot menu.
5. The client can register with FOG or start an available deployment task.

## Hardware Constraints

The lab runs on a laptop with 16 GB of RAM. Virtual machines use carefully allocated resources, and some testing scenarios are performed sequentially.

## Summary

The network architecture separates domain services from operating system deployment services.

DC01 manages domain authentication, DNS, and DHCP, while FOG01 handles PXE boot and Windows image deployment.

WIN11-IMAGE serves as the reference system for image preparation, while WIN11-TEST and Client1 provide Windows client environments for deployment and administration testing.
