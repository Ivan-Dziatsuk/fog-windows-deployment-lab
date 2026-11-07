# FOG Project Installation and Configuration

## 1. Overview

FOG Project is an open-source imaging and deployment solution used to capture, store, and deploy operating system images over a network.

In this lab, FOG is installed on an Ubuntu Server virtual machine and provides network boot and Windows deployment functionality.

### FOG Server Information

| Parameter | Value |
|---|---|
| Hostname | `FOG01` |
| Operating System | Ubuntu Server 26.04.1 LTS |
| FOG Project Version | `1.6.0-beta.5644` |
| Internal IP Address | `192.168.10.20` |
| Domain | `contoso.local` |
| Installation Type | Normal Server |
| DHCP Server | `DC01` |
| Web Interface | `https://FOG01.contoso.local/fog/management/` |

## 2. Network Configuration

FOG01 uses two network interfaces:

| Interface | Purpose | IP Address |
|---|---|---|
| NAT adapter | Internet access | DHCP |
| Internal network adapter | Communication with lab machines | `192.168.10.20` |

The internal network is:

`192.168.10.0/24`

The FOG server communicates with the domain controller and Windows clients through the internal network.

DHCP is provided by `DC01` (`192.168.10.10`), not by FOG01.

## 3. Installation Preparation

### Verify Network Configuration

Run on Ubuntu Server:

```bash
hostname
hostname -I
ip addr
ip route
```

These commands display the hostname, assigned IP addresses, network interfaces, and routing information.

The internal network interface should have the static address:

`192.168.10.20`

### Install and Verify Git

Git is used to obtain the FOG Project installation files.

```bash
git --version
```

The installed Git version in this lab was:

`2.53.0`

## 4. FOG Project Installation

### Installation Source

The installation used the official FOG Project bootstrap installer and the beta channel.

The installer was launched with:

```bash
sudo bash bootstrap.sh --channel beta
```

The exact original download command for `bootstrap.sh` is not included here because it was not preserved in the installation notes. The installation source was the official FOG Project repository.

### Installation Options

During the interactive installation, the following configuration was selected:

| Setting | Selected Value |
|---|---|
| Installation Channel | Beta |
| Installation Type | Normal Server |
| DHCP Service in FOG | No |
| Server Hostname | `FOG01` |

FOG DHCP was disabled because the lab already uses Windows DHCP Server on `DC01`.

This prevents two DHCP servers from independently assigning addresses on the same lab network.

### Installation Process

1. Obtain the official FOG bootstrap installer.
2. Run the installer using the beta channel.
3. Follow the interactive installation prompts.
4. Select Normal Server.
5. Disable the DHCP service inside the FOG installer.
6. Use `FOG01` as the server hostname.
7. Confirm the installation settings.
8. Wait for the installation to finish.

## 5. Web Interface

After installation, the FOG management interface is available at:

`https://FOG01.contoso.local/fog/management/`

The interface can also be accessed using the server's internal IP address:

`http://192.168.10.20/fog/management/`

The HTTPS hostname is preferred because it uses the configured server certificate with the hostname `FOG01.contoso.local`.

### Accessing FOG Management

1. Open a web browser.
2. Enter the FOG management URL.
3. Open the management interface.
4. Sign in using the configured FOG administrator account.

The web interface is used to manage:

- Hosts
- Images
- Storage
- Snapins
- Deployment tasks
- FOG client settings

## 6. HTTPS and Certificate Configuration

The FOG Apache web server uses certificate files located at:

```text
/etc/fog/pki/web/leaf/.webLeaf.pem
/etc/fog/pki/web/leaf/.webLeaf.key
```

The certificate includes the hostname:

`FOG01.contoso.local`

### Certificate Verification

The certificate can be inspected on Ubuntu with:

```bash
openssl x509 \
    -in /etc/fog/pki/web/leaf/.webLeaf.pem \
    -noout -subject -issuer -dates -ext subjectAltName
```

This displays the certificate subject, issuer, validity dates, and Subject Alternative Names.

A certificate trust warning on a Windows client does not necessarily mean the FOG web server is unavailable. It can indicate that the certificate's issuing CA is not trusted by that client.

## 7. Verification

### Verify FOG Server Network Configuration

```bash
hostname
hostname -I
ip addr
```

Expected internal address:

`192.168.10.20`

### Verify Apache Service

```bash
sudo systemctl status apache2
```

### Verify FOG Installation Directory

```bash
ls -la /opt/fog
```

### Verify Web Interface Response

```bash
curl -k -I https://FOG01.contoso.local/fog/management/
```

The `-k` option skips certificate trust verification. It is useful for connectivity testing, but it should not be treated as a permanent certificate security solution.

## 8. Screenshots

The following screenshots document the FOG installation and configuration:

| Screenshot | Description |
|---|---|
| `14-fog-server-network.png` | Ubuntu network configuration |
| `15-fog-installation.png` | FOG installation process |
| `16-fog-web-interface.png` | FOG management interface |
| `17-fog-server-dashboard.png` | FOG dashboard |
| `18-fog-version.png` | Installed FOG version |
| `19-fog-certificate.png` | FOG HTTPS certificate information |

## 9. Summary

FOG Project was installed on Ubuntu Server 26.04.1 LTS as the central imaging and deployment server.

The server uses the internal address `192.168.10.20` and operates alongside Windows Server 2022.

DHCP remains centralized on `DC01`, while FOG provides PXE-based network boot, image management, and Windows deployment functionality.

The installed FOG version is `1.6.0-beta.5644`.
