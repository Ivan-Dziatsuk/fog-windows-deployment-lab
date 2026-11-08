# Windows Image Capture and Deployment

![Windows 11](https://img.shields.io/badge/Windows-11_Pro-0078D4?style=flat-square&logo=windows&logoColor=white)
![FOG Project](https://img.shields.io/badge/FOG_Project-1.6.0-E95420?style=flat-square)
![Image Capture](https://img.shields.io/badge/IMAGE-CAPTURE-238636?style=flat-square)
![Deployment](https://img.shields.io/badge/DEPLOYMENT-PXE-183A61?style=flat-square)

## Overview

I used two separate Windows 11 virtual machines to test image capture and deployment with FOG.

WIN11-IMAGE is the reference machine. I prepared Windows on this VM, ran Sysprep, and captured the disk image through FOG.

WIN11-TEST is the target machine used to deploy the captured image and check that Windows starts correctly.

The reference machine is kept outside the Active Directory domain. This makes it easier to prepare a clean Windows installation before capturing it.

## Image Configuration

The image was created in FOG Image Management with the following settings:

| Parameter | Value |
|---|---|
| Image Name | Windows11-Base |
| Image ID | 1 |
| Image Path | Windows11-Base |
| Image Type | Single Disk - Resizable |
| Storage Group | default |
| Source VM | WIN11-IMAGE |
| Target VM | WIN11-TEST |
| Source Operating System | Windows 11 Pro |

During image configuration, the operating system selection in the FOG interface displayed Windows 10, although the reference machine was running Windows 11 Pro. The actual captured source system was Windows 11 Pro.

## Preparing the Reference Machine

Before capturing an image, I prepared the reference Windows installation.

The preparation included:

1. Installing Windows 11 Pro.
2. Configuring basic Windows settings.
3. Installing the required software and updates.
4. Removing temporary files and unnecessary data.
5. Checking that the machine was not joined to contoso.local.
6. Checking BitLocker status.
7. Running Sysprep.
8. Shutting down the reference machine.

I kept WIN11-IMAGE outside the domain so that the captured reference installation would not contain the lab's domain membership.

### Check Computer Information

Run PowerShell as Administrator:

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

### Check Windows Version

```powershell
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber
```

### Check BitLocker Status

```powershell
Get-BitLockerVolume
```

Before imaging, make sure the operating system volume is fully decrypted.

The VolumeStatus should show FullyDecrypted. Simply suspending BitLocker protection is not the same as decrypting the drive.

Windows Hello PIN credentials should also not be treated as transferable between computers through disk imaging. Users should configure Windows Hello again on the target system when needed.

## Preparing Windows with Sysprep

Sysprep (System Preparation Tool) prepares a Windows installation for deployment to another computer.

I used the following options:

| Option | Purpose |
|---|---|
| /generalize | Removes system-specific installation information |
| /oobe | Configures Windows to start with the Out-of-Box Experience |
| /shutdown | Shuts down the computer after Sysprep finishes |

Run the command from an elevated Command Prompt:

```cmd
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown
```

After Sysprep completes, WIN11-IMAGE shuts down automatically.

**Important:** Do not start Windows normally again before capturing the image. Boot the reference machine through PXE so that FOG can execute the scheduled capture task.

## Creating the Image in FOG

Before capture, an image object must be created in FOG. This defines how the image is stored and deployed.

### Create an Image Object

1. Open the FOG management interface.
2. Navigate to Image Management.
3. Select Create New Image.
4. Enter Windows11-Base as the image name.
5. Set the image path to Windows11-Base.
6. Select the operating system entry shown in the FOG interface.
7. Choose Single Disk - Resizable.
8. Select the default storage group.
9. Save the image configuration.

### Single Disk - Resizable

I selected Single Disk - Resizable for the Windows 11 image.

This image type is designed to capture a single disk and allows supported partitions to be resized during deployment.

Deployment to a disk of a different size is subject to partition layout, filesystem support, and the space required by the image. It does not guarantee that every smaller or larger disk will work.

## Capturing the Windows Image

The capture process transfers the reference machine's disk contents to FOG01.

### Register WIN11-IMAGE

1. Start WIN11-IMAGE.
2. Select network boot.
3. Wait for the FOG boot menu.
4. Select the host registration option.
5. Complete the registration process.
6. Open FOG Management → Host Management.
7. Locate the registered reference machine.

### Assign the Image to the Host

1. Open the registered host.
2. Locate the Host Image setting.
3. Select Windows11-Base.
4. Save the configuration.

### Create a Capture Task

1. Open the reference host in Host Management.
2. Navigate to Basic Tasks.
3. Select Capture.
4. Review the task settings.
5. Create the capture task.

### Start the Capture

1. Start WIN11-IMAGE through PXE.
2. FOG detects the scheduled capture task.
3. The imaging environment starts.
4. Partclone reads the disk partitions.
5. The image is transferred to FOG01.
6. Wait for the capture process to complete.

After a successful capture, FOG stores the image on its server.

## Checking Image Storage

FOG stores the captured image under the following path:

/images/Windows11-Base

To inspect the image directory, run on FOG01:

```bash
sudo ls -lah /images/Windows11-Base
```

The captured image contains partition data and metadata files.

The following command displays the available storage capacity:

```bash
df -h
```

The Windows11-Base image was captured successfully and stored on FOG01. Its main partition image, d1p2.img, occupies approximately 8.3 GB.

## Deploying the Image to WIN11-TEST

After capturing the reference image, I used WIN11-TEST as the deployment target.

### Prepare the Target Machine

1. Shut down WIN11-TEST.
2. Check that its network adapter is connected to the internal VirtualBox network.
3. Make sure network boot is enabled.
4. Start the VM using PXE.

### Create a Deployment Task

1. Open the FOG management interface.
2. Navigate to Host Management.
3. Locate the registered target computer.
4. Open the host configuration.
5. Assign Windows11-Base to the target host if it is not already selected.
6. Navigate to Basic Tasks.
7. Select Deploy.
8. Review the task settings.
9. Create the deployment task.

### Start Deployment

1. Start or reboot WIN11-TEST.
2. Select network boot.
3. FOG detects the scheduled deployment task.
4. Partclone transfers the image to the target disk.
5. Wait for the deployment process to finish.
6. The target computer reboots.
7. Windows starts.

## Deployment Result

The Windows11-Base image was successfully deployed from FOG01 to WIN11-TEST.

This demonstrated the complete workflow:

- Preparing a Windows reference machine.
- Generalizing Windows with Sysprep.
- Capturing the disk image through FOG.
- Storing the image on the Ubuntu server.
- Deploying the image to another virtual machine.

After deployment, WIN11-TEST was also used for further Active Directory and Group Policy practice. Domain joining was performed manually as a separate administration task.

| Screenshot | Description |
|---|---|
| 22-image-deployment-pxe.png | Windows 11 image deployment through PXE network boot |
| 23-image-deployment-verification.png | PowerShell verification of the deployed Windows 11 installation |

## Summary

I used FOG Project to capture a prepared Windows 11 Pro installation from WIN11-IMAGE and deploy it to WIN11-TEST.

The image uses the Single Disk - Resizable configuration and is stored under /images/Windows11-Base on FOG01.

This part of the lab gave me practical experience with Sysprep, image management, PXE boot, disk imaging, and Windows deployment.
