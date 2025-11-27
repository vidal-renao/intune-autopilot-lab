# Endpoint Security and Security Baselines Guide

> Complete guide for implementing enterprise-grade endpoint security using Microsoft Intune, including antivirus, encryption, firewall, and attack surface reduction.

## 📋 Table of Contents

- [Overview](#overview)
- [Understanding Endpoint Security](#understanding-endpoint-security)
- [Phase 1: Antivirus Protection](#phase-1-antivirus-protection)
- [Phase 2: Disk Encryption (BitLocker)](#phase-2-disk-encryption-bitlocker)
- [Phase 3: Firewall Configuration](#phase-3-firewall-configuration)
- [Phase 4: Attack Surface Reduction](#phase-4-attack-surface-reduction)
- [Phase 5: Account Protection](#phase-5-account-protection)
- [Phase 6: Security Baselines](#phase-6-security-baselines)
- [Phase 7: Endpoint Detection and Response](#phase-7-endpoint-detection-and-response)
- [Monitoring and Reporting](#monitoring-and-reporting)
- [Troubleshooting](#troubleshooting)

---

## Overview

Endpoint Security in Intune provides focused, purpose-built policies to protect devices from threats and manage security settings.

**What You'll Configure:**
- ✅ Microsoft Defender Antivirus
- ✅ BitLocker Disk Encryption
- ✅ Windows Firewall
- ✅ Attack Surface Reduction (ASR) Rules
- ✅ Account Protection (Credential Guard, Windows Hello)
- ✅ Security Baselines
- ✅ Endpoint Detection and Response (EDR)

**Estimated Time**: 2-3 hours

**Prerequisites:**
- Microsoft 365 Business Premium or E3/E5
- Windows 10/11 Pro or Enterprise
- Devices enrolled in Intune

---

## Understanding Endpoint Security

### Endpoint Security vs Configuration Profiles

| Aspect | Endpoint Security | Configuration Profiles |
|--------|------------------|----------------------|
| **Purpose** | Security-focused | General configuration |
| **Scope** | Security settings only | All device settings |
| **Expertise** | Security professionals | IT administrators |
| **Updates** | Security-focused updates | General updates |
| **Best For** | Zero Trust, compliance | Device management |

### Security Architecture

```
┌─────────────────────────────────────────────┐
│          Microsoft Defender Cloud           │
│     (Threat Intelligence & Analytics)       │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
┌──────────────┐    ┌──────────────┐
│   Intune     │    │   Defender   │
│  Endpoint    │◄───┤   for        │
│  Security    │    │   Endpoint   │
└──────┬───────┘    └──────────────┘
       │
       ▼
┌─────────────────────────────────┐
│      Windows 11 Device          │
├─────────────────────────────────┤
│ • Defender Antivirus            │
│ • BitLocker                     │
│ • Firewall                      │
│ • ASR Rules                     │
│ • Credential Guard              │
│ • EDR Sensor                    │
└─────────────────────────────────┘
```

### Policy Types in Endpoint Security

1. **Antivirus** - Real-time protection, scans, quarantine
2. **Disk encryption** - BitLocker configuration
3. **Firewall** - Network protection rules
4. **Endpoint detection and response** - EDR settings
5. **Attack surface reduction** - ASR rules
6. **Account protection** - Credential Guard, Windows Hello
7. **Security baselines** - Microsoft-recommended settings

---

## Phase 1: Antivirus Protection

Microsoft Defender Antivirus is the built-in antivirus for Windows 10/11.

### Step 1.1: Create Antivirus Policy

1. Go to **https://intune.microsoft.com**
2. Navigate to **Endpoint security → Antivirus**
3. Click **Create Policy**
4. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile: Microsoft Defender Antivirus
   ```

### Step 1.2: Configure Antivirus Settings

**Basics:**
```yaml
Name: Microsoft Defender Antivirus - Corporate Standard
Description: Standard antivirus configuration for all corporate devices
```

**Configuration Settings:**

#### Real-time Protection

```yaml
Turn on real-time protection: Enabled
Enable on access protection: Enabled
Monitoring for incoming and outgoing files: Monitor all files
Turn on behavior monitoring: Enabled
Turn on intrusion prevention: Enabled
Enable network protection: Enable (block)
```

#### Cloud Protection

```yaml
Turn on cloud-delivered protection: Enabled
Cloud-delivered protection level: High
Cloud extended timeout: 50 seconds
Consent: Send safe samples automatically
```

#### Automatic Sample Submission

```yaml
Submit samples consent: Send all samples automatically
```

**Why this matters:**
- Sends suspicious files to Microsoft for analysis
- Enables faster threat response
- Critical for zero-day protection

#### Scan Settings

```yaml
Scan type: Quick scan
Scan schedule day: Daily
Scan schedule time: 2:00 AM
Scan all downloaded files and attachments: Enabled
Turn on script scanning: Enabled

CPU usage limit during scan: 50%
Run daily quick scan at: 2:00 AM
Check for signature updates before running scan: Enabled
```

#### Remediation

```yaml
Submit malware sample consent: Always prompt
Number of days to keep malware in quarantine: 30
Action for potentially unwanted apps: Enable
Actions for detected threats:
  Severe: Remove
  High: Quarantine
  Medium: Quarantine
  Low: Quarantine
```

#### Exclusions (Configure Carefully)

```yaml
File and folder exclusions: (only if absolutely necessary)
  Example: C:\TrustedApp\data.db
  
Process exclusions: (only trusted processes)
  Example: trustedapp.exe
  
Extension exclusions: (avoid if possible)
  Example: .tmp (only if needed)
```

**⚠️ Warning**: Exclusions create security risks. Only add if absolutely necessary.

### Step 1.3: Assign Antivirus Policy

```yaml
Assignments:
  Include: All Devices
  Exclude: None
```

Click **Next** → **Create**

### Step 1.4: Create Antivirus Exclusions Policy (If Needed)

**Only create if you have legitimate exclusions:**

```yaml
Platform: Windows 10, Windows 11, and Windows Server
Profile: Microsoft Defender Antivirus exclusions

Settings:
  Defender Processes To Exclude:
    - C:\Program Files\TrustedApp\app.exe
    
  Defender Paths To Exclude:
    - C:\TrustedData\
    
  Defender File Extensions To Exclude:
    - .dbx (if required by specific app)
```

### Step 1.5: Advanced Threat Protection (ATP)

**Create ATP Policy:**

```yaml
Profile: Microsoft Defender Antivirus

Advanced Settings:
  Enable Potentially Unwanted Application (PUA) protection: Audit mode
  OR: Block mode (more restrictive)
  
  Enable file hash computation: Enabled
  Enable tamper protection: Enabled
  
  Scan removable drives: Enabled
  Scan mapped network drives: Enabled
  Scan archive files: Enabled
  Scan email: Enabled
```

**Tamper Protection (CRITICAL):**
```yaml
Tamper Protection: Enabled (Force)
```

**Why:** Prevents malware from disabling Defender.

---

## Phase 2: Disk Encryption (BitLocker)

BitLocker provides full disk encryption for Windows devices.

### Step 2.1: Create Disk Encryption Policy

1. **Endpoint security → Disk encryption**
2. Click **Create Policy**
3. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile: BitLocker
   ```

### Step 2.2: Configure BitLocker Settings

**Basics:**
```yaml
Name: BitLocker Encryption - Corporate Standard
Description: Full disk encryption for all corporate devices
```

**Configuration:**

#### BitLocker Base Settings

```yaml
Enable full disk encryption for OS and fixed data drives: Yes
Require device encryption: Yes

Hide prompt about third-party encryption: Yes
Allow standard users to enable encryption: No
```

#### Operating System Drive Settings

```yaml
BitLocker system drive policy:
  Startup authentication required: Require TPM
  OR (More Secure): Require TPM with startup PIN
  
  Minimum PIN length: 6 characters
  
  Configure encryption method: XTS-AES 256-bit
  
  Allow enhanced PINs for startup: Enabled
  
  Recovery options:
    Allow certificate-based data recovery agent: Not configured
    Configure user storage of BitLocker recovery information: 
      Require storing to Azure AD
    Store recovery information in Azure Active Directory: Enabled
    Configure storage of BitLocker recovery information to Azure AD:
      Store recovery passwords and key packages
    
  Pre-boot recovery message and URL:
    Pre-boot recovery message: Use default
```

**Startup PIN Configuration (Most Secure):**

If using TPM + PIN:
```yaml
Startup authentication required: Require TPM with startup PIN
Minimum PIN length: 8 characters
Allow enhanced PINs for startup: Enabled
```

**⚠️ Trade-off:**
- **TPM only**: Transparent encryption, no user action
- **TPM + PIN**: More secure, user must enter PIN on boot

#### Fixed Data Drives Settings

```yaml
BitLocker fixed data drive policy:
  Require encryption: Require
  Recovery options: Backup to Azure AD
  Configure encryption method: XTS-AES 256-bit
  
  Deny write access to drives not protected by BitLocker: Enabled
```

#### Removable Data Drives Settings

```yaml
BitLocker removable data drive policy:
  Configure encryption method: AES-CBC 256-bit
  Deny write access to drives not protected by BitLocker: Enabled
  Allow users to suspend and decrypt: Disabled
```

### Step 2.3: Assign BitLocker Policy

```yaml
Assignments:
  Include: All Devices
  Exclude: None (or exclude devices that can't support BitLocker)
```

### Step 2.4: Monitor BitLocker Deployment

**Check Encryption Status:**

1. **Intune → Devices → Monitor → Encryption report**
2. View:
   - Devices encrypted
   - Devices not encrypted
   - Encryption in progress
   - Encryption failed

**PowerShell Verification (on device):**

```powershell
# Check BitLocker status
Get-BitLockerVolume

# Check recovery key backup to Azure AD
Get-BitLockerVolume -MountPoint "C:" | Select-Object VolumeStatus, ProtectionStatus, KeyProtector
```

**User Experience:**

1. Policy applied to device
2. User sees notification: "Encrypting..."
3. Encryption happens in background
4. May take 1-4 hours depending on disk size
5. Recovery key automatically backed up to Azure AD

---

## Phase 3: Firewall Configuration

Windows Firewall protects devices from network attacks.

### Step 3.1: Create Firewall Policy

1. **Endpoint security → Firewall**
2. Click **Create Policy**
3. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile: Microsoft Defender Firewall
   ```

### Step 3.2: Configure Firewall Settings

**Basics:**
```yaml
Name: Windows Firewall - Corporate Standard
Description: Firewall configuration for all networks
```

**Configuration:**

#### Domain Network (Corporate Network)

```yaml
Firewall: Enable
Inbound connections: Block all
Outbound connections: Allow all (unless you need to block specific)

Stealth mode: Enable
Inbound notifications: Disable
Unicast responses to multicast broadcasts: Block

Log settings:
  Log file path: %systemroot%\system32\LogFiles\Firewall\pfirewall.log
  Log file max size: 16384 KB
  Log dropped packets: Yes
  Log successful connections: No
```

#### Private Network (Home Network)

```yaml
Firewall: Enable
Inbound connections: Block all
Outbound connections: Allow all

Stealth mode: Enable
Inbound notifications: Enable
Unicast responses to multicast broadcasts: Block
```

#### Public Network (Untrusted Network)

```yaml
Firewall: Enable
Inbound connections: Block all
Outbound connections: Allow all

Stealth mode: Enable
Inbound notifications: Enable
Unicast responses to multicast broadcasts: Block
Allow local policy merge: No
Allow local IPsec policy merge: No
```

**⚠️ Public Network = Most Restrictive**

### Step 3.3: Create Firewall Rules

**Allow Remote Desktop (if needed):**

1. **Endpoint security → Firewall**
2. Click **Create Policy**
3. Select **Microsoft Defender Firewall Rules**

```yaml
Name: Allow Remote Desktop - IT Staff

Rule:
  Name: Remote Desktop (TCP-In)
  Direction: Inbound
  Action: Allow
  Protocol: TCP
  Local ports: 3389
  
  Edge traversal: Block edge traversal
  Authorized users: (specific users/groups if possible)
  
Assign to: IT Administrators group only
```

**Allow Specific Application:**

```yaml
Name: Allow Custom App
Rule:
  Name: CustomApp Inbound
  Direction: Inbound
  Action: Allow
  Protocol: TCP
  Local ports: 8080
  Program path: C:\Program Files\CustomApp\app.exe
  
Assign to: Devices that need the app
```

### Step 3.4: Assign Firewall Policy

```yaml
Assignments:
  Include: All Devices
  Exclude: None
```

---

## Phase 4: Attack Surface Reduction

ASR rules reduce attack vectors by blocking risky behaviors.

### Step 4.1: Create ASR Policy

1. **Endpoint security → Attack surface reduction**
2. Click **Create Policy**
3. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile: Attack Surface Reduction rules
   ```

### Step 4.2: Configure ASR Rules

**Basics:**
```yaml
Name: Attack Surface Reduction Rules - Standard
Description: ASR rules to block common attack vectors
```

**Critical ASR Rules (Recommended):**

```yaml
Block executable content from email client and webmail: Block
  Rule GUID: BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550

Block all Office applications from creating child processes: Block
  Rule GUID: D4F940AB-401B-4EFC-AADC-AD5F3C50688A

Block Office applications from creating executable content: Block
  Rule GUID: 3B576869-A4EC-4529-8536-B80A7769E899

Block Office applications from injecting code into other processes: Block
  Rule GUID: 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84

Block JavaScript or VBScript from launching downloaded executable content: Block
  Rule GUID: D3E037E1-3EB8-44C8-A917-57927947596D

Block execution of potentially obfuscated scripts: Block
  Rule GUID: 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC

Block Win32 API calls from Office macros: Block
  Rule GUID: 92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B

Block credential stealing from the Windows local security authority subsystem (lsass.exe): Block
  Rule GUID: 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2

Block process creations originating from PSExec and WMI commands: Block
  Rule GUID: d1e49aac-8f56-4280-b9ba-993a6d77406c

Block untrusted and unsigned processes that run from USB: Block
  Rule GUID: b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4

Block Office communication application from creating child processes: Block
  Rule GUID: 26190899-1602-49e8-8b27-eb1d0a1ce869

Block Adobe Reader from creating child processes: Block
  Rule GUID: 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c

Block persistence through WMI event subscription: Block
  Rule GUID: e6db77e5-3df2-4cf1-b95a-636979351e5b
```

**ASR Rules - Audit Mode (for testing):**

When first implementing, consider:
```yaml
Mode: Audit mode (logs but doesn't block)
Duration: 2-4 weeks
Purpose: Identify false positives
Then: Switch to Block mode
```

**Exclusions (if needed):**

```yaml
ASR rule exclusions:
  Files: C:\TrustedApp\tool.exe
  Folders: C:\TrustedData\
```

### Step 4.3: Controlled Folder Access

Protects important folders from ransomware.

```yaml
Enable Controlled Folder Access: Enabled (Audit mode initially)

Protected folders:
  (Default Windows protected folders)
  + C:\Users\%username%\Documents
  + C:\CompanyData

Allowed applications:
  C:\Program Files\TrustedApp\app.exe
  (Only add if legitimate app needs access)
```

### Step 4.4: Assign ASR Policy

```yaml
Assignments:
  Include: All Devices
  Exclude: Developer workstations (if needed)
```

---

## Phase 5: Account Protection

Protects user credentials and authentication.

### Step 5.1: Create Account Protection Policy

1. **Endpoint security → Account protection**
2. Click **Create Policy**
3. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile: Account protection
   ```

### Step 5.2: Configure Credential Guard

**Windows Defender Credential Guard:**

```yaml
Name: Credential Guard - Enterprise

Settings:
  Turn on Credential Guard: Enable with UEFI lock
  
  Platform Security Level: Secure Boot and DMA Protection
  
  Virtualization Based Security:
    Requirement: Require
    
  Configure System Guard Launch: Enabled
```

**Requirements:**
- UEFI firmware (not legacy BIOS)
- Secure Boot capable
- TPM 2.0
- Virtualization extensions (Intel VT-x or AMD-V)

### Step 5.3: Configure Windows Hello for Business

```yaml
Profile: Identity protection

Settings:
  Use Windows Hello for Business: Enable
  Minimum PIN length: 6
  Maximum PIN length: 127
  Lowercase letters in PIN: Allow
  Uppercase letters in PIN: Allow
  Special characters in PIN: Allow
  PIN expiration (days): 0 (never)
  Prevent reuse of previous PINs: 5
  
  Enable biometric authentication: Yes
  Use enhanced anti-spoofing (if available): Yes
  
  Use security keys for sign-in: Enabled
```

### Step 5.4: Local Admin Password Solution (LAPS)

**Configure LAPS:**

```yaml
Profile: Local admin password solution (Windows LAPS)

Settings:
  Backup directory: Azure Active Directory
  Password age (days): 30
  Administrator account name: Administrator (or custom)
  Password complexity: Large letters + small letters + numbers + special
  Password length: 14
  Post authentication actions: Reset password and logoff managed account
```

---

## Phase 6: Security Baselines

Microsoft-recommended security configurations.

### Step 6.1: Available Security Baselines

```yaml
Available Baselines:
  - Security Baseline for Windows 10 and later
  - Microsoft Defender for Endpoint Baseline
  - Microsoft Edge Baseline
  - Microsoft 365 Apps for Enterprise Security Baseline
```

### Step 6.2: Deploy Windows Security Baseline

1. **Endpoint security → Security baselines**
2. Select **Security Baseline for Windows 10 and later**
3. Click **Create profile**

**Configuration:**

```yaml
Name: Windows 11 Security Baseline - Corporate

Baseline version: (latest available)

Settings to customize:
  Above Lock:
    - Voice activate apps: Block
    
  App Runtime:
    - Microsoft accounts optional for Store apps: Enable
    
  BitLocker:
    - Use configuration from Disk Encryption policy
    
  Browser:
    - Configure from Microsoft Edge Baseline
    
  Device Guard:
    - Credential Guard configuration: Configured above
    
  Firewall:
    - Use configuration from Firewall policy
    
  Windows Defender:
    - Use configuration from Antivirus policy
```

**Most settings:** Keep Microsoft defaults (they're already secure)

### Step 6.3: Deploy Microsoft Defender for Endpoint Baseline

```yaml
Name: Defender for Endpoint Baseline - Corporate

Settings:
  Application Guard:
    - Turn on App Guard for Edge: Enabled
    
  Attack Surface Reduction:
    - Use configuration from ASR policy
    
  BitLocker:
    - Use configuration from Disk Encryption policy
    
  Defender:
    - Use configuration from Antivirus policy
    
  Device Control:
    - Removable storage access: Read-only (or Block)
    
  Exploit Protection:
    - Use system defaults (Microsoft's protection)
    
  Microsoft Defender Security Center:
    - Hide areas from users: None (let users see status)
```

### Step 6.4: Deploy Microsoft Edge Baseline

```yaml
Name: Microsoft Edge Security Baseline - Corporate

Key Settings:
  Passwords and autofill:
    - Enable saving passwords: Block
    - Enable autofill for addresses: Block
    - Enable autofill for credit cards: Block
    
  Content settings:
    - Default pop-up window setting: Block
    - Default notification setting: Ask
    
  Extensions:
    - Control which extensions are installed silently: (enterprise extensions)
    - Block extensions: (known malicious)
    
  HTTP authentication:
    - Allowed authentication schemes: NTLM, Negotiate
    
  Privacy:
    - Enable Do Not Track: Enabled
    - Send required and optional diagnostic data: Required only
    
  SmartScreen:
    - Configure SmartScreen: Enabled
    - Prevent bypassing SmartScreen warnings: Enabled
```

### Step 6.5: Assign Security Baselines

```yaml
All Baselines:
  Include: All Devices
  Exclude: Test/development devices (if needed)
```

---

## Phase 7: Endpoint Detection and Response

Advanced threat detection and response capabilities.

### Step 7.1: Enable Microsoft Defender for Endpoint

**Prerequisites:**
- Microsoft 365 E5 or Defender for Endpoint license
- Devices enrolled in Intune

**Enable EDR:**

1. **Endpoint security → Endpoint detection and response**
2. Click **Create Policy**
3. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile: Endpoint detection and response
   ```

**Configuration:**

```yaml
Name: Microsoft Defender for Endpoint - Onboarding

Settings:
  Endpoint detection and response configuration package:
    - Download onboarding package from Security Center
    - Upload .onboardingpackage file
    
  Sample sharing for all files: Enable
  Expedite telemetry reporting frequency: Enable
```

**Get Onboarding Package:**

1. Go to **https://security.microsoft.com**
2. **Settings → Endpoints → Onboarding**
3. Select **Windows 10 and later**
4. Download onboarding package
5. Upload to Intune policy

### Step 7.2: Configure EDR Settings

```yaml
Profile: Endpoint detection and response

Settings:
  Telemetry reporting frequency: Expedited
  Sample collection: All files
  Tamper protection: Enabled (Force)
  
  Advanced features:
    - Auto-resolve alerts: Enabled
    - Block at first sight: Enabled
    - Cloud protection level: High+
```

### Step 7.3: Assign EDR Policy

```yaml
Assignments:
  Include: All Devices
  Exclude: None
```

---

## Monitoring and Reporting

### Dashboard Locations

**Intune Portal:**
```
Endpoint security → Overview
  - Antivirus status
  - Firewall status
  - Encryption status
  - Endpoint security status
```

**Security Center:**
```
https://security.microsoft.com

Dashboards:
  - Threat & Vulnerability Management
  - Incidents & Alerts
  - Threat Analytics
  - Secure Score
```

### Key Reports to Monitor

1. **Encryption Report**
   ```
   Intune → Devices → Monitor → Encryption report
   Check: % of devices encrypted
   ```

2. **Antivirus Report**
   ```
   Endpoint security → Antivirus → Monitor
   Check: Devices without protection
   ```

3. **Firewall Status**
   ```
   Endpoint security → Firewall → Monitor
   Check: Firewall disabled devices
   ```

4. **ASR Events**
   ```
   Security Center → Reports → Attack surface reduction
   Check: Blocked attacks, false positives
   ```

5. **Security Baseline Compliance**
   ```
   Endpoint security → Security baselines → [Baseline] → Monitor
   Check: Non-compliant settings
   ```

### PowerShell Monitoring

```powershell
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All"

# Get BitLocker status across all devices
$devices = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'"

foreach ($device in $devices) {
    $encryption = Get-MgDeviceManagementManagedDeviceEncryptionState -ManagedDeviceId $device.Id
    
    [PSCustomObject]@{
        DeviceName = $device.deviceName
        EncryptionState = $encryption.encryptionState
        EncryptionMethod = $encryption.encryptionMethod
    }
}
```

---

## Troubleshooting

### Issue 1: BitLocker Not Encrypting

**Symptoms:**
- Device shows "Not encrypted"
- Policy shows "Pending"

**Solutions:**

1. **Check TPM status:**
   ```powershell
   Get-Tpm
   # Should show: TpmPresent: True, TpmReady: True
   ```

2. **Check for errors:**
   ```powershell
   Get-BitLockerVolume | Select-Object VolumeStatus, ProtectionStatus, EncryptionPercentage
   ```

3. **Common causes:**
   - TPM not enabled in BIOS/UEFI
   - Secure Boot not enabled
   - Drive already encrypted with non-BitLocker
   - Insufficient permissions

4. **Manually trigger:**
   ```powershell
   # As Administrator
   Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector
   ```

### Issue 2: ASR Rules Blocking Legitimate Apps

**Symptoms:**
- Application won't launch
- Process blocked messages
- Users report functionality issues

**Solutions:**

1. **Check ASR events:**
   ```
   Security Center → Reports → Attack surface reduction
   Find the blocked event
   ```

2. **Identify the rule:**
   Look at the Rule GUID in event logs

3. **Options:**
   - **Best**: Fix the app (contact vendor)
   - **Good**: Add process exclusion
   - **Last resort**: Set rule to Audit mode

4. **Add exclusion:**
   ```yaml
   ASR policy → Edit → Exclusions
   Add: C:\Program Files\LegitimateApp\app.exe
   ```

### Issue 3: Defender Antivirus Disabled

**Symptoms:**
- Real-time protection off
- Can't turn on protection
- Tamper protection message

**Solutions:**

1. **Check Tamper Protection:**
   ```powershell
   Get-MpComputerStatus | Select-Object IsTamperProtected, RealTimeProtectionEnabled
   ```

2. **Re-enable from policy:**
   ```yaml
   Antivirus policy → Tamper Protection: Enabled (Force)
   Sync device
   ```

3. **Check for conflicts:**
   - Third-party antivirus installed?
   - Conflicting group policies?
   - Local admin disabled it?

4. **Force enable:**
   ```powershell
   Set-MpPreference -DisableRealtimeMonitoring $false
   ```

### Issue 4: Firewall Rule Not Applying

**Symptoms:**
- Connection blocked
- Rule shows as assigned but not working

**Solutions:**

1. **Check firewall status:**
   ```powershell
   Get-NetFirewallProfile | Select-Object Name, Enabled
   ```

2. **Check rule:**
   ```powershell
   Get-NetFirewallRule -DisplayName "Your Rule Name" | Select-Object *
   ```

3. **Verify no local conflicts:**
   ```powershell
   # Check local rules
   Get-NetFirewallRule -PolicyStore ActiveStore
   ```

4. **Force policy refresh:**
   ```
   Device → Sync
   Wait 5 minutes
   ```

---

## Security Configuration Checklist

Before considering security complete:

- [x] Antivirus policy created and assigned
- [x] Real-time protection enabled
- [x] Cloud protection enabled
- [x] Tamper protection enabled
- [x] BitLocker policy created and assigned
- [x] All devices encrypted (or in progress)
- [x] Recovery keys backed up to Azure AD
- [x] Firewall policy created for all networks
- [x] ASR rules configured (at least critical ones)
- [x] ASR tested in audit mode first
- [x] Account protection configured
- [x] Credential Guard enabled (if supported)
- [x] Windows Hello for Business configured
- [x] Security baselines deployed
- [x] EDR onboarding completed (if E5)
- [x] Monitoring dashboards configured
- [x] Security team trained on alerts

---

## Next Steps

Once endpoint security is configured:

📄 **[05-troubleshooting.md](./05-troubleshooting.md)** - Comprehensive troubleshooting guide for common issues

---

## Additional Resources

### Microsoft Documentation
- [Endpoint Security in Intune](https://learn.microsoft.com/mem/intune/protect/endpoint-security)
- [BitLocker Overview](https://learn.microsoft.com/windows/security/information-protection/bitlocker/)
- [Attack Surface Reduction](https://learn.microsoft.com/microsoft-365/security/defender-endpoint/attack-surface-reduction)
- [Defender Antivirus](https://learn.microsoft.com/microsoft-365/security/defender-endpoint/microsoft-defender-antivirus-windows)

### Security Center
- **Microsoft 365 Defender**: https://security.microsoft.com
- **Secure Score**: https://security.microsoft.com/securescore
- **Threat Analytics**: https://security.microsoft.com/threatanalytics3

### Community Resources
- [Microsoft Security Blog](https://www.microsoft.com/security/blog/)
- [Defender for Endpoint Tech Community](https://techcommunity.microsoft.com/t5/microsoft-defender-for-endpoint/bd-p/MicrosoftDefenderATP)

---

*Last Updated: November 2024*
*Author: Vidal Reñao Lopelo*
*Repository: https://github.com/vidal-renao/intune-autopilot-lab*
