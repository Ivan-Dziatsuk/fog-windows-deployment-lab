# Project Overview

![Windows Server](https://img.shields.io/badge/Windows_Server-2022-0078D4?style=flat-square&logo=windows&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04.1-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-Used-5391FE?style=flat-square&logo=powershell&logoColor=white)
![VirtualBox](https://img.shields.io/badge/VirtualBox-Home_Lab-183A61?style=flat-square&logo=virtualbox&logoColor=white)

## About the Project

I built this lab to get more practical experience with Windows Server administration and everyday infrastructure tasks.

The environment runs in Oracle VirtualBox on my personal laptop. It includes a Windows Server domain controller, a separate FOG deployment server, and several Windows 11 virtual machines.

I wanted to build something close to a small company environment rather than just install individual Windows Server roles and leave them running.

The main focus is Active Directory, DNS, DHCP, Group Policy, file sharing, and Windows deployment.

## Lab Environment

![Domain](https://img.shields.io/badge/DOMAIN-contoso.local-0969DA?style=flat-square)
![Network](https://img.shields.io/badge/NETWORK-192.168.10.0%2F24-238636?style=flat-square)

The lab uses the contoso.local domain and an internal network with the address range 192.168.10.0/24.

| Hostname | Operating System | Purpose | IP Address |
|---|---|---|---|
| DC01 | Windows Server 2022 | Active Directory, DNS, DHCP | 192.168.10.10 |
| FOG01 | Ubuntu Server 26.04.1 LTS | FOG Project, TFTP, PXE | 192.168.10.20 |
| WIN11-TEST | Windows 11 Pro | Deployment and domain testing | DHCP |
| Client1 | Windows 11 Pro | Domain client | DHCP |
| WIN11-IMAGE | Windows 11 Pro | Reference machine for image capture | DHCP |

All virtual machines use the same internal VirtualBox network for communication.

## How the Lab Is Set Up

DC01 is the main Windows Server in the environment. It handles domain authentication, DNS resolution, and DHCP address assignment.

FOG01 is a separate Ubuntu Server. I installed FOG Project there to experiment with PXE boot, host registration, image capture, and deployment.

Windows clients receive their network configuration from DC01. When a machine starts through PXE, it uses FOG01 to load the network boot environment.

For image deployment, I use two separate Windows machines:

- WIN11-IMAGE is used to prepare and capture the reference Windows installation.
- WIN11-TEST is used to test deployment of the captured image.

Keeping these machines separate makes it easier to work with the reference image without changing the existing domain environment.

## What I Have Worked On

### Active Directory

- Created the contoso.local domain.
- Organized users and computers into Organizational Units.
- Created domain accounts and security groups.
- Joined Windows 11 machines to the domain.
- Tested domain membership and secure channel connectivity.

### DNS and DHCP

- Configured the internal DNS zone and reverse lookup.
- Worked with A, PTR, and SRV records.
- Created the LABNET DHCP scope.
- Configured DHCP options for DNS and PXE boot.

### Group Policy

- Created and linked several GPOs.
- Configured Microsoft Defender PUA protection in Block mode.
- Worked with security auditing and Windows Update policies.
- Checked applied policies using gpresult.

### File Sharing

- Created the IT-Share shared folder on DC01.
- Separated access into Public, Helpdesk, and Admin folders.
- Configured SMB and NTFS permissions.
- Practiced permission inheritance and Effective Access.

### FOG and Windows Deployment

- Installed FOG Project on Ubuntu Server.
- Configured PXE boot using Windows DHCP and FOG TFTP.
- Registered client machines.
- Captured a Windows 11 image.
- Deployed the image to another virtual machine.

### PowerShell

- Used PowerShell for Active Directory and Windows administration.
- Created a system inventory script using CIM.
- Tested remote script execution through FOG Snapins.

## Hardware and Limitations

![Hardware](https://img.shields.io/badge/RAM-16_GB-orange?style=flat-square)

The lab runs on a personal laptop with 16 GB of RAM.

This is enough for the main scenarios, but running all virtual machines at the same time is not practical. I usually start only the machines needed for a particular task and perform some tests sequentially.

This also means that the lab is intentionally smaller than a typical corporate environment.

## Documentation

I keep separate notes for each part of the lab so that the configuration can be understood and repeated later.

| File | Description |
|---|---|
| 02-network-architecture.md | Network configuration and VM connectivity |
| 03-active-directory.md | Domain, users, computers, and OUs |
| 04-dns-and-dhcp.md | DNS and DHCP configuration |
| 05-fog-installation.md | FOG installation on Ubuntu Server |
| 06-pxe-boot.md | PXE boot configuration and testing |
| 07-image-capture-deployment.md | Windows image capture and deployment |
| 08-powershell-snapins.md | PowerShell automation using FOG Snapins |
| 09-group-policy-management.md | Group Policy configuration |
| 10-smb-file-server.md | Shared folders and access permissions |

## Screenshots

| Screenshot | Description |
|---|---|
| 00-virtualbox-lab-overview.png | VirtualBox overview showing all lab virtual machines |

## Current Status

The main infrastructure is in place. I have tested domain joining, DNS and DHCP functionality, PXE boot, image capture and deployment, Group Policy application, and basic FOG Snapin execution.

I am continuing to improve the documentation and organize the PowerShell commands and scripts used during the lab.
