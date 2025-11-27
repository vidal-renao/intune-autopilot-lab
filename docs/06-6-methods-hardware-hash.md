# 6 Methods to Extract Hardware Hash for Windows Autopilot

> **Complete professional guide for hardware hash extraction in enterprise environments**

## 📋 Table of Contents

- [Overview](#overview)
- [Comparison Table](#comparison-table)
- [Method 1: OOBE Extraction](#method-1-oobe-extraction-shiftf10)
- [Method 2: Installed Windows](#method-2-installed-windows-system)
- [Method 3: OEM/Manufacturer Registration](#method-3-oemmanufacturer-registration)
- [Method 4: USB Provisioning Package](#method-4-usb-provisioning-package)
- [Method 5: Automated Script for Multiple Devices](#method-5-automated-script-for-multiple-devices)
- [Method 6: From Intune Portal](#method-6-extract-from-intune-enrolled-devices)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

Windows Autopilot requires a **hardware hash** (also called hardware ID) to identify and register devices. This unique identifier allows Autopilot to recognize a device and apply the correct deployment profile during OOBE (Out-of-Box Experience).

### What is a Hardware Hash?

A hardware hash is a unique identifier generated from:
- Device serial number
- MAC address
- Disk serial number
- TPM information
- Other hardware identifiers

### When to Use Each Method

| Scenario | Best Method |
|----------|-------------|
| New device, not yet configured | Method 1 (OOBE) |
| Device already running Windows | Method 2 (Installed) |
| Corporate purchase (Dell, HP, Lenovo) | Method 3 (OEM) |
| Mass deployment on-site | Method 4 (USB) |
| Migrating 50+ existing devices | Method 5 (Automated) |
| Device already in Intune | Method 6 (From Intune) |

---

## Comparison Table

| Method | Difficulty | Time/Device | Best For | Enterprise Usage |
|--------|-----------|-------------|----------|------------------|
| **1. OOBE** | ⭐⭐⭐⭐ Hard | 10-15 min | Single new PCs | 4% |
| **2. Installed Windows** | ⭐⭐ Easy | 5 min | Labs, VMs, existing PCs | 15% |
| **3. OEM Registration** | ⭐ Very Easy | 0 min (automatic) | Corporate purchases | **80%** |
| **4. USB Provisioning** | ⭐⭐⭐ Medium | 15 min setup + 5 min/device | On-site mass deployment | 1% |
| **5. Automated Script** | ⭐⭐⭐ Medium | 30 min setup, then automatic | Large existing fleet | 10% |
| **6. From Intune** | ⭐ Very Easy | 2 min | Already enrolled devices | 5% |

---

## Method 1: OOBE Extraction (Shift+F10)

### Overview
Extract hardware hash during Windows Out-of-Box Experience (OOBE) before any configuration is done.

### When to Use
- Brand new device
- Fresh Windows installation
- Device hasn't been set up yet
- Want to maintain "factory fresh" state

### Prerequisites
- Device at Windows language selection screen
- Access to keyboard
- USB drive (to extract CSV file)
- Network connectivity (for script download)

### Step-by-Step Process

#### Step 1: Access Command Prompt
1. Power on the device
2. Wait for Windows OOBE (language selection screen)
3. Press **Shift + F10** simultaneously
4. Command Prompt window opens

> **💡 Tip**: On some laptops, use **Fn + Shift + F10**

#### Step 2: Navigate to PowerShell
Since PowerShell is not in the PATH during OOBE, use the full path:

```cmd
cd \Windows\System32\WindowsPowerShell\v1.0
```

#### Step 3: Launch PowerShell
```cmd
.\PowerShell.exe
```

**✅ Success indicator**: Prompt changes from `X:\Sources>` to `PS X:\Sources>`

#### Step 4: Install Autopilot Script
```powershell
Install-Script -Name Get-WindowsAutopilotInfo -Force
```

**Possible prompts:**
- "NuGet provider is required" → Type **Y** and press Enter
- "Untrusted repository" → Type **Y** and press Enter

#### Step 5: Extract Hardware Hash
```powershell
Get-WindowsAutopilotInfo -OutputFile C:\AutopilotHWID.csv
```

**Output location**: `C:\AutopilotHWID.csv`

#### Step 6: Extract the CSV File

**Option A - USB Drive:**
1. Insert USB drive
2. Copy file from C:\ to USB

**Option B - Complete Windows Setup:**
1. Continue with Windows setup
2. Once in Windows, upload to OneDrive or email

#### Step 7: Import to Intune
1. Go to **https://intune.microsoft.com**
2. Navigate to **Devices → Windows → Windows enrollment → Devices**
3. Click **Import**
4. Select `AutopilotHWID.csv`
5. Wait 15-20 minutes for sync

### Pros & Cons

**✅ Advantages:**
- Device stays "factory fresh"
- No Windows configuration needed
- Immediate Autopilot readiness

**❌ Disadvantages:**
- Complex commands and paths
- Easy to make syntax errors
- Requires network connectivity
- PowerShell not in PATH
- Difficult for non-technical users

### Troubleshooting

**Problem**: `PowerShell.exe is not recognized`
```powershell
# Solution: Use full path
cd \Windows\System32\WindowsPowerShell\v1.0
.\PowerShell.exe
```

**Problem**: Script download fails
```powershell
# Solution: Check network connectivity
Test-NetConnection google.com
```

---

## Method 2: Installed Windows System

### Overview
Extract hardware hash from a device already running Windows. **BEST METHOD FOR LABS AND TESTING.**

### When to Use
- Device already has Windows installed
- Lab environments
- Virtual machines
- Testing Autopilot
- Existing devices to migrate

### Prerequisites
- Windows 10/11 already installed
- Administrator access
- Internet connectivity

### Step-by-Step Process

#### Step 1: Open PowerShell as Administrator

**Method A (Recommended):**
1. Press **Windows key**
2. Type: `powershell`
3. Right-click **"Windows PowerShell"**
4. Select **"Run as administrator"**

**Method B:**
1. Right-click **Start button**
2. Select **"Terminal (Admin)"** or **"Windows PowerShell (Admin)"**

> **⚠️ CRITICAL**: Must use "Run as administrator" - regular PowerShell won't work!

#### Step 2: Set Execution Policy (if needed)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

#### Step 3: Install Autopilot Script
```powershell
Install-Script -Name Get-WindowsAutopilotInfo -Force
```

**Possible prompts:**
- NuGet provider: Type **Y**
- PSGallery trust: Type **Y**

#### Step 4: Extract Hardware Hash to Desktop
```powershell
Get-WindowsAutopilotInfo -OutputFile $env:USERPROFILE\Desktop\AutopilotHWID.csv
```

**✅ Success**: File appears on Desktop named `AutopilotHWID.csv`

#### Step 5: Upload to Intune
1. Go to **https://intune.microsoft.com**
2. **Devices → Windows → Windows enrollment → Devices**
3. Click **Import**
4. Select the CSV from Desktop
5. Wait 15-20 minutes for sync

#### Step 6: Reset Device for Autopilot
To trigger Autopilot on next boot:

**Via Settings:**
1. **Settings → System → Recovery**
2. Click **"Reset this PC"**
3. Choose **"Remove everything"**
4. Select **"Cloud download"** (recommended)
5. Confirm and reset

**Via PowerShell:**
```powershell
systemreset -cleanpc
```

**✅ Result**: On next boot, device uses Autopilot automatically!

### Alternative Output Locations

```powershell
# Save to specific location
Get-WindowsAutopilotInfo -OutputFile "C:\Temp\AutopilotHWID.csv"

# Save to network share
Get-WindowsAutopilotInfo -OutputFile "\\server\share\AutopilotHWID.csv"

# Include group tag
Get-WindowsAutopilotInfo -OutputFile .\hash.csv -GroupTag "Finance-Dept"
```

### Pros & Cons

**✅ Advantages:**
- Very simple and straightforward
- PowerShell easily accessible
- No complex paths needed
- Perfect for testing and labs
- File saves to Desktop automatically
- Can test on VMs

**❌ Disadvantages:**
- Need to install Windows first (~15 minutes)
- Requires device Reset after import
- Total time ~30 minutes (including reset)

### Troubleshooting

**Problem**: "Install-Script is not recognized"
```powershell
# Solution: Update PowerShellGet
Install-Module -Name PowerShellGet -Force -AllowClobber
# Close and reopen PowerShell as Admin
```

**Problem**: Script executes but no CSV created
```powershell
# Solution: Check you're running as Administrator
# Verify with:
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# Should return: True
```

---

## Method 3: OEM/Manufacturer Registration

### Overview
For corporate device purchases, manufacturers can automatically register devices to your Autopilot tenant. **MOST USED IN ENTERPRISE (80%).**

### When to Use
- Buying devices from Dell, HP, Lenovo, Microsoft Surface
- Corporate purchasing accounts
- Large-scale deployments (10+ devices)
- Want zero IT effort

### Supported OEMs
- ✅ Dell
- ✅ HP
- ✅ Lenovo
- ✅ Microsoft Surface
- ✅ Acer
- ✅ ASUS
- ✅ Panasonic
- ✅ Toshiba

### Prerequisites
- Corporate purchasing account with OEM
- Microsoft 365 tenant
- Intune licenses

### Step-by-Step Process

#### Step 1: Register with OEM Partner Program

**Dell:**
- Create **Dell Premier Account**
- Enable **Autopilot Service**
- Contact: dell.com/autopilot

**HP:**
- Sign up for **HP TechPulse**
- Enable Autopilot registration
- Contact: hp.com/techpulse

**Lenovo:**
- Access **Lenovo Services Portal**
- Enable Autopilot integration
- Contact: support.lenovo.com

**Microsoft Surface:**
- Use **Surface Partner Portal**
- Automatic for qualified partners

#### Step 2: Link Your Microsoft Tenant

Provide to OEM:
```yaml
Tenant Information:
  - Tenant ID: [Find in Entra ID → Overview]
  - Tenant Domain: yourcompany.onmicrosoft.com
  - Admin Email: admin@yourcompany.onmicrosoft.com
  - Company Name: Your Company Inc.
```

**To find Tenant ID:**
1. Go to **https://entra.microsoft.com**
2. **Overview** → Copy **Tenant ID**

#### Step 3: Place Your Order

When ordering devices, specify:
- ✅ Enable Autopilot registration
- ✅ Provide Tenant ID
- ✅ Request pre-provisioning (if available)

Example order note:
```
Please register all devices to Windows Autopilot:
Tenant ID: 12345678-1234-1234-1234-123456789012
Tenant: company.onmicrosoft.com
```

#### Step 4: Automatic Registration

OEM automatically:
1. Extracts hardware hash during manufacturing
2. Uploads to Microsoft Autopilot service
3. Links to your tenant
4. Assigns to your deployment profile

**Timeline**: Usually 1-3 business days after shipping

#### Step 5: Verify in Intune

Before devices arrive:
1. Go to **Intune → Devices → Windows enrollment → Devices**
2. Verify devices appear in list
3. Check status: **"Assigned"**

#### Step 6: Deploy to End Users

Simply:
1. Ship device to user (still in box)
2. User powers on
3. Autopilot starts automatically
4. User signs in with corporate credentials
5. Device configures itself

**✅ ZERO TOUCH DEPLOYMENT!**

### OEM Contact Information

| Manufacturer | Service | URL |
|--------------|---------|-----|
| **Dell** | Dell Premier | dell.com/autopilot |
| **HP** | HP TechPulse | hp.com/techpulse |
| **Lenovo** | Services Portal | support.lenovo.com |
| **Surface** | Partner Center | partner.microsoft.com |

### Pros & Cons

**✅ Advantages:**
- Zero manual work required
- Completely automatic
- Works at scale (hundreds/thousands)
- Devices arrive ready for Autopilot
- No technical skills needed
- No chance of human error

**❌ Disadvantages:**
- Only works with OEM partnerships
- Requires corporate purchasing accounts
- Not available for consumer purchases
- Vendor-specific processes
- May have minimum order quantities

### Cost Considerations

Most OEMs offer this service:
- **Free** for enterprise customers
- May require minimum purchase volume
- Included in corporate pricing
- No per-device fees

---

## Method 4: USB Provisioning Package

### Overview
Create a USB drive with a provisioning package that extracts and registers devices during OOBE.

### When to Use
- On-site mass deployment
- Technician in the field
- Multiple devices to register
- No network connectivity
- Reusable solution needed

### Prerequisites
- Windows 10/11 PC
- Windows Configuration Designer
- USB drive (8GB+)
- Bulk enrollment token from Intune

### Step-by-Step Process

#### Step 1: Install Windows Configuration Designer

**Option A - Microsoft Store:**
Search for "Windows Configuration Designer" and install

**Option B - winget:**
```powershell
winget install Microsoft.WindowsConfigurationDesigner
```

**Option C - Download:**
https://www.microsoft.com/store/productId/9NBLGGH4TX22

#### Step 2: Get Bulk Enrollment Token

1. Go to **Intune → Devices → Windows → Windows enrollment**
2. Click **Enrollment Program Tokens**
3. Click **Add**
4. Download the **.ppkg** file

#### Step 3: Create Provisioning Package

1. Open **Windows Configuration Designer**
2. Click **"Provision desktop devices"**
3. Enter project name: `AutopilotUSB`
4. Click **Next**

**Configure settings:**
```yaml
Project Settings:
  Name: AutopilotUSB
  
Device Information:
  Device Name: (leave blank for Autopilot template)
  
Network:
  WiFi: (optional - add company WiFi)
  
Enrollment:
  Enroll in Azure AD: Yes
  Bulk Token: [Browse to downloaded token]
  
Applications:
  (optional - add apps)
  
Security:
  Remove pre-installed software: Yes (optional)
```

#### Step 4: Build Package

1. Click **Create**
2. Choose export location
3. Package builds as **.ppkg** file

#### Step 5: Prepare USB Drive

1. Format USB drive (FAT32)
2. Copy `.ppkg` file to USB root
3. Label USB: "Autopilot Provisioning"

#### Step 6: Use on Devices

**On each new device:**
1. Boot to Windows OOBE
2. Insert USB drive
3. Press **Windows key** 5 times quickly
4. Provisioning package detected
5. Select the package
6. Click **"Yes, add it"**
7. Device auto-enrolls to Autopilot

**✅ Result**: Device registers and applies Autopilot profile

### Advanced Options

#### Include Group Tags
```powershell
# In Configuration Designer
Settings → Runtime settings → Azure → Autopilot → GroupTag
Value: "Finance-Department"
```

#### Multiple Profiles
Create separate packages for:
- Executive devices
- Standard employees
- Kiosk devices
- Different departments

### Pros & Cons

**✅ Advantages:**
- Reusable USB for multiple devices
- Works during OOBE
- No complex commands
- Good for field technicians
- Can include WiFi credentials

**❌ Disadvantages:**
- Initial setup is complex
- Must update USB for new tenants
- Physical USB required
- Token expires (needs renewal)

### Troubleshooting

**Problem**: Package not detected
- Solution: Ensure .ppkg is in USB root (not in folder)
- Format USB as FAT32 (not NTFS or exFAT)

**Problem**: Token expired
- Solution: Generate new token in Intune
- Rebuild provisioning package

---

## Method 5: Automated Script for Multiple Devices

### Overview
Deploy PowerShell script via Intune to extract hashes from many devices automatically.

### When to Use
- Migrating 50+ existing devices
- Devices already in Intune (MDM only)
- Remote hash collection
- No physical access to devices

### Prerequisites
- Devices enrolled in Intune (MDM)
- Network share or Azure Storage
- Intune Remediation Scripts license

### Step-by-Step Process

#### Step 1: Create Detection Script

Save as `Detect-AutopilotHash.ps1`:

```powershell
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Detection script for Autopilot hash
.DESCRIPTION
    Checks if hardware hash has been collected
#>

$hashPath = "$env:ProgramData\AutopilotHash.csv"

if (Test-Path $hashPath) {
    Write-Host "Hash already collected"
    exit 0  # Compliant
} else {
    Write-Host "Hash not found"
    exit 1  # Non-compliant, trigger remediation
}
```

#### Step 2: Create Remediation Script

Save as `Remediate-AutopilotHash.ps1`:

```powershell
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Remediation script to collect Autopilot hash
.DESCRIPTION
    Extracts hardware hash and uploads to network share
#>

# Configuration
$SharePath = "\\server\AutopilotHashes"
$LocalPath = "$env:ProgramData\AutopilotHash.csv"

try {
    # Install script if not present
    $scriptInstalled = Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue
    
    if (-not $scriptInstalled) {
        Write-Host "Installing Autopilot script..."
        Install-Script -Name Get-WindowsAutopilotInfo -Force -ErrorAction Stop
    }
    
    # Extract hardware hash
    Write-Host "Extracting hardware hash..."
    Get-WindowsAutopilotInfo -OutputFile $LocalPath -ErrorAction Stop
    
    # Upload to network share
    if (Test-Path $SharePath) {
        $fileName = "$env:COMPUTERNAME-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $remotePath = Join-Path $SharePath $fileName
        Copy-Item -Path $LocalPath -Destination $remotePath -Force -ErrorAction Stop
        Write-Host "Hash uploaded to $remotePath"
    }
    
    # Alternative: Upload to Azure Blob Storage
    # $storageAccount = "yourstorageaccount"
    # $containerName = "autopilot-hashes"
    # $sasToken = "YOUR_SAS_TOKEN"
    # $blobUrl = "https://$storageAccount.blob.core.windows.net/$containerName/$fileName$sasToken"
    # Invoke-RestMethod -Uri $blobUrl -Method Put -InFile $LocalPath
    
    Write-Host "Hash collection completed successfully"
    exit 0
    
} catch {
    Write-Error "Failed to collect hash: $_"
    exit 1
}
```

#### Step 3: Deploy via Intune

1. Go to **Intune → Devices → Scripts and remediations**
2. Click **Create** → **Remediation script**
3. Configure:

```yaml
Name: Collect Autopilot Hardware Hash
Description: Automatically extract and upload hardware hashes

Detection script: Detect-AutopilotHash.ps1
Remediation script: Remediate-AutopilotHash.ps1

Settings:
  Run this script using logged on credentials: No
  Enforce script signature check: No
  Run script in 64-bit PowerShell: Yes
  
Schedule:
  Run script: Daily
  Time: 2:00 AM
  
Assignment:
  Include: All Devices
  (or specific group of devices to migrate)
```

4. Click **Create**

#### Step 4: Monitor Execution

1. **Intune → Reports → Device health → Remediation script status**
2. View:
   - Devices detected
   - Remediation success/failure
   - Error messages

#### Step 5: Collect and Import Hashes

1. Access network share or Azure Storage
2. Download all CSV files
3. Merge CSVs (or import individually)
4. Import to Intune:
   - **Devices → Windows enrollment → Devices → Import**
   - Select merged CSV
   - Wait for sync

### Advanced: Merge Multiple CSVs

```powershell
# PowerShell script to merge multiple Autopilot CSVs

$sourcePath = "\\server\AutopilotHashes"
$outputFile = "C:\Temp\MergedAutopilotHashes.csv"

# Get all CSV files
$csvFiles = Get-ChildItem -Path $sourcePath -Filter "*.csv"

# Merge all CSVs
$allData = @()
foreach ($file in $csvFiles) {
    $data = Import-Csv -Path $file.FullName
    $allData += $data
}

# Remove duplicates based on Serial Number
$uniqueData = $allData | Sort-Object -Property "Device Serial Number" -Unique

# Export merged file
$uniqueData | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "Merged $($csvFiles.Count) files into $outputFile"
Write-Host "Total unique devices: $($uniqueData.Count)"
```

### Pros & Cons

**✅ Advantages:**
- Handles hundreds of devices
- No physical access needed
- Runs automatically
- Centralized collection
- Can schedule during off-hours

**❌ Disadvantages:**
- Requires Intune enrollment first
- Network share or Azure Storage needed
- Initial script setup complexity
- Requires scripting knowledge

---

## Method 6: Extract from Intune-Enrolled Devices

### Overview
For devices already enrolled in Intune (MDM only), extract hardware hash directly from Intune portal or via Graph API.

### When to Use
- Device already in Intune (MDM only, not Autopilot)
- Want to convert MDM to Autopilot
- Need to re-register device
- Lost original hash

### Prerequisites
- Device enrolled in Intune
- Device must be online
- Admin access to Intune

### Method A: Via Intune Portal (Manual)

#### Step 1: Navigate to Device
1. Go to **https://intune.microsoft.com**
2. **Devices → All devices**
3. Find and click the device

#### Step 2: Find Hardware Information
1. Scroll to **Hardware** section
2. Look for **"Hardware hash"** or **"Windows Autopilot"**
3. Copy the hash value

> **⚠️ Note**: Not all devices show this information directly

### Method B: Via Graph API (Programmatic)

#### Step 1: Install Microsoft Graph PowerShell

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

#### Step 2: Connect to Graph

```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
```

#### Step 3: Get Device Information

```powershell
# Get specific device
$deviceName = "LAB-12345"
$device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'"

# Display hardware information
$device | Select-Object deviceName, serialNumber, azureADDeviceId, id

# Get hardware hash (if available)
$hardwareInfo = Get-MgDeviceManagementManagedDeviceHardwareInformation -ManagedDeviceId $device.Id
```

#### Step 4: Register to Autopilot

```powershell
# Create Autopilot device identity
$autopilotDevice = @{
    serialNumber = $device.serialNumber
    hardwareIdentifier = $hardwareInfo.deviceIdentifier
    groupTag = "ConvertedFromMDM"
}

# Register to Autopilot
New-MgDeviceManagementWindowsAutopilotDeviceIdentity -BodyParameter $autopilotDevice
```

### Method C: PowerShell Script for Bulk Conversion

```powershell
<#
.SYNOPSIS
    Convert Intune MDM devices to Autopilot
.DESCRIPTION
    Extracts hardware hashes from Intune and registers to Autopilot
#>

#Requires -Modules Microsoft.Graph

# Connect
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All", `
                        "DeviceManagementServiceConfig.ReadWrite.All"

# Get all Windows devices not in Autopilot
$allDevices = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'"
$autopilotDevices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity

$devicesToConvert = $allDevices | Where-Object {
    $_.serialNumber -notin $autopilotDevices.serialNumber
}

Write-Host "Found $($devicesToConvert.Count) devices to convert"

# Process each device
foreach ($device in $devicesToConvert) {
    try {
        Write-Host "Processing: $($device.deviceName)"
        
        # Get hardware info
        $hwInfo = Get-MgDeviceManagementManagedDeviceHardwareInformation -ManagedDeviceId $device.Id
        
        # Register to Autopilot
        $autopilotDevice = @{
            serialNumber = $device.serialNumber
            hardwareIdentifier = $hwInfo.deviceIdentifier
            groupTag = "MDM-Converted"
        }
        
        New-MgDeviceManagementWindowsAutopilotDeviceIdentity -BodyParameter $autopilotDevice
        
        Write-Host "✅ Successfully registered: $($device.deviceName)" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to register: $($device.deviceName) - $_" -ForegroundColor Red
    }
}

Write-Host "`nConversion complete!"
```

### Pros & Cons

**✅ Advantages:**
- No device access needed
- Works remotely
- Instant registration
- Good for already-managed devices

**❌ Disadvantages:**
- Only for Intune-enrolled devices
- Requires Graph API knowledge
- Hardware hash not always available
- One device at a time (manual method)

---

## Troubleshooting

### Common Issues Across All Methods

#### Issue 1: "Install-Script: The term 'Install-Script' is not recognized"

**Cause**: PowerShellGet module not installed or outdated

**Solution**:
```powershell
# Update PowerShellGet
Install-Module -Name PowerShellGet -Force -AllowClobber

# Close and reopen PowerShell as Administrator
```

#### Issue 2: Execution Policy Errors

**Cause**: PowerShell execution policy blocking scripts

**Solution**:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

#### Issue 3: CSV Import Fails in Intune

**Causes**:
- Incorrect CSV format
- Duplicate serial numbers
- Missing required fields

**Solution**:
```powershell
# Verify CSV structure
Import-Csv .\AutopilotHWID.csv | Format-Table

# Required columns:
# - Device Serial Number
# - Windows Product ID
# - Hardware Hash
```

#### Issue 4: Device Not Showing in Autopilot After Import

**Cause**: Sync delay or group membership issues

**Solution**:
1. Wait 15-20 minutes for initial sync
2. Force sync: **Intune → Devices → Sync**
3. Check dynamic group rules
4. Verify device has valid license

#### Issue 5: PowerShell Script Download Fails

**Cause**: Network connectivity or firewall

**Solution**:
```powershell
# Test connectivity
Test-NetConnection packages.microsoft.com -Port 443

# Try alternative download
Invoke-WebRequest -Uri "https://www.powershellgallery.com/api/v2/package/Get-WindowsAutopilotInfo" -OutFile "autopilot.nupkg"
```

### Method-Specific Issues

#### OOBE Method Issues

**Problem**: Shift+F10 doesn't work
- Try: Fn + Shift + F10
- Try: Interrupt boot 3 times to access recovery

**Problem**: PowerShell path not found
- Use exact path: `\Windows\System32\WindowsPowerShell\v1.0`
- Don't forget the `.\` before PowerShell.exe

#### Installed Windows Issues

**Problem**: Not running as Administrator
```powershell
# Check admin status
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```

**Problem**: CSV not appearing on Desktop
- Check: `$env:USERPROFILE\Desktop`
- Try alternative: `C:\Temp\AutopilotHWID.csv`

---

## Best Practices

### 1. CSV File Management

```powershell
# Name files consistently
$date = Get-Date -Format "yyyyMMdd"
$computerName = $env:COMPUTERNAME
$fileName = "$computerName-$date-Autopilot.csv"
Get-WindowsAutopilotInfo -OutputFile "C:\Temp\$fileName"
```

### 2. Bulk Import Organization

```
folder structure:
├── AutopilotHashes/
│   ├── 2024-11-20/
│   │   ├── Device001.csv
│   │   ├── Device002.csv
│   │   └── merged.csv
│   └── 2024-11-21/
│       └── ...
```

### 3. Group Tags for Organization

```powershell
# Add group tags during extraction
Get-WindowsAutopilotInfo -OutputFile .\hash.csv -GroupTag "Finance-Dept"
Get-WindowsAutopilotInfo -OutputFile .\hash.csv -GroupTag "Remote-Workers"
Get-WindowsAutopilotInfo -OutputFile .\hash.csv -GroupTag "Executives"
```

### 4. Verification Script

```powershell
<#
.SYNOPSIS
    Verify Autopilot registration
#>

# Check if device is in Autopilot
$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber

Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"

$autopilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq '$serial'"

if ($autopilotDevice) {
    Write-Host "✅ Device IS registered in Autopilot" -ForegroundColor Green
    Write-Host "Group Tag: $($autopilotDevice.groupTag)"
    Write-Host "Deployment Profile: $($autopilotDevice.deploymentProfileAssignmentStatus)"
} else {
    Write-Host "❌ Device NOT registered in Autopilot" -ForegroundColor Red
    Write-Host "Serial Number: $serial"
}
```

### 5. Documentation Template

For each device batch, document:

```markdown
## Autopilot Import - [Date]

**Batch Information:**
- Date: 2024-11-20
- Device Count: 25
- Method Used: Method 2 (Installed Windows)
- Group Tag: Finance-Department
- Deployment Profile: Standard User Setup

**Devices:**
| Serial Number | Model | Status | Notes |
|---------------|-------|--------|-------|
| ABC123456 | Dell Latitude | ✅ Success | - |
| DEF789012 | Dell Latitude | ✅ Success | - |
| GHI345678 | HP EliteBook | ⚠️ Pending | Sync delay |

**Issues Encountered:**
- None

**Time Taken:**
- Extraction: 2 hours (25 devices × 5 min)
- Import: 15 minutes
- Verification: 30 minutes
- **Total: 2 hours 45 minutes**
```

---

## Summary: Choosing the Right Method

### Decision Tree

```
Are you purchasing NEW devices from OEM?
│
├─ YES → Method 3 (OEM Registration) ✅ BEST
│
└─ NO → Is Windows already installed?
    │
    ├─ YES → Is it ONE device or MANY?
    │   │
    │   ├─ ONE → Method 2 (Installed Windows) ✅ EASIEST
    │   │
    │   └─ MANY (50+) → Method 5 (Automated Script) ✅ EFFICIENT
    │
    └─ NO → Do you want to keep device "factory fresh"?
        │
        ├─ YES → Method 1 (OOBE) ⚠️ COMPLEX
        │
        └─ NO → Install Windows first, use Method 2 ✅ RECOMMENDED
```

### Quick Reference

| Your Situation | Recommended Method | Time | Difficulty |
|----------------|-------------------|------|------------|
| New corporate purchase | Method 3 (OEM) | 0 min | ⭐ |
| Lab/VM testing | Method 2 (Installed) | 5 min | ⭐⭐ |
| Migrating existing fleet | Method 5 (Automated) | Setup once | ⭐⭐⭐ |
| On-site deployment | Method 4 (USB) | 5 min/device | ⭐⭐⭐ |
| Single new device | Method 1 or 2 | 10-15 min | ⭐⭐⭐⭐ |
| Already in Intune | Method 6 (From Intune) | 2 min | ⭐ |

---

## Additional Resources

### Official Documentation
- [Windows Autopilot Documentation](https://docs.microsoft.com/windows/deployment/windows-autopilot/)
- [Intune Documentation](https://docs.microsoft.com/mem/intune/)
- [Microsoft Graph API](https://docs.microsoft.com/graph/)

### PowerShell Gallery
- [Get-WindowsAutopilotInfo](https://www.powershellgallery.com/packages/Get-WindowsAutopilotInfo)
- [WindowsAutopilotIntune Module](https://www.powershellgallery.com/packages/WindowsAutopilotIntune)

### Community Resources
- [Microsoft Tech Community - Autopilot](https://techcommunity.microsoft.com/t5/windows-autopilot/bd-p/Windows10Deployment)
- [Intune Customer Success Blog](https://techcommunity.microsoft.com/t5/intune-customer-success/bg-p/IntuneCustomerSuccess)

---

## Appendix A: PowerShell Cmdlets Reference

### Get-WindowsAutopilotInfo Parameters

```powershell
Get-WindowsAutopilotInfo `
    -OutputFile <string>           # Output CSV file path
    [-GroupTag <string>]           # Optional group tag
    [-AssignedUser <string>]       # Pre-assign user
    [-Online]                      # Upload directly to Intune
    [-Append]                      # Append to existing CSV
    [-Credential <PSCredential>]   # Credentials for online mode
    [-Partner]                     # For CSP partners
```

### Example Commands

```powershell
# Basic extraction
Get-WindowsAutopilotInfo -OutputFile .\hash.csv

# With group tag
Get-WindowsAutopilotInfo -OutputFile .\hash.csv -GroupTag "Finance"

# Direct upload to Intune (requires authentication)
Get-WindowsAutopilotInfo -Online

# Append to existing file
Get-WindowsAutopilotInfo -OutputFile .\batch.csv -Append

# Pre-assign user
Get-WindowsAutopilotInfo -OutputFile .\hash.csv -AssignedUser "user@contoso.com"
```

---

## Appendix B: CSV File Format

### Required Format

```csv
Device Serial Number,Windows Product ID,Hardware Hash
ABC123456,00000-00000-00000-00000,AAAAAQAAA...base64...
DEF789012,00000-00000-00000-00000,BBBBBQBBB...base64...
```

### Optional Fields

```csv
Device Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User
ABC123456,00000-00000-00000-00000,AAAAAQAAA...,Finance,user@contoso.com
```

### Validation Script

```powershell
<#
.SYNOPSIS
    Validate Autopilot CSV format
#>

$csvPath = ".\AutopilotHWID.csv"

try {
    $data = Import-Csv -Path $csvPath
    
    # Check required columns
    $requiredColumns = @('Device Serial Number', 'Windows Product ID', 'Hardware Hash')
    $actualColumns = $data[0].PSObject.Properties.Name
    
    $missingColumns = $requiredColumns | Where-Object { $_ -notin $actualColumns }
    
    if ($missingColumns) {
        Write-Host "❌ Missing required columns: $($missingColumns -join ', ')" -ForegroundColor Red
        exit 1
    }
    
    # Check for empty values
    $emptySerials = $data | Where-Object { [string]::IsNullOrWhiteSpace($_.'Device Serial Number') }
    $emptyHashes = $data | Where-Object { [string]::IsNullOrWhiteSpace($_.'Hardware Hash') }
    
    if ($emptySerials) {
        Write-Host "⚠️ Found $($emptySerials.Count) rows with empty serial numbers" -ForegroundColor Yellow
    }
    
    if ($emptyHashes) {
        Write-Host "⚠️ Found $($emptyHashes.Count) rows with empty hardware hashes" -ForegroundColor Yellow
    }
    
    # Check for duplicates
    $duplicates = $data | Group-Object 'Device Serial Number' | Where-Object { $_.Count -gt 1 }
    
    if ($duplicates) {
        Write-Host "⚠️ Found duplicate serial numbers:" -ForegroundColor Yellow
        $duplicates | ForEach-Object { Write-Host "  - $($_.Name)" }
    }
    
    Write-Host "`n✅ CSV validation complete!" -ForegroundColor Green
    Write-Host "Total devices: $($data.Count)"
    
} catch {
    Write-Host "❌ Failed to validate CSV: $_" -ForegroundColor Red
    exit 1
}
```

---

## Appendix C: Network Requirements

### Required URLs for Autopilot

Allow access to these Microsoft services:

```
# Autopilot Service
*.windows.com
*.microsoft.com

# Intune Service
*.manage.microsoft.com
*.microsoftonline.com

# Windows Update
*.windowsupdate.com
*.update.microsoft.com

# Telemetry
*.telemetry.microsoft.com

# Store
*.apps.microsoft.com
*.store.microsoft.com

# Licensing
*.licensing.mp.microsoft.com
```

### Firewall Ports

```
TCP 443 (HTTPS)
TCP 80 (HTTP - for redirects)
```

---

## License

This documentation is provided as-is for educational and professional use.

---

## Changelog

### Version 1.0 (2024-11-20)
- Initial release
- All 6 methods documented
- Complete PowerShell examples
- Troubleshooting guide

---

## Contributing

Found an issue or have a suggestion? Please open an issue on GitHub:
https://github.com/vidal-renao/intune-autopilot-lab/issues

---

## About the Author

**Vidal Reñao Lopelo**
- Cloud Solutions Engineer
- Microsoft 365 & Azure Specialist
- [LinkedIn](https://linkedin.com/in/vidal-renao)
- [GitHub](https://github.com/vidal-renao)

---

*Last Updated: November 2024*
