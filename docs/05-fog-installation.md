# FOG Project Installation and Configuration

![FOG Project](https://img.shields.io/badge/FOG_Project-1.6.0-E95420?style=flat-square)
![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-26.04.1-E95420?style=flat-square)
![Apache](https://img.shields.io/badge/Apache-2.4.66-D22128?style=flat-square)
![MariaDB](https://img.shields.io/badge/MariaDB-11.8.6-003545?style=flat-square)

## Overview

I installed FOG Project on a separate Ubuntu Server virtual machine to handle network boot and Windows deployment in the lab.

FOG is used to register computers, store operating system images, capture a prepared Windows installation, and deploy it to other machines.

The DHCP service remains on DC01. This allows Windows DHCP and FOG deployment services to operate separately.

## FOG Server

| Parameter | Value |
|---|---|
| Hostname | FOG01 |
| Operating System | Ubuntu Server 26.04.1 LTS |
| FOG Version | 1.6.0 (build 5644) |
| Installation Channel | Beta |
| Installation Type | Normal Server |
| Internal IP | 192.168.10.20 |
| Domain | contoso.local |
| DHCP Server | DC01 (192.168.10.10) |
| Installation Directory | /opt/fog |
| Image Storage | /images |
| TFTP Directory | /tftpboot |

## Network Configuration

FOG01 uses two VirtualBox network adapters.

| Interface | Purpose | IP Address |
|---|---|---|
| enp0s3 | NAT / Internet access | 10.0.2.15 |
| enp0s8 | Internal lab network | 192.168.10.20 |

The internal network uses the 192.168.10.0/24 subnet.

I use the internal adapter for communication with DC01 and the Windows clients. The NAT adapter provides internet access when required.

### Check Network Configuration

Run on Ubuntu Server:

```bash
hostname
hostname -I
ip addr
ip route
```

For a shorter overview of the interfaces:

```bash
ip -br addr
```

The internal interface should have the address 192.168.10.20.

## Installation Preparation

Before installing FOG, I checked the Ubuntu environment and installed the required tools.

### Check Operating System and Hostname

```bash
cat /etc/os-release
hostnamectl
```

The server runs Ubuntu Server 26.04.1 LTS and uses the hostname FOG01.

### Check Git

Git is used to obtain the FOG Project installation files.

```bash
git --version
```

The Git version recorded during the initial setup was 2.53.0.

## FOG Project Installation

### Installation Source

I used the official FOG Project bootstrap installer with the beta channel.

The installer was launched with:

```bash
sudo bash bootstrap.sh --channel beta
```

The original download command for bootstrap.sh was not preserved in my installation notes, so I have not included an unverified command here.

### Installation Options

During the interactive installation, I selected the following options:

| Setting | Selected Value |
|---|---|
| Installation Channel | Beta |
| Installation Type | Normal Server |
| DHCP Service in FOG | No |
| Server Hostname | FOG01 |

DHCP was disabled in the FOG installer because DC01 already provides DHCP for the internal network.

This keeps address assignment centralized and avoids having two DHCP servers independently responding to client requests on the same network.

### Installation Process

The installation followed these steps:

1. Obtain the official FOG bootstrap installer.
2. Start the installer using the beta channel.
3. Follow the interactive installation prompts.
4. Select Normal Server.
5. Disable the DHCP service in the FOG installer.
6. Use FOG01 as the server hostname.
7. Review and confirm the installation settings.
8. Wait for the installation to finish.

### Check Installation Directory

After installation, the FOG files are located in:

/opt/fog

To check the directory:

```bash
sudo ls -ld /opt/fog
```

The installation directory exists on FOG01.

## Web Interface

The FOG management interface is used to manage hosts, images, storage, Snapins, and deployment tasks.

The management page is available at:

**HTTPS:**

https://FOG01.contoso.local/fog/management/

**HTTP:**

http://192.168.10.20/fog/management/

To access the interface:

1. Open a web browser.
2. Enter the FOG management address.
3. Open the management interface.
4. Sign in using the configured FOG administrator account.

### Apache Web Server

Apache provides the FOG web interface.

To check its status:

```bash
sudo systemctl status apache2 --no-pager
```

The latest audit confirmed:

- Apache version: 2.4.66
- Service status: active (running)

### Check the Web Interface

Run locally on FOG01:

```bash
curl -I http://127.0.0.1/fog/management/
```

The latest audit returned:

```text
HTTP/1.1 200 OK
```

This confirms that Apache successfully serves the FOG management page through local HTTP.

## HTTPS and Certificate

The original installation notes identify the following certificate files:

```text
/etc/fog/pki/web/leaf/.webLeaf.pem
/etc/fog/pki/web/leaf/.webLeaf.key
```

The certificate is documented as containing the hostname:

FOG01.contoso.local

### Inspect the Certificate

The certificate information can be displayed with:

```bash
openssl x509 \
    -in /etc/fog/pki/web/leaf/.webLeaf.pem \
    -noout -subject -issuer -dates -ext subjectAltName
```

This displays the subject, issuer, validity dates, and Subject Alternative Names.

A certificate warning in a Windows browser does not necessarily mean that the web server is unavailable. The client may simply not trust the certificate's issuing authority.

The successful HTTP test does not by itself confirm HTTPS connectivity or certificate trust.

To test HTTPS connectivity while skipping certificate validation:

```bash
curl -k -I https://FOG01.contoso.local/fog/management/
```

The -k option is useful for testing connectivity, but it should not replace proper certificate trust configuration.

## TFTP and PXE Configuration

TFTP (Trivial File Transfer Protocol) provides the initial network boot file to PXE clients.

The TFTP service runs on FOG01.

### Check TFTP Service

```bash
sudo systemctl status tftpd-hpa --no-pager
```

The latest audit confirmed that the service is active and running.

### TFTP Configuration

The configuration is stored in:

/etc/default/tftpd-hpa

To display the relevant settings:

```bash
sudo grep -E 'TFTP_DIRECTORY|TFTP_ADDRESS|TFTP_USERNAME' /etc/default/tftpd-hpa
```

The current configuration is:

```text
TFTP_USERNAME="root"
TFTP_DIRECTORY="/tftpboot"
TFTP_ADDRESS=":69"
```

The service uses port 69 and the /tftpboot directory.

The TFTP service currently runs under the root account. This is the observed lab configuration, not a general security recommendation.

### Check the PXE Boot File

The boot file used in this lab is:

/tftpboot/undionly.kpxe

Check whether it exists:

```bash
sudo ls -lh /tftpboot/undionly.kpxe
```

The file was present during the latest audit.

## MariaDB Database

MariaDB is used by FOG to store its database information.

To check the service:

```bash
sudo systemctl status mariadb --no-pager
```

The latest audit confirmed:

- MariaDB version: 11.8.6
- Service status: active (running)
- Database server ready to accept connections.

## Image Storage

FOG stores captured operating system images under:

/images

The directory contains the storage marker and the image directories.

### Check Storage Capacity

```bash
df -h
```

During the latest audit, the Ubuntu root filesystem had the following capacity:

| Parameter | Value |
|---|---|
| Filesystem | /dev/sda2 |
| Total Size | 98 GB |
| Used Space | 14 GB |
| Available Space | 79 GB |
| Usage | 16% |

### Check the Image Storage Directory

```bash
sudo ls -lah /images
```

The following directories were present:

```text
/images
/images/Windows11-Base
/images/dev
/images/postdownloadscripts
```

The storage marker .mntcheck was also present.

### Windows11-Base Image

The lab contains a captured Windows 11 image named Windows11-Base.

Image directory:

/images/Windows11-Base

To inspect its contents:

```bash
sudo ls -lah /images/Windows11-Base
```

The directory contains the following image and metadata files:

```text
d1.fixed_size_partitions
d1.mbr
d1.minimum.partitions
d1.original.fstypes
d1.original.swapuuids
d1.partitions
d1p1.img
d1p2.img
d1p3.img
```

The main partition image, d1p2.img, occupies approximately 8.3 GB.

### Development Storage Directory

FOG also has a development directory:

/images/dev

Its contents were checked during the audit:

```bash
sudo ls -lah /images/dev
```

The directory contains:

```text
.mntcheck
postinitscripts
```

## Service and Installation Checks

These are the main commands I used to inspect the installed FOG environment.

| Command | Purpose |
|---|---|
| cat /etc/os-release | Check Ubuntu version |
| hostnamectl | Check hostname and virtualization |
| ip -br addr | Display network interfaces |
| sudo systemctl status apache2 | Check Apache |
| sudo systemctl status mariadb | Check MariaDB |
| sudo systemctl status tftpd-hpa | Check TFTP |
| curl -I http://127.0.0.1/fog/management/ | Check local web response |
| sudo ls -ld /opt/fog | Check FOG installation directory |
| sudo ls -lh /tftpboot/undionly.kpxe | Check PXE boot file |
| sudo ls -lah /images | Check image storage |
| df -h | Check available disk space |

## Screenshots

The following screenshots document the initial FOG installation and configuration.

| Screenshot | Description |
|---|---|
| 14-fog-server-network.png | Ubuntu network configuration |
| 15-fog-installation.png | FOG installation process |
| 16-fog-web-interface.png | FOG management interface |
| 17-fog-server-dashboard.png | FOG dashboard |
| 18-fog-version.png | Installed FOG version |
| 19-fog-certificate.png | FOG HTTPS certificate information |

Only include screenshots that actually exist in the repository.

## Summary

FOG Project is installed on Ubuntu Server 26.04.1 LTS and runs as the deployment server in the lab.

DC01 remains responsible for DHCP, while FOG01 handles TFTP, PXE boot, image storage, and Windows deployment.

The latest audit confirmed that Apache, MariaDB, and TFTP are running, the local FOG management page returns HTTP 200, the PXE boot file exists, and the Windows11-Base image is stored on the server.

The environment uses FOG Project 1.6.0, build 5644, installed through the beta channel.
