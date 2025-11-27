# Windows Autopilot Configuration Guide

> Complete guide for configuring Windows Autopilot deployment profiles, device groups, and deployment settings.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Understanding Autopilot Components](#understanding-autopilot-components)
- [Phase 1: Create Dynamic Device Groups](#phase-1-create-dynamic-device-groups)
- [Phase 2: Create Autopilot Deployment Profile](#phase-2-create-autopilot-deployment-profile)
- [Phase 3: Assign Profile to Groups](#phase-3-assign-profile-to-groups)
- [Phase 4: Configure Enrollment Status Page](#phase-4-configure-enrollment-status-page)
- [Phase 5: Test Deployment](#phase-5-test-deployment)
- [Advanced Configurations](#advanced-configurations)
- [Troubleshooting](#troubleshooting)

---

## Overview

Windows Autopilot transforms device deployment by enabling zero-touch provisioning. This guide covers:

- ✅ Creating deployment profiles
- ✅ Configuring OOBE (Out-of-Box Experience)
- ✅ Setting up dynamic device groups
- ✅ Configuring enrollment status page
- ✅ Testing the complete deployment flow

**Estimated Time**: 30-45 minutes

---

## Prerequisites

Before starting, ensure you have completed:

- ✅ **[01-environment-setup.md](./01-environment-setup.md)** - Tenant, Entra ID, and Intune configured
- ✅ Microsoft 365 license with Intune
- ✅ Global Administrator or Intune Administrator role
- ✅ At least one test device ready

**Required Access:**
- Intune Admin Center: https://intune.microsoft.com
- Entra Admin Center: https://entra.microsoft.com

---

## Understanding Autopilot Components

### Autopilot Architecture

```
┌─────────────────────────────────────────────────┐
│          Autopilot Service (Cloud)              │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐  ┌──────────────┐           │
│  │   Device     │  │  Deployment  │           │
│  │  Identity    │  │   Profile    │           │
│  │  (HW Hash)   │  │              │           │
│  └──────────────┘  └──────────────┘           │
│         │                  │                   │
│         └──────────────────┘                   │
│                    │                           │
└────────────────────┼───────────────────────────┘
                     │
                     ▼
           ┌─────────────────┐
           │  Physical Device │
           │   - Serial #     │
           │   - HW Hash      │
           │   - Group Tag    │
           └─────────────────┘
                     │
                     ▼
           ┌─────────────────┐
           │  Dynamic Group   │
           │  (Auto-assign)   │
           └─────────────────┘
                     │
                     ▼
           ┌─────────────────┐
           │ Profile Applied  │
           │  - OOBE Settings │
           │  - User Type     │
           │  - Device Name   │
           └─────────────────┘
```

### Key Components

| Component | Purpose | Example |
|-----------|---------|---------|
| **Hardware Hash** | Unique device identifier | Used to register device in Autopilot |
| **Deployment Profile** | OOBE configuration | User-driven, Self-deploying, etc. |
| **Dynamic Group** | Auto-assignment | All Autopilot devices get profile automatically |
| **Group Tag** | Device categorization | Finance, IT, Executive, etc. |
| **ESP** | Enrollment Status Page | Shows progress during setup |

### Deployment Modes

**User-driven Mode** (Most Common)
- User initiates deployment
- Signs in with corporate credentials
- Device joins Entra ID
- Standard or Administrator user

**Self-deploying Mode**
- No user interaction
- For kiosks, digital signage
- Joins Entra ID automatically
- No user assignment

**Pre-provisioning (White Glove)**
- Technician pre-configures device
- User receives ready device
- Minimal end-user setup

---

## Phase 1: Create Dynamic Device Groups

Dynamic groups automatically assign devices to deployment profiles based on rules.

### Step 1.1: Create Autopilot Devices Group

**Via Entra Admin Center:**

1. Go to **https://entra.microsoft.com**
2. Navigate to **Groups → All groups**
3. Click **New group**
4. Configure:

```yaml
Group type: Security
Group name: Autopilot Devices
Group description: All devices registered in Windows Autopilot
Membership type: Dynamic Device
Owners: admin@yourcompany.onmicrosoft.com
```

5. Click **Add dynamic query**
6. Click **Edit** (top right)
7. Paste this rule:

```
(device.devicePhysicalIds -any (_ -contains "[ZTDId]"))
```

8. Click **Save**
9. Click **Create**

**Explanation:**
- `device.devicePhysicalIds`: Device physical identifiers
- `ZTDId`: Zero Touch Deployment ID (Autopilot identifier)
- This rule matches ANY device with Autopilot registration

**PowerShell Method:**

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All"

$groupParams = @{
    DisplayName = "Autopilot Devices"
    Description = "All devices registered in Windows Autopilot"
    GroupTypes = @("DynamicMembership")
    MailEnabled = $false
    MailNickname = "AutopilotDevices"
    SecurityEnabled = $true
    MembershipRule = '(device.devicePhysicalIds -any (_ -contains "[ZTDId]"))'
    MembershipRuleProcessingState = "On"
}

New-MgGroup @groupParams
```

### Step 1.2: Create Department-Specific Groups (Optional)

**Example: Finance Department Devices**

```yaml
Group name: Finance Autopilot Devices
Membership type: Dynamic Device
Rule: (device.devicePhysicalIds -any (_ -contains "[OrderID]:Finance"))
```

**Example: Executive Devices**

```yaml
Group name: Executive Autopilot Devices  
Membership type: Dynamic Device
Rule: (device.devicePhysicalIds -any (_ -contains "[OrderID]:Executive"))
```

**How to use Group Tags:**
- When extracting hardware hash, add `-GroupTag "Finance"`
- Device automatically enters Finance group
- Receives Finance-specific profile

### Step 1.3: Verify Dynamic Group

**Check Group Processing:**

1. Go to **Entra ID → Groups → Autopilot Devices**
2. Click **Dynamic membership rules**
3. Verify:
   - Rule syntax: Correct
   - Processing state: **On**
   - Errors: None

**Note**: Dynamic group processing can take up to 24 hours for first evaluation.

---

## Phase 2: Create Autopilot Deployment Profile

### Step 2.1: Access Autopilot Settings

1. Go to **https://intune.microsoft.com**
2. Navigate to **Devices → Windows → Windows enrollment**
3. Click **Deployment Profiles**
4. Click **Create profile → Windows PC**

### Step 2.2: Configure Profile - Basics

```yaml
Name: Autopilot Standard User Setup
Description: User-driven Autopilot deployment for standard employees with Entra join
```

Click **Next**

### Step 2.3: Configure Profile - Out-of-box experience (OOBE)

**Deployment mode:**
```yaml
Deployment mode: User-Driven
Join to Azure AD as: Azure AD joined
Microsoft Software License Terms: Hide
Privacy settings: Hide
Hide change account options: Hide
User account type: Standard
Allow pre-provisioned deployment: No
Language (Region): Operating system default
Automatically configure keyboard: Yes
Apply device name template: Yes
```

**Device Name Template:**
```
LAB-%SERIAL%
```

**Template Variables:**
- `%SERIAL%`: Device serial number
- `%RAND:5%`: 5 random characters
- Example result: `LAB-ABC123456`

**OOBE Settings Explained:**

| Setting | Recommended | Reason |
|---------|-------------|--------|
| **License Terms** | Hide | Streamline OOBE |
| **Privacy Settings** | Hide | Reduce user confusion |
| **Change Account** | Hide | Prevent wrong account usage |
| **User Type** | Standard | Security best practice (not admin) |
| **Device Name Template** | Yes | Consistent naming |

Click **Next**

### Step 2.4: Configure Scope Tags (Optional)

If using scope tags for RBAC:
```yaml
Scope tags: Default
```

Click **Next**

### Step 2.5: Assign to Groups

**Include:**
- Select **Autopilot Devices** group

**Exclude:**
- None (or specific groups if needed)

Click **Next**

### Step 2.6: Review and Create

Review all settings:
```yaml
Summary:
  Name: Autopilot Standard User Setup
  Deployment mode: User-Driven
  Join type: Azure AD joined
  User type: Standard
  Device name: LAB-%SERIAL%
  Assigned to: Autopilot Devices
```

Click **Create**

**✅ Result**: Deployment profile created and assigned

### Step 2.7: Complete JSON Configuration

For reference, here's the complete profile structure:

```json
{
  "@odata.type": "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile",
  "displayName": "Autopilot Standard User Setup",
  "description": "User-driven Autopilot deployment for standard employees with Entra join",
  "language": "os-default",
  "outOfBoxExperienceSettings": {
    "hidePrivacySettings": true,
    "hideEULA": true,
    "userType": "standard",
    "deviceUsageType": "singleUser",
    "skipKeyboardSelectionPage": true,
    "hideEscapeLink": true
  },
  "deviceNameTemplate": "LAB-%SERIAL%",
  "deviceType": "windowsPc",
  "enableWhiteGlove": false,
  "roleScopeTagIds": ["0"],
  "managementServiceAppId": "0000000a-0000-0000-c000-000000000000"
}
```

---

## Phase 3: Assign Profile to Groups

### Step 3.1: Verify Assignment

1. Go to **Intune → Devices → Windows → Deployment Profiles**
2. Click on **"Autopilot Standard User Setup"**
3. Click **Properties**
4. Verify **Assignments** section shows:
   - Assigned to: **Autopilot Devices**
   - Mode: Include

### Step 3.2: Check Assignment Status

1. In the profile, click **Device status**
2. You should see:
   - Assigned: 0 (initially, before devices are added)
   - Succeeded: 0
   - Failed: 0

**Note**: Numbers update after devices are imported and synced

### Step 3.3: Create Additional Profiles (Optional)

**Example: Executive Profile**

```yaml
Name: Autopilot Executive Setup
User account type: Administrator
Device name template: EXEC-%SERIAL%
Assigned to: Executive Autopilot Devices
```

**Example: Kiosk Profile**

```yaml
Name: Autopilot Kiosk Setup
Deployment mode: Self-deploying
User account type: N/A
Device name template: KIOSK-%RAND:5%
Assigned to: Kiosk Devices
```

---

## Phase 4: Configure Enrollment Status Page (ESP)

The ESP shows deployment progress to users during Autopilot.

### Step 4.1: Access ESP Settings

1. Go to **Intune → Devices → Windows → Windows enrollment**
2. Click **Enrollment Status Page**
3. Click **Default** profile or **Create new**

### Step 4.2: Configure ESP Settings

**Settings:**

```yaml
Name: Default Enrollment Status Page
Description: Shows deployment progress during Autopilot

Show app and profile configuration progress: Yes
Show an error when installation takes longer than specified number of minutes: 60

Show custom message when time limit error occurs: No

Allow users to collect logs about installation errors: Yes
Only show page to devices provisioned by out-of-box experience (OOBE): Yes

Block device use until all apps and profiles are installed: 
  - Device setup: Yes
  - User setup: Yes
  
Allow users to reset device if installation error occurs: No
Allow users to use device if installation error occurs: No

Block device use until these required apps are installed if they are assigned to the user/device:
  - Select specific apps (if any required)
```

**ESP Settings Explained:**

| Setting | Recommended | Reason |
|---------|-------------|--------|
| **Show progress** | Yes | User visibility |
| **Timeout** | 60 minutes | Enough for most deployments |
| **Block device use** | Yes | Ensure complete setup |
| **Allow reset on error** | No | Prevent accidental resets |
| **Required apps** | Select critical apps | Block until installed |

### Step 4.3: Assign ESP to Groups

**Assignments:**
```yaml
Include: All devices
Exclude: None
```

Click **Save**

### Step 4.4: Test ESP Display

During Autopilot deployment, users will see:

```
┌────────────────────────────────────┐
│  Setting up your device            │
│                                    │
│  Device preparation    [████████]  │
│  Device setup          [████░░░░]  │
│  Account setup         [░░░░░░░░]  │
│                                    │
│  Installing apps and policies...   │
│  This might take a few minutes     │
└────────────────────────────────────┘
```

---

## Phase 5: Test Deployment

### Step 5.1: Import Test Device

**Prerequisites:**
- Windows 11 Pro VM or physical device
- Device not yet configured
- Internet connectivity

**Extract and Import Hardware Hash:**

See **[06-6-methods-hardware-hash.md](./06-6-methods-hardware-hash.md)** for detailed methods.

**Quick Method (if Windows already installed):**

```powershell
# On the device, run as Administrator
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile $env:USERPROFILE\Desktop\AutopilotHWID.csv
```

**Import to Intune:**

1. Go to **Intune → Devices → Windows → Windows enrollment → Devices**
2. Click **Import**
3. Select the CSV file
4. Click **Import**
5. Wait 15-20 minutes for sync

### Step 5.2: Verify Device Registration

**Check Registration:**

1. Go to **Intune → Devices → Windows → Windows enrollment → Devices**
2. Find your device by serial number
3. Verify:
   - **Profile status**: Assigned
   - **Deployment profile**: Autopilot Standard User Setup
   - **Group tag**: (if you added one)

**PowerShell Verification:**

```powershell
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"

$serial = "YOUR-SERIAL-NUMBER"
$device = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq '$serial'"

if ($device) {
    Write-Host "✅ Device registered in Autopilot" -ForegroundColor Green
    Write-Host "Profile Status: $($device.deploymentProfileAssignmentStatus)" -ForegroundColor Cyan
    Write-Host "Group Tag: $($device.groupTag)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Device NOT found in Autopilot" -ForegroundColor Red
}
```

### Step 5.3: Verify Dynamic Group Membership

**Check Group:**

1. Go to **Entra ID → Groups → Autopilot Devices**
2. Click **Members**
3. Wait for dynamic group evaluation (can take up to 24 hours)
4. Device should appear in members list

**Force Group Update (if needed):**

```powershell
# Trigger dynamic group processing
$groupId = (Get-MgGroup -Filter "displayName eq 'Autopilot Devices'").Id
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/evaluate-dynamicMembership"
```

### Step 5.4: Reset Device for Autopilot

**On the test device:**

**Method 1 - Via Settings (Recommended):**

1. Go to **Settings → System → Recovery**
2. Click **Reset this PC**
3. Select **Remove everything**
4. Select **Cloud download** (recommended)
5. Click **Reset**

**Method 2 - Via PowerShell:**

```powershell
systemreset -cleanpc
```

**Method 3 - During OOBE:**

If device is at initial setup:
- It should automatically detect Autopilot
- No manual reset needed

### Step 5.5: Watch Autopilot Deployment

**User Experience:**

1. **Device boots** → Shows Windows logo
2. **Language selection** → Autopilot detected (logo changes to company branding if configured)
3. **Company sign-in screen** → "Let's set things up for your work or school"
4. **User enters credentials** → `user@yourcompany.onmicrosoft.com`
5. **MFA prompt** → If configured
6. **Enrollment Status Page** → Shows progress:
   - Device preparation
   - Device setup (Intune policies)
   - Account setup (user-specific settings)
7. **Desktop** → User lands on configured desktop

**Expected Timeline:**
- Account sign-in: 1-2 minutes
- Device preparation: 2-3 minutes
- Device setup: 5-10 minutes
- Account setup: 2-5 minutes
- **Total: 10-20 minutes**

### Step 5.6: Verify Successful Deployment

**On the device, check:**

```powershell
# Check Entra ID join
dsregcmd /status

# Should show:
# AzureAdJoined : YES
# DeviceId : xxx-xxx-xxx

# Check Intune enrollment
Get-WmiObject -Namespace root\cimv2\mdm\dmmap -Class MDM_DevDetail_Ext01

# Check device name
hostname
# Should be: LAB-SERIALNUMBER
```

**In Intune Portal:**

1. Go to **Devices → All devices**
2. Find your device (name: LAB-SERIALNUMBER)
3. Verify:
   - **Managed by**: Intune
   - **Ownership**: Corporate
   - **Compliance**: Compliant (or In grace period)
   - **Last check-in**: Recent (within last hour)

---

## Advanced Configurations

### Configuration 1: Multiple Deployment Profiles

**Scenario**: Different profiles for different departments

```yaml
Profile 1: Standard Employees
  Name: Autopilot Standard Setup
  User Type: Standard
  Device Name: LAB-%SERIAL%
  Assigned to: Autopilot Devices

Profile 2: IT Department
  Name: Autopilot IT Admin Setup
  User Type: Administrator
  Device Name: IT-%SERIAL%
  Assigned to: IT Autopilot Devices (Group Tag: IT)

Profile 3: Executives
  Name: Autopilot Executive Setup
  User Type: Administrator
  Device Name: EXEC-%SERIAL%
  Assigned to: Executive Devices (Group Tag: Executive)
```

**Dynamic Group Rules:**

```
IT Devices:
(device.devicePhysicalIds -any (_ -contains "[OrderID]:IT"))

Executive Devices:
(device.devicePhysicalIds -any (_ -contains "[OrderID]:Executive"))
```

### Configuration 2: Pre-Provisioning (White Glove)

**Use Case**: IT pre-configures devices before shipping to users

**Profile Settings:**

```yaml
Allow pre-provisioned deployment: Yes
Deployment mode: User-Driven
```

**Workflow:**

1. IT imports device hash
2. IT technician powers on device
3. Presses Windows key 5 times during OOBE
4. Signs in with tech account
5. Device provisions (apps, policies install)
6. Tech reseals device
7. Ships to user
8. User signs in → instant setup

### Configuration 3: Self-Deploying Mode

**Use Case**: Kiosks, conference room devices, digital signage

**Profile Settings:**

```yaml
Deployment mode: Self-deploying
Join to Azure AD as: Azure AD joined
User account type: N/A (no user assignment)
Device name template: KIOSK-%RAND:8%
```

**Workflow:**

1. Device boots
2. Connects to network
3. Contacts Autopilot service
4. Auto-provisions without user interaction
5. Ready for shared use

### Configuration 4: Hybrid Azure AD Join

**Use Case**: Organizations with on-premises Active Directory

```yaml
Join to Azure AD as: Hybrid Azure AD joined
ODJ Connector: Required (installed on-premises)
```

**Requirements:**
- On-premises AD
- Azure AD Connect
- Intune Connector for Active Directory

---

## Troubleshooting

### Issue 1: Device Not Showing in Autopilot

**Symptoms:**
- Device not in Autopilot devices list after import
- CSV import succeeded but no device visible

**Solutions:**

1. **Wait for sync** (15-20 minutes)
2. **Force sync**:
   - Intune → Devices → All devices → Sync
3. **Check CSV format**:
   ```powershell
   Import-Csv .\AutopilotHWID.csv | Format-Table
   # Verify columns: Device Serial Number, Windows Product ID, Hardware Hash
   ```
4. **Re-import device**
5. **Check tenant ID** in CSV matches your tenant

### Issue 2: Profile Not Assigned to Device

**Symptoms:**
- Device in Autopilot but Profile Status = "Not assigned"
- Device not in dynamic group

**Solutions:**

1. **Check dynamic group rule**:
   ```
   (device.devicePhysicalIds -any (_ -contains "[ZTDId]"))
   ```
2. **Verify group processing state** = On
3. **Wait up to 24 hours** for first dynamic evaluation
4. **Check profile assignment**:
   - Profile → Properties → Assignments
   - Verify group is included
5. **Force group re-evaluation**

### Issue 3: Autopilot Not Triggering During OOBE

**Symptoms:**
- Device boots to standard Windows setup
- No company branding
- Not detecting Autopilot

**Solutions:**

1. **Verify device is Entra ID ready**:
   - Check if it's already joined to domain
   - Must be clean Windows installation
2. **Check network connectivity**
3. **Wait 5 minutes** at language screen
4. **Check device registration**:
   ```powershell
   # From another PC
   Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq 'SERIAL'"
   ```
5. **Re-extract hardware hash** and re-import

### Issue 4: ESP Timeout

**Symptoms:**
- Enrollment Status Page shows timeout error
- "Setup is taking longer than expected"

**Solutions:**

1. **Increase timeout** in ESP settings (60 → 90 minutes)
2. **Check app installation failures**:
   - Intune → Devices → Device → Managed Apps
3. **Check policy conflicts**
4. **Verify network speed**
5. **Remove non-critical apps** from required list

### Issue 5: Device Name Template Not Applied

**Symptoms:**
- Device name is default (DESKTOP-XXXXXX)
- Template not working

**Solutions:**

1. **Verify template syntax**: `LAB-%SERIAL%`
2. **Check profile assignment**
3. **Limitations**:
   - 15 character limit
   - No special characters except hyphen
4. **Example working templates**:
   - `PC-%SERIAL%`
   - `WIN-%RAND:5%`
   - `LAB-%SERIAL:6%` (first 6 chars of serial)

### Issue 6: User Gets Admin Rights Despite Standard Setting

**Symptoms:**
- User account type set to Standard
- User has admin rights

**Solutions:**

1. **Check conflicting policies**:
   - Configuration profiles making user admin
   - Group memberships
2. **Verify profile setting**: User account type = **Standard**
3. **Remove user from local administrators group**:
   ```powershell
   Remove-LocalGroupMember -Group "Administrators" -Member "DOMAIN\User"
   ```

---

## Validation Checklist

Before moving to next phase, verify:

- [x] Dynamic device group created with correct rule
- [x] Autopilot deployment profile created
- [x] Profile assigned to dynamic group
- [x] Enrollment Status Page configured
- [x] Test device imported successfully
- [x] Device shows "Profile assigned" status
- [x] Device appears in dynamic group members
- [x] Test deployment completed successfully
- [x] Device has correct name (template applied)
- [x] User has correct permissions (Standard/Admin)
- [x] Device is Entra ID joined
- [x] Device is Intune enrolled and compliant

---

## Next Steps

Once Autopilot is configured and tested, proceed to:

📄 **[03-policy-templates.md](./03-policy-templates.md)** - Configure device policies, apps, and settings

---

## Additional Resources

### Microsoft Documentation
- [Windows Autopilot Overview](https://learn.microsoft.com/windows/deployment/windows-autopilot/)
- [Autopilot Deployment Scenarios](https://learn.microsoft.com/windows/deployment/windows-autopilot/windows-autopilot-scenarios)
- [Enrollment Status Page](https://learn.microsoft.com/mem/intune/enrollment/windows-enrollment-status)

### PowerShell Management
```powershell
# Get all Autopilot devices
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity

# Get specific device
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq 'ABC123'"

# Get deployment profiles
Get-MgDeviceManagementWindowsAutopilotDeploymentProfile

# Sync Autopilot devices
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotSettings/sync"
```

### Useful Links
- **Autopilot Device Import**: https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/WindowsEnrollmentMenu/~/windowsAutopilotDevices
- **Deployment Profiles**: https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/WindowsEnrollmentMenu/~/windowsAutopilotProfiles
- **ESP Configuration**: https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/WindowsEnrollmentMenu/~/enrollmentStatusPage

---

*Last Updated: November 2024*
*Author: Vidal Reñao Lopelo*
*Repository: https://github.com/vidal-renao/intune-autopilot-lab*
