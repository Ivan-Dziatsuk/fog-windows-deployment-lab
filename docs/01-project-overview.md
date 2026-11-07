# Project Overview

## Introduction

This project is a virtualized Windows infrastructure lab designed to practice real-world system administration tasks.

The lab combines Windows Server, Active Directory, network services, Group Policy, file sharing, and automated Windows deployment.

## Main Goals

- Learn Windows Server administration.
- Practice Active Directory domain management.
- Configure DNS and DHCP services.
- Manage users, groups, and computers.
- Implement Group Policy security settings.
- Configure SMB file sharing and access permissions.
- Deploy Windows 11 using FOG Project and PXE.
- Automate administrative tasks using PowerShell.

## Infrastructure Overview

The environment consists of three main virtual machines:

| Hostname | Operating System | Purpose | IP Address |
|---|---|---|---|
| DC01 | Windows Server 2022 | Active Directory, DNS, DHCP | 192.168.10.10 |
| FOG01 | Ubuntu Server 26.04 LTS | FOG Project and PXE deployment | 192.168.10.20 |
| WIN11-TEST | Windows 11 Pro | Deployment and domain testing | DHCP |
| Client1 | Windows 11 Pro | Deployment and domain testing | DHCP |
| WIN11-IMAGE | Windows 11 Pro | Deployment, not in domain | - |

The virtual machines communicate through an internal VirtualBox network.

## Hardware Constraints

The lab runs on a laptop with 16 GB of RAM.

Due to limited hardware resources, virtual machines are configured with carefully allocated memory and CPU resources. Some testing scenarios are performed sequentially rather than running every virtual machine simultaneously.

## Project Scope

The project covers the following areas:

1. Windows Server installation and configuration.
2. Active Directory Domain Services.
3. DNS and DHCP administration.
4. Group Policy management.
5. SMB file server configuration.
6. FOG Project installation and configuration.
7. PXE-based Windows deployment.
8. PowerShell automation and system inventory.

## Learning Outcomes

Through this project, I gained practical experience with Windows infrastructure administration, network troubleshooting, access control, operating system deployment, and basic administrative automation.
