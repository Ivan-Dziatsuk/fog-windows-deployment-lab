# Network Architecture

![Internal Network](https://img.shields.io/badge/INTERNAL_NETWORK-192.168.10.0%2F24-238636?style=flat-square)
![Active Directory](https://img.shields.io/badge/ACTIVE_DIRECTORY-contoso.local-0969DA?style=flat-square)
![DHCP](https://img.shields.io/badge/DHCP-DC01-0078D4?style=flat-square)
![PXE](https://img.shields.io/badge/PXE-FOG01-183A61?style=flat-square)

## Overview

I use a VirtualBox Internal Network to connect the virtual machines in this lab. This keeps communication between the servers and Windows clients separate from the host's physical network.

The internal network uses the 192.168.10.0/24 subnet. DC01 and FOG01 also have NAT network adapters for internet access when needed.

The network is built around two servers: DC01 handles domain and network services, while FOG01 is responsible for PXE boot and Windows deployment.

## Network Configuration

| Parameter | Value |
|---|---|
| Network Type | VirtualBox Internal Network |
| Network Address | 192.168.10.0/24 |
| Subnet Mask | 255.255.255.0 |
| Domain Name | contoso.local |
| DNS Server | 192.168.10.10 |
| DHCP Server | 192.168.10.10 |
| PXE Boot Server | 192.168.10.20 |

All machines use the internal network to communicate with each other. NAT adapters provide a separate connection to the internet.

## Virtual Machines

| Hostname | Operating System | Role | Internal IP |
|---|---|---|---|
| DC01 | Windows Server 2022 | Active Directory, DNS, DHCP | 192.168.10.10 |
| FOG01 | Ubuntu Server 26.04.1 LTS | FOG Project, PXE, TFTP | 192.168.10.20 |
| WIN11-TEST | Windows 11 Pro | Deployment and domain testing | DHCP |
| Client1 | Windows 11 Pro | Additional domain client and administration testing | DHCP |
| WIN11-IMAGE | Windows 11 Pro | Reference machine for image preparation and capture | No fixed IP |

DC01 and FOG01 have two network interfaces: one connected to NAT and another connected to the internal network.

## Network Layout

The table below shows how the main machines communicate and what each server provides.

| Source | Destination | Purpose |
|---|---|---|
| DC01 | WIN11-TEST | DHCP, DNS, domain services |
| DC01 | Client1 | DHCP, DNS, domain services |
| DC01 | WIN11-IMAGE | DHCP during network boot |
| Windows PXE clients | FOG01 | TFTP boot file and FOG network boot |
| WIN11-IMAGE | FOG01 | Windows image capture |
| FOG01 | WIN11-TEST | Windows image deployment |

The internal network allows the servers and clients to communicate without depending on the host's physical network.

## Servers and Their Roles

### DC01 — Domain Controller

DC01 is the main infrastructure server in the lab. It provides centralized domain and network services.

Configured roles:

- Active Directory Domain Services (AD DS)
- DNS Server
- DHCP Server

The DNS server hosts the contoso.local zone. DHCP assigns IP addresses from the LABNET scope and provides the settings required for DNS resolution and PXE boot.

### FOG01 — Deployment Server

FOG01 runs Ubuntu Server and hosts FOG Project.

I use it for:

- Managing registered Windows clients.
- Providing PXE boot files through TFTP.
- Starting the iPXE environment.
- Storing Windows images.
- Capturing and deploying operating system images.

DHCP is not running on FOG01. Address assignment is handled by DC01.

### Windows Clients

There are three Windows 11 virtual machines in the lab, each with a different purpose.

**WIN11-TEST**

Used to test the deployed Windows image, domain membership, DNS resolution, and Group Policy application.

**Client1**

An additional domain client used for Active Directory and general Windows administration practice.

**WIN11-IMAGE**

The reference machine used to prepare Windows 11 before capturing an image with FOG. It is kept outside the Active Directory domain.

Keeping the reference machine separate makes it easier to maintain a clean Windows installation for deployment testing.

## DHCP and PXE Configuration

DHCP is configured on DC01. The scope is named LABNET and provides addresses for the internal network.

| Setting | Value |
|---|---|
| Scope Name | LABNET |
| Address Range | 192.168.10.100 – 192.168.10.200 |
| Subnet Mask | 255.255.255.0 |
| Option 006 — DNS Server | 192.168.10.10 |
| Option 015 — DNS Domain Name | contoso.local |
| Option 066 — Boot Server | 192.168.10.20 |
| Option 067 — Boot File | undionly.kpxe |

Options 066 and 067 tell PXE clients where to find the network boot server and which boot file to download.

## How PXE Clients Communicate

When a Windows client starts using network boot, the following process takes place:

1. The client requests network configuration through DHCP.
2. DC01 assigns an IP address and provides the PXE boot options.
3. The client contacts FOG01 and downloads undionly.kpxe using TFTP.
4. The iPXE bootloader starts and communicates with the FOG server.
5. The FOG network boot menu appears.
6. The client can register with FOG or execute an available deployment task.

This setup allows DHCP and deployment services to remain on separate servers.

## Hardware and Limitations

The lab runs on a laptop with 16 GB of RAM. Running all virtual machines simultaneously is not practical.

I start only the machines required for a particular task and perform some configuration and deployment scenarios sequentially.

## Summary

The network separates domain services from operating system deployment.

DC01 manages Active Directory, DNS, and DHCP. FOG01 handles PXE boot, image storage, and Windows deployment.

WIN11-IMAGE is used to prepare and capture the reference image, while WIN11-TEST and Client1 provide separate Windows client environments for testing and administration.
