# Windows Image Capture and Deployment

## 1. Overview

This section documents the preparation of a Windows 11 reference machine, capturing its disk image with FOG Project, and deploying that image to another virtual machine.

The lab uses two separate Windows virtual machines:

- `WIN11-IMAGE` — reference machine used to prepare and capture the Windows image.
- `WIN11-TEST` — target virtual machine used to test image deployment.

The reference machine is not joined to the Active Directory domain.

## 2. Lab Image Information

### FOG Image Configuration

| Parameter | Value |
|---|---|
| Image Name | `Windows11-Base` |
| Image ID | `1` |
| Image Path | `Windows11-Base` |
| Image Type | Single Disk - Resizable |
| Storage Group | `default` |
| Source VM | `WIN11-IMAGE` |
| Target VM | `WIN11-TEST` |
| Operating System | Windows 11 Pro |

### Virtual Machine Roles

| Virtual Machine | Purpose |
|---|---|
| WIN11-IMAGE | Windows reference image preparation and capture |
| WIN11-TEST | Deployment testing |

`WIN11-IMAGE` is kept separate from the domain environment to provide a clean reference system.

## 3. Reference Machine Preparation

Before capturing an image, the reference machine must be prepared.

### Preparation Checklist

1. Install Windows 11 Pro.
2. Configure basic Windows settings.
3. Install required software and updates.
4. Remove temporary files and unnecessary data.
5. Verify that the system is not joined to `contoso.local`.
6. Make sure BitLocker encryption is fully disabled or the drive is fully decrypted before imaging.
7. Prepare Windows using Sysprep.
8. Shut down the reference machine.

BitLocker and Windows Hello requirements are important because the FOG imaging environment may not be able to capture encrypted partitions, and a Windows Hello PIN cannot be transferred as part of an image.

### Verify Computer Information

Run PowerShell as Administrator:

```powershell
Get-CimInstance Win32_ComputerSystem |
    Select-Object Name, Domain, PartOfDomain
```

### Verify Windows Version

```powershell
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber
```

### Verify BitLocker Status

```powershell
Get-BitLockerVolume
```

Check the operating system volume and verify that it is fully decrypted before capturing the image.

## 4. Sysprep Preparation

Sysprep (System Preparation Tool) prepares a Windows installation for deployment to other computers.

The `/generalize` option removes system-specific information so that Windows can be initialized on another machine.

The `/oobe` option configures Windows to start in the Out-of-Box Experience.

The `/shutdown` option shuts down the computer after Sysprep completes.

### Example Sysprep Command

Run in an elevated Command Prompt:

```cmd
C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown
```

After Sysprep completes, the reference machine shuts down.

Do not boot the reference Windows installation normally again before the capture task. Start it using network boot.

## 5. FOG Image Configuration

The image object defines how FOG stores and deploys the operating system image.

### Create an Image Object

In the FOG management interface:

1. Open the FOG web management interface.
2. Navigate to Image Management.
3. Select Create New Image.
4. Enter the image name: `Windows11-Base`.
5. Configure the image path: `Windows11-Base`.
6. Select the Windows 11 operating system entry matching the source machine.
7. Select `Single Disk - Resizable`.
8. Select the `default` storage group.
9. Save the image configuration.

### Image Type: Single Disk - Resizable

This image type captures partitions from a single disk and supports resizing partitions during deployment when the filesystem allows it.

It can make deployment to a smaller or larger destination disk possible, subject to the source and destination disk layout and filesystem requirements.

## 6. Image Capture

Image capture transfers the contents of the reference machine's disk to the FOG server.

### Register the Reference Machine

1. Start `WIN11-IMAGE`.
2. Select network boot.
3. Wait for the FOG boot menu.
4. Select the host registration option.
5. Complete the registration process.
6. Open FOG Management → Host Management.
7. Locate the registered reference host.

### Associate the Image with the Host

1. Open the registered reference host.
2. Locate the Host Image setting.
3. Select `Windows11-Base`.
4. Save the host configuration.

### Create a Capture Task

1. Open the reference host in FOG Host Management.
2. Navigate to Basic Tasks.
3. Select Capture.
4. Review the task settings.
5. Create the capture task.

### Execute the Capture

1. Start `WIN11-IMAGE`.
2. Select network boot.
3. FOG detects the scheduled capture task.
4. The imaging environment starts.
5. Partclone reads the disk partitions and transfers the image to FOG.
6. Wait for the capture process to complete.

After a successful capture, the image is stored on the FOG server.

### Important Warning

A new capture using the same image object can overwrite the previously stored image files.

Verify the selected image before creating a capture task.

## 7. Image Storage Verification

FOG stores image files on its storage node.

The configured image path is:

`Windows11-Base`

The default FOG image storage directory is:

`/images`

### Verify Image Directory

Run on `FOG01`:

```bash
sudo ls -lah /images/Windows11-Base
```

This command checks whether the image directory exists and displays its contents.

### Verify Storage Capacity

```bash
df -h
```

This displays filesystem capacity and available storage space.

## 8. Image Deployment

Image deployment transfers the stored Windows image from FOG to a target computer.

In this lab, the target is `WIN11-TEST`.

### Prepare the Target Machine

1. Shut down `WIN11-TEST`.
2. Verify that its network adapter is connected to the lab's internal network.
3. Verify that network boot is enabled.
4. Start the virtual machine using PXE.

### Create a Deployment Task

1. Open the FOG web interface.
2. Navigate to Host Management.
3. Locate the registered target host.
4. Open the host configuration.
5. Associate the `Windows11-Base` image with the target host, if it is not already assigned.
6. Open Basic Tasks.
7. Select Deploy.
8. Review the task settings.
9. Create the deployment task.

### Execute Deployment

1. Start or reboot `WIN11-TEST`.
2. Select network boot.
3. FOG detects the scheduled deployment task.
4. Partclone starts transferring the image to the target disk.
5. Wait for the deployment process to finish.
6. The target computer reboots.
7. Windows starts
