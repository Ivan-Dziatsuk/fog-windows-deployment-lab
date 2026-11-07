# Windows Infrastructure & Deployment Lab

A hands-on home lab project focused on building, configuring, and managing a small Windows-based corporate infrastructure.

The project demonstrates practical skills in Windows Server administration, Active Directory, network services, Group Policy, file sharing, operating system deployment, and PowerShell automation.

## Project Objectives

- Build a virtual Windows domain environment.
- Configure centralized user and computer management.
- Implement DNS and DHCP services.
- Manage security settings using Group Policy.
- Configure SMB file sharing and NTFS permissions.
- Deploy Windows 11 over the network using FOG Project and PXE.
- Automate basic administrative tasks with PowerShell.

## Lab Environment

| Component | Configuration |
|---|---|
| Host OS | Windows 11 |
| Virtualization | Oracle VirtualBox |
| Domain Controller | Windows Server 2022 |
| Deployment Server | Ubuntu Server 26.04 LTS |
| Client OS | Windows 11 Pro |
| Active Directory Domain | `contoso.local` |
| Internal Network | `192.168.10.0/24` |
| Host Hardware | Laptop with 16 GB RAM |

### Virtual Machines

| Hostname | Role | IP Address |
|---|---|---|
| DC01 | Active Directory, DNS, DHCP | `192.168.10.10` |
| FOG01 | FOG Project, PXE, image deployment | `192.168.10.20` |
| WIN11-TEST | Windows 11 deployment and domain client | DHCP |

## Technologies

- Windows Server 2022
- Windows 11 Pro
- Active Directory Domain Services (AD DS)
- DNS and DHCP
- Group Policy Management (GPO)
- SMB File Sharing
- NTFS Permissions
- FOG Project 1.6
- PXE / iPXE / TFTP
- Ubuntu Server
- PowerShell
- Oracle VirtualBox

## Implemented Features

### 1. Active Directory

- Created the `contoso.local` domain.
- Configured Organizational Units (OUs).
- Created and managed domain users and computer accounts.
- Joined Windows 11 clients to the domain.
- Verified domain membership and secure channel connectivity.

### 2. DNS and DHCP

- Configured the `contoso.local` DNS zone.
- Created and verified host (A), service (SRV), and reverse lookup (PTR) records.
- Configured a DHCP scope for the internal network.
- Configured DHCP options for DNS and PXE boot.
- Tested client IP address assignment and DNS resolution.

### 3. Group Policy Management

- Created and linked domain Group Policy Objects.
- Configured Microsoft Defender potentially unwanted application (PUA) protection.
- Applied computer policies to the appropriate OU.
- Verified applied policies using `gpresult`.

### 4. SMB File Server

- Created shared folders for different departments.
- Configured SMB share permissions.
- Managed NTFS permissions and inheritance.
- Practiced access control for different domain groups.

### 5. FOG Project and PXE Deployment

- Installed and configured FOG Project on Ubuntu Server.
- Configured network boot using DHCP, TFTP, and iPXE.
- Registered client machines in FOG.
- Captured a Windows 11 reference image.
- Deployed the captured image to a test machine.
- Verified the deployed Windows installation.

### 6. PowerShell Automation

- Created FOG Snapins to execute PowerShell scripts remotely.
- Built a Windows hardware and system inventory report.
- Created test tasks to verify remote script execution.

## Hardware Limitations

This lab runs on a laptop with 16 GB of RAM, which limits the number of virtual machines and the resources available to each system.

Because of these hardware constraints:

- The lab uses a limited number of simultaneously running virtual machines.
- VM memory and CPU resources are allocated carefully.
- Some services and deployment scenarios are tested sequentially rather than running all systems at once.
- The environment focuses on demonstrating core system administration concepts within limited hardware resources.

These limitations are part of the lab environment and do not reflect the full capabilities of the technologies used.

## Repository Structure

```text
fog-windows-deployment-lab/
├── README.md
├── .gitignore
├── docs/
├── scripts/
├── diagrams/
└── screenshots/
```

- `docs/` — configuration guides and technical documentation.
- `scripts/` — PowerShell scripts used in the lab.
- `diagrams/` — network architecture diagrams.
- `screenshots/` — screenshots documenting configuration and results.

## Project Status

The core lab infrastructure is configured and operational. Documentation and portfolio materials are being organized.

## Disclaimer

This is a personal educational lab running in a virtualized environment. It is designed for learning and demonstrating practical system administration skills, not for production use.

All domain names, accounts, and network configurations are used for lab purposes.
