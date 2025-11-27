# Configuration Policies and Templates Guide

> Complete guide for creating and managing device configuration profiles, Settings Catalog policies, and custom configurations in Microsoft Intune.

## 📋 Table of Contents

- [Overview](#overview)
- [Understanding Configuration Methods](#understanding-configuration-methods)
- [Phase 1: Configuration Profiles (Templates)](#phase-1-configuration-profiles-templates)
- [Phase 2: Settings Catalog](#phase-2-settings-catalog)
- [Phase 3: Administrative Templates](#phase-3-administrative-templates)
- [Phase 4: Custom Configurations](#phase-4-custom-configurations)
- [Common Policy Examples](#common-policy-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

Intune provides multiple methods to configure Windows devices. This guide covers:

- ✅ Configuration Profiles (template-based)
- ✅ Settings Catalog (granular control)
- ✅ Administrative Templates (GPO-like)
- ✅ Custom OMA-URI configurations
- ✅ Real-world policy examples

**Estimated Time**: 1-2 hours to configure base policies

---

## Understanding Configuration Methods

### Configuration Methods Comparison

| Method | Use Case | Difficulty | Flexibility | Example |
|--------|----------|-----------|-------------|---------|
| **Configuration Profiles** | Common scenarios | ⭐ Easy | Limited | WiFi, VPN, Email |
| **Settings Catalog** | Granular control | ⭐⭐ Medium | High | Specific Windows settings |
| **Administrative Templates** | GPO replacement | ⭐⭐ Medium | High | Classic Windows policies |
| **Custom OMA-URI** | Advanced scenarios | ⭐⭐⭐⭐ Hard | Maximum | Custom CSP settings |

### When to Use Each Method

```
Need WiFi or VPN? → Configuration Profile (Template)
Need specific Windows setting? → Settings Catalog
Migrating from GPO? → Administrative Templates
Need something custom? → OMA-URI
```

### Policy Application Order

```
1. Device Configuration Profiles
2. Settings Catalog
3. Administrative Templates
4. Custom OMA-URI
   ↓
Last applied policy wins (usually)
```

---

## Phase 1: Configuration Profiles (Templates)

Configuration Profiles use pre-built templates for common scenarios.

### Step 1.1: Access Configuration Profiles

1. Go to **https://intune.microsoft.com**
2. Navigate to **Devices → Configuration**
3. Click **Create → New Policy**

### Step 1.2: Available Profile Types

**Windows 10 and later:**
- Device restrictions
- Email
- VPN
- Wi-Fi
- Trusted certificate
- SCEP certificate
- PKCS certificate
- Custom
- Endpoint protection
- Delivery optimization
- Device features
- Device firmware configuration interface
- Edition upgrade and mode switch
- Kiosk
- Network boundary
- Shared multi-user device
- Update policies

### Common Configuration Profile: Device Restrictions

#### Create Device Restrictions Profile

**Step 1: Basics**

```yaml
Name: Windows Device Restrictions - Standard
Description: Standard device restrictions for corporate devices
Platform: Windows 10 and later
Profile type: Templates → Device restrictions
```

Click **Create**

**Step 2: Configuration Settings**

Key settings to configure:

**General:**
```yaml
Block manual unenrollment: Yes
Block Windows Spotlight: Block
Block voice recording: Not configured
Block Cortana: Block
Block location: Not configured
```

**Password:**
```yaml
Require password: Require
Require password type: Alphanumeric
Minimum password length: 8 characters
Number of sign-in failures before wiping device: 10
Maximum minutes of inactivity until screen locks: 5 minutes
Password expiration (days): 90
Prevent reuse of previous passwords: 5
```

**Cloud and Storage:**
```yaml
Force saving to OneDrive: Not configured
Block OneDrive sync: Not configured
Block removable storage: Not configured
```

**Control Panel and Settings:**
```yaml
Block access to Control Panel: Not configured
Block system time modification: Block
Block region settings modification: Block
```

**Start:**
```yaml
Start menu layout: (optional - upload XML file)
Pin websites to tiles: Not configured
```

**Step 3: Assignments**

```yaml
Include: All Devices
Exclude: None
```

Click **Next** → **Create**

### Common Configuration Profile: WiFi

#### Create WiFi Profile

**Basics:**

```yaml
Name: Corporate WiFi - Main Office
Description: WiFi configuration for main office network
Platform: Windows 10 and later
Profile type: Templates → Wi-Fi
```

**Configuration:**

```yaml
Wi-Fi type: Enterprise
Network name (SSID): CorpWiFi
Connection type: Automatically
Connect automatically: Yes
Connect when network is in range: Yes

Security type: WPA/WPA2-Enterprise
EAP type: PEAP
Certificate server names: (your RADIUS server)

Authentication method: Username and password
OR
Authentication method: Certificates (with SCEP/PKCS)

Proxy settings: None (or configure if needed)
```

**Assignments:**

```yaml
Include: All Devices
Exclude: None
```

### Common Configuration Profile: VPN

#### Create VPN Profile

**Basics:**

```yaml
Name: Corporate VPN
Description: VPN connection to corporate network
Platform: Windows 10 and later
Profile type: Templates → VPN
```

**Configuration:**

```yaml
Connection name: Corporate VPN
Connection type: IKEv2
OR
Connection type: Automatic (recommended)

Servers:
  Description: VPN Gateway
  Address: vpn.yourcompany.com
  
Authentication method: Username and password
OR
Authentication method: Certificates

Split tunneling: Enable (recommended for Office 365)
Always On: Not configured (or Enable for always-on VPN)

Proxy settings: Automatic detection (or Manual if needed)
```

**Assignments:**

```yaml
Include: Remote Workers group
Exclude: Office-based devices
```

### Common Configuration Profile: Email (Outlook)

#### Create Email Profile

**Basics:**

```yaml
Name: Corporate Email - Outlook
Description: Email configuration for Microsoft 365
Platform: Windows 10 and later
Profile type: Templates → Email
```

**Configuration:**

```yaml
Email server: outlook.office365.com
Account name: Corporate Email
Username: Use username from certificate
OR
Username: {{UserPrincipalName}}

Email address: {{EmailAddress}}
Authentication method: Username and password
OR
Authentication method: Certificates

Sync settings:
  Number of days of email to sync: 2 weeks
  Sync schedule: As messages arrive
  
Sync contacts: Yes
Sync calendar: Yes
Sync tasks: Yes
```

---

## Phase 2: Settings Catalog

Settings Catalog provides granular control over specific Windows settings.

### Step 2.1: Understanding Settings Catalog

**What is Settings Catalog?**
- Modern replacement for Templates
- Access to 1000+ individual settings
- Granular control
- Searchable settings
- Recommended for new policies

**When to Use:**
- Need specific Windows setting not in templates
- Want fine-grained control
- Building modern policies

### Step 2.2: Create Settings Catalog Policy

**Example: Windows Update Settings**

**Step 1: Create Policy**

1. Go to **Devices → Configuration → Create**
2. Select:
   ```yaml
   Platform: Windows 10 and later
   Profile type: Settings catalog
   ```

**Step 2: Add Settings**

Click **+ Add settings**

Search for settings by category:

**Example Settings to Configure:**

**Windows Update:**

1. Search: **"Windows Update"**
2. Expand **Windows Update for Business**
3. Select settings:

```yaml
Configure Deadline Grace Period: 2 days
Configure Deadline No Auto Reboot: Disabled
Configure Deadline For Feature Updates: 7 days
Configure Deadline For Quality Updates: 3 days

Active Hours Start: 8 AM
Active Hours End: 6 PM
Active Hours Max Range: 18 hours

Automatic Updates Behavior: Auto install and restart at scheduled time
Scheduled Install Day: 0 (Every day)
Scheduled Install Time: 3 AM

Defer Feature Updates: 30 days
Defer Quality Updates: 7 days
Pause Feature Updates: Not configured
```

**Power Settings:**

Search: **"Power"**

```yaml
Allow Standby States When Sleeping Plugged In: Disabled
Require Password When Computer Wakes On Battery: Enabled
Require Password When Computer Wakes Plugged In: Enabled

Display Turn Off Timeout On Battery: 10 minutes
Display Turn Off Timeout Plugged In: 15 minutes
Sleep Timeout On Battery: 15 minutes
Sleep Timeout Plugged In: 30 minutes
```

**BitLocker (if not using Endpoint Security):**

Search: **"BitLocker"**

```yaml
Require Device Encryption: Yes
Allow Warning For Other Disk Encryption: Block
Allow Standard User Encryption: Block

Operating System Drive:
  Encryption Method: XTS-AES 256-bit
  Require Additional Authentication At Startup: Require TPM
  Require TPM Startup PIN: Require startup PIN with TPM
  Minimum PIN Length: 6
  
Recovery:
  Recovery Key File Creation: Enabled
  Hide Recovery Options: Disabled
  Save BitLocker Recovery Information To AAD: Enabled
```

**Step 3: Name and Assign**

```yaml
Basics:
  Name: Windows Update and Power Management
  Description: Configures Windows Update settings and power management

Assignments:
  Include: All Devices
  Exclude: None
```

### Step 2.3: Common Settings Catalog Policies

**Policy 1: Privacy and Telemetry**

Search for: **"Privacy"**, **"Telemetry"**

```yaml
Settings:
  Allow Telemetry: Required
  Disable Advertising Id: Enabled
  Let Apps Access Location: Force deny
  Let Apps Access Camera: User choice
  Let Apps Access Microphone: User choice
  Disable Consumer Account State Content: Enabled
```

**Policy 2: Security Hardening**

Search for: **"Security"**, **"Credential"**

```yaml
Settings:
  Block Non Admin User Install: Enabled
  Allow Local System Null Session Fallback: Disabled
  Disable NTLM: Enabled
  Apply UAC Restrictions: Enabled
  Elevation Prompt Behavior Admin: Prompt for credentials
  Enable Secure Boot: Enabled
```

**Policy 3: Start Menu and Taskbar**

Search for: **"Start"**, **"Taskbar"**

```yaml
Settings:
  Hide App List: Not configured
  Hide Recently Added Apps: Enabled
  Hide Change Account Settings: Enabled
  Pin Apps To Taskbar: (list of apps)
  Remove Task View: Enabled
  Show Recent Files: Disabled
```

---

## Phase 3: Administrative Templates

Administrative Templates replicate Group Policy (GPO) functionality.

### Step 3.1: Create Administrative Template

**Example: Internet Explorer Settings**

1. **Devices → Configuration → Create**
2. Platform: **Windows 10 and later**
3. Profile type: **Templates → Administrative Templates**

**Configuration:**

```yaml
Name: Internet Explorer Security Settings
Description: IE security and compatibility settings

Computer Configuration:
  Windows Components → Internet Explorer:
    - Disable changing Automatic Configuration settings: Enabled
    - Disable changing proxy settings: Enabled
    - Turn on Enhanced Protected Mode: Enabled
    
  Internet Control Panel → Security Page:
    - Intranet Zone: Medium-low security
    - Internet Zone: Medium-high security
```

### Step 3.2: Common Administrative Templates

**Policy 1: Windows Defender Exploit Guard**

```yaml
Computer Configuration → Windows Components → Windows Defender Exploit Guard:
  Attack Surface Reduction:
    - Configure Attack Surface Reduction rules: Enabled
    - Block executable content from email and webmail: Block
    - Block Office applications from creating child processes: Block
    - Block credential stealing from Windows lsass: Block
```

**Policy 2: Remote Desktop**

```yaml
Computer Configuration → Administrative Templates → Windows Components → Remote Desktop Services:
  Security:
    - Require use of specific security layer: SSL (TLS 1.0)
    - Require user authentication using NLA: Enabled
    - Set client connection encryption level: High
```

**Policy 3: Microsoft Edge**

```yaml
Computer Configuration → Microsoft Edge:
  - Configure Do Not Track: Enabled
  - Enable saving passwords to the password manager: Disabled
  - Control which extensions cannot be installed: (list malicious extensions)
  - SmartScreen settings: Enabled
```

---

## Phase 4: Custom Configurations

### Step 4.1: Custom OMA-URI Policies

For advanced scenarios not covered by templates.

**Example: Configure Windows Hello for Business**

```yaml
Platform: Windows 10 and later
Profile type: Templates → Custom

Custom Configuration:
  Name: EnableWindowsHello
  Description: Force Windows Hello enrollment
  OMA-URI: ./Device/Vendor/MSFT/PassportForWork/{TenantID}/Policies/UsePassportForWork
  Data type: Boolean
  Value: True
```

**Example: Disable Windows Store**

```yaml
OMA-URI: ./Vendor/MSFT/Policy/Config/ApplicationManagement/AllowAppStoreAutoUpdate
Data type: Integer
Value: 0
```

**Example: Custom Start Menu Layout**

```yaml
OMA-URI: ./Vendor/MSFT/Policy/Config/Start/StartLayout
Data type: String
Value: (XML content of start layout)
```

### Step 4.2: PowerShell Scripts

Deploy PowerShell scripts to devices.

**Create Script:**

1. **Devices → Scripts and remediations → Platform scripts**
2. Click **Add → Windows 10 and later**
3. Configure:

```yaml
Name: Configure Network Settings
Description: Custom network configuration script

Script settings:
  Script location: (upload .ps1 file)
  Run script in 64-bit PowerShell: Yes
  Run script as Logged-on user: No (run as system)
  Enforce script signature check: No
  
Assignments:
  Include: All Devices
```

**Example Script:**

```powershell
# Example: Disable IPv6
Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

# Example: Configure DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("8.8.8.8","8.8.4.4")

# Example: Configure Power Settings
powercfg /change monitor-timeout-ac 15
powercfg /change standby-timeout-ac 30
```

---

## Common Policy Examples

### Example 1: Standard Corporate Workstation

**Profile Set:**

1. **Device Restrictions**
   - Password requirements
   - Block USB storage
   - Block camera
   - Lock screen timeout

2. **WiFi Configuration**
   - Corporate SSID
   - WPA2-Enterprise
   - Auto-connect

3. **VPN Configuration**
   - Always-on VPN
   - Split tunneling
   - Certificate-based auth

4. **Windows Update**
   - Defer feature updates 30 days
   - Defer quality updates 7 days
   - Active hours: 8 AM - 6 PM
   - Install time: 3 AM

5. **BitLocker**
   - XTS-AES 256-bit
   - TPM + PIN
   - Recovery key to Azure AD

### Example 2: Kiosk Device

**Profile Set:**

1. **Kiosk Configuration**
   ```yaml
   Kiosk mode: Single app kiosk
   User logon type: Auto logon
   Application type: Store app
   App user model ID: (your app ID)
   
   Maintenance window:
     Start time: 2 AM
     Duration: 4 hours
   ```

2. **Device Restrictions**
   ```yaml
   Block all settings access: Block
   Block task manager: Block
   Block sign out: Block
   Block Windows Spotlight: Block
   Block action center: Block
   ```

3. **Network Configuration**
   - WiFi auto-connect
   - No VPN
   - Proxy if needed

### Example 3: Remote Worker Laptop

**Profile Set:**

1. **Device Restrictions**
   - Strong password: 12 characters
   - BitLocker required
   - Screen lock: 3 minutes
   - Allow location services

2. **VPN Configuration**
   - Always-on VPN
   - IKEv2 connection
   - Certificate authentication
   - Split tunneling enabled

3. **WiFi Configuration**
   - Corporate office networks
   - Auto-connect when in range

4. **Windows Update**
   - Defer updates: 14 days
   - Flexible active hours
   - Download over metered: No

---

## Best Practices

### Policy Design Best Practices

1. **Start Simple**
   - Begin with essential policies
   - Add complexity gradually
   - Test each policy before deploying

2. **Use Meaningful Names**
   ```
   Good: "Windows Update - Standard Workstations"
   Bad: "Policy 1"
   ```

3. **Add Descriptions**
   ```yaml
   Description: Windows Update settings for standard corporate workstations. 
   Defers feature updates 30 days, quality updates 7 days. Active hours 8AM-6PM. 
   Created: 2024-11-20. Owner: IT Team.
   ```

4. **Group Similar Settings**
   - Create focused policies
   - Don't create one massive policy
   - Example: Separate Windows Update from BitLocker

5. **Use Groups Effectively**
   ```
   All Devices → Base security policies
   Department Groups → Specific apps/settings
   Test Group → Pilot new policies
   ```

### Assignment Best Practices

1. **Assignment Strategy**
   ```
   Layer 1: All Devices (base security)
   Layer 2: Device Type (laptop vs desktop)
   Layer 3: Department (finance, IT, etc.)
   Layer 4: Role (executives, standard users)
   ```

2. **Use Exclusions Wisely**
   - Exclude test devices from production policies
   - Exclude kiosks from user-focused policies
   - Exclude executives if they need exceptions

3. **Pilot First**
   ```
   1. Create policy
   2. Assign to Test Devices group
   3. Monitor for 1 week
   4. Fix any issues
   5. Roll out to production
   ```

### Conflict Resolution

**When policies conflict:**

1. **Settings Catalog** > Configuration Profiles
2. **Last applied** policy typically wins
3. **More restrictive** setting may win
4. **Check conflict reports** in Intune

**Avoid Conflicts:**
- Don't configure same setting in multiple policies
- Use Settings Catalog for new policies
- Document which policy controls which settings

### Monitoring and Maintenance

1. **Regular Reviews**
   - Monthly: Check policy compliance
   - Quarterly: Review and update policies
   - Yearly: Full policy audit

2. **Monitor Reports**
   ```
   Intune → Devices → Monitor → Assignment status
   Check for:
   - Policies pending
   - Failed deployments
   - Devices not compliant
   ```

3. **Keep Documentation**
   ```markdown
   Policy: Windows Update Settings
   Created: 2024-11-20
   Last Modified: 2024-11-20
   Owner: IT Team
   Purpose: Control Windows Update behavior
   Assigned To: All Devices
   Dependencies: None
   Related Policies: None
   ```

---

## Troubleshooting

### Issue 1: Policy Not Applying to Device

**Check:**

1. **Device sync status**
   ```
   On device: Settings → Accounts → Access work or school → Info → Sync
   ```

2. **Assignment status**
   ```
   Intune → Policy → Device status
   Check if device is in assigned group
   ```

3. **Conflicts**
   ```
   Intune → Devices → [Device] → Device configuration
   Look for conflict warnings
   ```

4. **Policy refresh**
   ```powershell
   # Force policy refresh on device
   Get-ScheduledTask | Where-Object {$_.TaskName -like "*PushLaunch*"} | Start-ScheduledTask
   ```

### Issue 2: Settings Revert After Applying

**Causes:**
- Conflicting policies
- User is admin and changing settings
- Another management tool (GPO)

**Solutions:**

1. **Check for conflicts**
2. **Set user as Standard (not admin)**
3. **Verify no GPO overlap**
4. **Use "Configure" not "Not configured"**

### Issue 3: Custom OMA-URI Fails

**Common Errors:**

1. **Wrong data type**
   ```
   Integer vs String
   Solution: Check CSP documentation
   ```

2. **Wrong OMA-URI path**
   ```
   ./Device/... vs ./User/... vs ./Vendor/...
   Solution: Use correct path from docs
   ```

3. **Invalid value**
   ```
   Solution: Test value format
   ```

### Issue 4: Script Execution Failure

**Check:**

1. **Execution policy**
   ```powershell
   Get-ExecutionPolicy
   # Should be: Bypass or RemoteSigned
   ```

2. **Script errors**
   ```
   Intune → Scripts → [Script] → Device status
   View error messages
   ```

3. **Permissions**
   ```
   Run as: System vs User
   Ensure correct permissions
   ```

---

## Policy Export/Import

### Export Policies (for backup or migration)

**Using PowerShell:**

```powershell
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All"

# Export all policies
$policies = Get-MgDeviceManagementDeviceConfiguration

foreach ($policy in $policies) {
    $fileName = "$($policy.displayName).json"
    $policy | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\policies\$fileName"
}

Write-Host "Exported $($policies.Count) policies"
```

### Import Policies

```powershell
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"

# Import from JSON
$jsonFiles = Get-ChildItem -Path ".\policies" -Filter "*.json"

foreach ($file in $jsonFiles) {
    $policy = Get-Content -Path $file.FullName | ConvertFrom-Json
    
    # Remove properties that can't be imported
    $policy.PSObject.Properties.Remove('id')
    $policy.PSObject.Properties.Remove('createdDateTime')
    $policy.PSObject.Properties.Remove('lastModifiedDateTime')
    
    # Create new policy
    New-MgDeviceManagementDeviceConfiguration -BodyParameter $policy
    
    Write-Host "Imported: $($file.Name)"
}
```

---

## Validation Checklist

Before moving to next phase:

- [x] At least 3 Configuration Profiles created
- [x] At least 2 Settings Catalog policies created
- [x] Policies assigned to appropriate groups
- [x] Test device receives policies successfully
- [x] No policy conflicts detected
- [x] Policies documented
- [x] Backup/export of policies completed

---

## Next Steps

Once configuration policies are complete, proceed to:

📄 **[04-security-baseline.md](./04-security-baseline.md)** - Configure Endpoint Security, BitLocker, Firewall, and security baselines

---

## Additional Resources

### Microsoft Documentation
- [Configuration Profiles Overview](https://learn.microsoft.com/mem/intune/configuration/device-profiles)
- [Settings Catalog](https://learn.microsoft.com/mem/intune/configuration/settings-catalog)
- [Administrative Templates](https://learn.microsoft.com/mem/intune/configuration/administrative-templates-windows)
- [OMA-URI Settings](https://learn.microsoft.com/mem/intune/configuration/custom-settings-windows-10)

### CSP Documentation
- [Configuration Service Provider Reference](https://learn.microsoft.com/windows/client-management/mdm/configuration-service-provider-reference)
- [Policy CSP](https://learn.microsoft.com/windows/client-management/mdm/policy-configuration-service-provider)

### Useful Tools
- **Intune Settings Search**: https://intunegraph.com/
- **CSP Browser**: https://csp.microsoft.com/

---

*Last Updated: November 2024*
*Author: Vidal Reñao Lopelo*
*Repository: https://github.com/vidal-renao/intune-autopilot-lab*
