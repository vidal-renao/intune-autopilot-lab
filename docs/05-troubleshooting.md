# 🔧 Troubleshooting Guide - Intune Autopilot

## 📋 Table of Contents
1. [Common Autopilot Deployment Issues](#autopilot-issues)
2. [Device Registration Problems](#registration-problems)
3. [Profile Assignment Issues](#profile-issues)
4. [Network and Connectivity](#network-issues)
5. [Policy Application Failures](#policy-failures)
6. [Diagnostic Tools and Logs](#diagnostic-tools)
7. [Known Issues and Workarounds](#known-issues)

---

## 1. Common Autopilot Deployment Issues {#autopilot-issues}

### ❌ Issue: Device stuck at "Just a moment..." screen

**Symptoms:**
- Device remains at white screen with spinning dots
- No progress for more than 30 minutes
- No error message displayed

**Common Causes:**
- Network connectivity issues
- TPM attestation failure
- Autopilot profile not assigned
- Device hash not properly imported

**Solutions:**

#### Step 1: Check network connectivity
```powershell
# Test internet connectivity
Test-NetConnection -ComputerName www.microsoft.com -Port 443

# Test Azure AD connectivity
Test-NetConnection -ComputerName login.microsoftonline.com -Port 443
```

#### Step 2: Verify Autopilot profile assignment
1. Go to **Intune Portal** → Devices → Enroll devices → Windows enrollment → Devices
2. Search for device by serial number
3. Verify profile is assigned and status shows "Assigned"

#### Step 3: Collect logs
```powershell
# Press Shift + F10 to open Command Prompt during OOBE
cd C:\Windows\Panther

# Export Autopilot diagnostics
mdmdiagnosticstool.exe -area Autopilot -cab C:\AutopilotDiag.cab
```

#### Step 4: Reset and retry
- Restart the device: `shutdown /r /t 0`
- If issue persists, reset to factory settings
- Re-import hardware hash if necessary

---

### ❌ Issue: "Something went wrong" error during deployment

**Error Code Examples:**
- `0x80180014` - Device registration failed
- `0x801c03ea` - Policy download failure
- `0x80070774` - Certificate enrollment failed

**Solutions by Error Code:**

#### 0x80180014 - Device Registration Failed
```powershell
# Check Azure AD join status
dsregcmd /status

# Verify required URLs are accessible
# https://docs.microsoft.com/en-us/mem/autopilot/networking-requirements
```

**Resolution:**
1. Verify firewall/proxy allows required URLs
2. Check device is not already registered in another tenant
3. Remove stale device records from Azure AD
4. Retry deployment

#### 0x801c03ea - Policy Download Failure
**Causes:**
- Network timeout
- Intune service temporary unavailability
- Configuration profile corruption

**Resolution:**
1. Restart device and retry
2. Verify Intune service health in M365 Admin Center
3. Check assignment filters are not blocking the device
4. Review policy JSON for syntax errors

#### 0x80070774 - Certificate Enrollment Failed
**Resolution:**
1. Check NDES/SCEP configuration
2. Verify CA certificates are valid
3. Review certificate profile assignment
4. Check device can reach certificate authority

---

## 2. Device Registration Problems {#registration-problems}

### ❌ Issue: Hardware hash not appearing in Intune

**Symptoms:**
- Device imported but not showing in Autopilot devices list
- CSV imported successfully but no devices appear
- Import status shows "Processing" indefinitely

**Solutions:**

#### Verify CSV format
```csv
Device Serial Number,Windows Product ID,Hardware Hash
SERIALNUMBER123,ProductID123,BASE64HARDWAREHASH==
```

**Common CSV mistakes:**
- Extra spaces in headers
- Missing comma delimiters
- Hardware hash not properly base64 encoded
- BOM encoding in UTF-8 file

#### Re-export hardware hash properly
```powershell
# Recommended method - Using Get-WindowsAutopilotInfo
Install-Script -Name Get-WindowsAutopilotInfo
Get-WindowsAutopilotInfo -OutputFile C:\ComputerHash.csv

# Verify hash in CSV
$csv = Import-Csv C:\ComputerHash.csv
$csv.'Hardware Hash'.Length  # Should be several thousand characters
```

#### Check import status
```powershell
# Using Microsoft Graph PowerShell
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

# Get import status
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity | 
    Where-Object {$_.SerialNumber -eq "YOUR_SERIAL_NUMBER"}
```

#### Force sync
1. Go to **Intune Portal** → Devices → Enroll devices → Windows enrollment → Devices
2. Click **Sync** button
3. Wait 15-30 minutes for sync to complete
4. Refresh browser

---

### ❌ Issue: Device assigned to wrong group/profile

**Solutions:**

#### Check dynamic group membership
```powershell
# Verify device properties
Get-MgDevice -Filter "displayName eq 'DEVICE_NAME'" | 
    Select-Object Id, DisplayName, DeviceId, OperatingSystem
```

**Review dynamic group rules:**
```
(device.devicePhysicalIds -any (_ -contains "[ZTDId]"))
-and (device.deviceModel -eq "Surface Pro 9")
```

#### Verify profile assignment
1. Device → Properties → Group memberships
2. Check which Autopilot profile is targeted
3. Review assignment filters

#### Reassign device
```powershell
# Remove from current profile
# Assign to correct profile
# Force sync
```

---

## 3. Profile Assignment Issues {#profile-issues}

### ❌ Issue: Profile changes not applying to devices

**Solutions:**

#### Clear device Autopilot profile cache
1. Delete device from Autopilot devices list
2. Wait 30 minutes
3. Re-import hardware hash
4. Assign new profile
5. Force sync

#### Check assignment conflicts
- Review all assignment filters
- Verify group membership is correct
- Check for exclude groups blocking assignment
- Ensure no conflicting profiles are assigned

---

## 4. Network and Connectivity {#network-issues}

### ❌ Issue: Cannot reach required endpoints

**Required URLs for Autopilot:**
```
# Azure AD
login.microsoftonline.com
login.microsoft.com

# Intune
*.manage.microsoft.com
enterpriseregistration.windows.net

# Windows Update
*.windowsupdate.com
*.delivery.mp.microsoft.com

# Certificate Services (if using SCEP)
[Your NDES server FQDN]
```

**Test connectivity:**
```powershell
# Test each critical endpoint
$endpoints = @(
    "login.microsoftonline.com",
    "enterpriseregistration.windows.net",
    "manage.microsoft.com"
)

foreach ($endpoint in $endpoints) {
    Write-Host "Testing $endpoint..." -ForegroundColor Yellow
    $result = Test-NetConnection -ComputerName $endpoint -Port 443
    if ($result.TcpTestSucceeded) {
        Write-Host "✓ Success" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed" -ForegroundColor Red
    }
}
```

**Proxy configuration:**
```powershell
# Configure proxy if required
netsh winhttp set proxy proxy-server="proxy.company.com:8080" bypass-list="localhost;*.local"

# Test proxy settings
netsh winhttp show proxy
```

---

## 5. Policy Application Failures {#policy-failures}

### ❌ Issue: Configuration policies not applying

**Check policy assignment:**
1. Intune Portal → Devices → Configuration profiles
2. Select profile → Device status
3. Review errors and pending devices

**Force policy sync on device:**
```powershell
# Trigger IME sync
Get-ScheduledTask | Where-Object {$_.TaskName -eq 'PushLaunch'} | Start-ScheduledTask

# Manual sync via Registry
$trigger = @{
    SessionType = "BackgroundSync"
}
Invoke-MDMReenrollment
```

**Review Intune Management Extension logs:**
```
Location: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
Key files:
- IntuneManagementExtension.log
- AgentExecutor.log
```

---

## 6. Diagnostic Tools and Logs {#diagnostic-tools}

### Primary Diagnostic Tools

#### 1. MDM Diagnostic Tool
```powershell
# Generate diagnostic report
mdmdiagnosticstool.exe -out C:\MDMDiag

# Generate Autopilot-specific diagnostics
mdmdiagnosticstool.exe -area Autopilot -cab C:\AutopilotDiag.cab
```

#### 2. dsregcmd Status
```powershell
# Check Azure AD join status
dsregcmd /status

# Key sections to review:
# - Device State (AzureAdJoined should be YES)
# - Tenant Details
# - User State
# - Diagnostic Data
```

Expected output for successful Autopilot device:
```
+----------------------------------------------------------------------+
| Device State                                                         |
+----------------------------------------------------------------------+
             AzureAdJoined : YES
          EnterpriseJoined : NO
              DomainJoined : NO
```

#### 3. Get-AutopilotDiagnostics
```powershell
# Install module
Install-Script -Name Get-AutopilotDiagnostics

# Run diagnostics
Get-AutopilotDiagnostics -Online

# Export to file
Get-AutopilotDiagnostics -OutputFile C:\AutopilotDiag.html
```

### Key Log Locations

```
# Autopilot logs
C:\Windows\Panther\
C:\Windows\Provisioning\Autopilot\

# Intune Management Extension
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\

# Event Viewer
Applications and Services Logs → Microsoft → Windows → 
  - Provisioning-Diagnostics-Provider
  - DeviceManagement-Enterprise-Diagnostics-Provider
  - AAD

# MDM Diagnostics
C:\ProgramData\Microsoft\Windows\MDMDiagnostics\
```

### Analyzing ETL Logs
```powershell
# Convert ETL to readable format
Get-WinEvent -Path "C:\Windows\Panther\DiagnosticEvents.xml" | 
    Select-Object TimeCreated, LevelDisplayName, Message |
    Out-File C:\AutopilotEvents.txt
```

---

## 7. Known Issues and Workarounds {#known-issues}

### Known Issue #1: White Glove fails with TPM attestation error

**Affected Versions:** Windows 10 20H2, 21H1  
**Error:** "TPM attestation failed"

**Workaround:**
1. Update Windows to latest cumulative update
2. Or disable TPM attestation in Autopilot profile (not recommended for production)
3. Microsoft patch: KB5003173 or later

### Known Issue #2: Device reboots during ESP and loses progress

**Cause:** Windows Updates trigger reboot during ESP

**Workaround:**
1. Configure Windows Update ring to defer updates
2. Use Autopilot profile settings:
   - "Allow users to reset device if installation error occurs" = No
   - "Block device use until required apps are installed" = Yes
3. Pre-stage critical updates in WIM image

### Known Issue #3: ESP stuck at "Preparing your device"

**Symptoms:**
- Progress bar doesn't move
- Can last 1+ hours
- Eventually times out

**Causes:**
- Large number of policies assigned
- Network latency
- Certificate enrollment delays

**Workarounds:**
1. Reduce number of policies in ESP
2. Assign policies to user phase instead of device phase
3. Use assignment filters to target only critical policies during ESP
4. Increase ESP timeout value (default 60 minutes)

### Known Issue #4: Co-management devices fail Autopilot

**Cause:** Configuration Manager client interfering with Autopilot

**Workaround:**
1. Do not install ConfigMgr client during Autopilot
2. Install ConfigMgr client after Autopilot completes
3. Use co-management workload slider to transition gradually
4. Ensure Autopilot devices are in separate collection

---

## 🆘 Emergency Recovery Steps

If Autopilot deployment completely fails:

### Step 1: Collect all logs
```powershell
# Run this on affected device
$logPath = "C:\AutopilotLogs"
New-Item -ItemType Directory -Path $logPath -Force

# Copy all relevant logs
Copy-Item "C:\Windows\Panther\*" $logPath -Recurse -Force
Copy-Item "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\*" $logPath -Recurse -Force

# Generate MDM diagnostic
mdmdiagnosticstool.exe -out $logPath\MDMDiag

# Generate Autopilot diagnostic
Get-AutopilotDiagnostics -OutputFile $logPath\AutopilotDiag.html

# Compress logs
Compress-Archive -Path $logPath -DestinationPath "C:\AutopilotLogs_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
```

### Step 2: Reset device
```powershell
# Option 1: Reset from Windows
systemreset -factoryreset

# Option 2: Boot to recovery and reset
# Press Shift + F10 during OOBE
shutdown /r /o /t 0
```

### Step 3: Remove device from Azure AD and Intune
1. Azure AD → Devices → Search device → Delete
2. Intune → Devices → All devices → Search device → Delete
3. Intune → Devices → Windows → Windows enrollment → Devices → Search device → Delete

### Step 4: Re-import hardware hash
```powershell
# On the device or from another machine with access
Get-WindowsAutopilotInfo -OutputFile C:\Hash.csv
# Import CSV to Intune
# Wait 30 minutes for sync
# Retry Autopilot deployment
```

---

## 📞 Additional Resources

**Microsoft Documentation:**
- [Autopilot troubleshooting](https://docs.microsoft.com/en-us/mem/autopilot/troubleshooting)
- [Known issues](https://docs.microsoft.com/en-us/mem/autopilot/known-issues)
- [Windows Autopilot support](https://docs.microsoft.com/en-us/mem/autopilot/autopilot-support)

**Community Resources:**
- [Microsoft Tech Community - Intune](https://techcommunity.microsoft.com/t5/microsoft-intune/bd-p/Microsoft-Intune)
- [Reddit r/Intune](https://www.reddit.com/r/Intune/)

**Support Channels:**
- Microsoft Premier Support
- Microsoft 365 Admin Center → Support → New service request
- Intune Portal → Help and support

---

## 📝 Troubleshooting Checklist

Use this checklist when encountering Autopilot issues:

- [ ] Device hardware hash properly imported
- [ ] Autopilot profile assigned to device
- [ ] Network connectivity verified (all required URLs accessible)
- [ ] Azure AD tenant ID matches deployment configuration
- [ ] No conflicting group policies or assignments
- [ ] TPM enabled and functional
- [ ] Windows version compatible with Autopilot profile
- [ ] Intune service health normal (check M365 admin center)
- [ ] Logs collected and reviewed
- [ ] Device not previously registered in another tenant
- [ ] Certificates valid and not expired
- [ ] Firewall/proxy configuration allows traffic
- [ ] User assigned appropriate licenses
- [ ] ESP configured correctly (if used)
- [ ] Assignment filters not blocking deployment

---

**Last Updated:** November 2024  
**Version:** 1.0
