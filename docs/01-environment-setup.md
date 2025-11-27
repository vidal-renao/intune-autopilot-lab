# Environment Setup Guide

> Complete guide for setting up Microsoft 365 tenant, Entra ID, and Intune for Windows Autopilot deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Phase 1: Microsoft 365 Tenant Setup](#phase-1-microsoft-365-tenant-setup)
- [Phase 2: Microsoft Entra ID Configuration](#phase-2-microsoft-entra-id-configuration)
- [Phase 3: Microsoft Intune Setup](#phase-3-microsoft-intune-setup)
- [Phase 4: Licensing](#phase-4-licensing)
- [Phase 5: Initial Validation](#phase-5-initial-validation)
- [Troubleshooting](#troubleshooting)

---

## Overview

This guide walks through the complete initial setup required for a Windows Autopilot environment. By the end of this guide, you will have:

- ✅ Microsoft 365 tenant configured
- ✅ Entra ID (Azure AD) ready for identity management
- ✅ Intune enabled for device management
- ✅ Users and groups created
- ✅ Proper licensing assigned
- ✅ MDM scope configured

**Estimated Time**: 1-2 hours

---

## Prerequisites

### Required Resources

- **Microsoft Account** (for admin)
- **Credit card** (for trial or subscription)
- **Domain name** (optional, can use .onmicrosoft.com)
- **Email address** (for notifications)

### Technical Requirements

- **Web browser** (Edge, Chrome, Firefox)
- **Internet connection**
- **Basic understanding** of:
  - Cloud services
  - Identity management
  - Device management concepts

### Lab Environment (Optional)

For testing purposes:
- **VMware Workstation** or Hyper-V
- **Windows 11 Pro ISO**
- At least **4GB RAM** per VM
- **50GB disk space** per VM

---

## Phase 1: Microsoft 365 Tenant Setup

### Step 1.1: Create Microsoft 365 Tenant

#### Option A: Business Premium Trial (Recommended for Labs)

1. Go to: **https://www.microsoft.com/microsoft-365/business/microsoft-365-business-premium**
2. Click **"Try for free"** or **"Buy now"**
3. Fill in the required information:

```yaml
Business Information:
  Email: your.email@gmail.com
  Business Name: Your Company Name (e.g., "Vidal Cloud Solutions")
  Organization Size: 1-25 employees
  Country/Region: Your country

Admin Account:
  Username: admin (will become admin@yourcompany.onmicrosoft.com)
  Domain: yourcompany.onmicrosoft.com
  Password: (create a strong password)
  
Verification:
  Phone Number: Your phone (for SMS verification)
```

4. Complete verification (SMS code)
5. Accept terms and conditions
6. Wait for tenant provisioning (2-5 minutes)

#### Option B: Enterprise Trial (E3 or E5)

1. Go to: **https://www.microsoft.com/microsoft-365/enterprise**
2. Select **E3** or **E5** trial
3. Follow similar steps as Business Premium

**✅ Result**: You now have a Microsoft 365 tenant

**Save these credentials securely:**
```
Tenant Name: yourcompany.onmicrosoft.com
Admin UPN: admin@yourcompany.onmicrosoft.com
Password: [your secure password]
Tenant ID: [will be available in Entra ID portal]
```

### Step 1.2: Access Microsoft 365 Admin Center

1. Go to: **https://admin.microsoft.com**
2. Sign in with your admin credentials
3. Complete the setup wizard (optional):
   - Add domain (skip for now if using .onmicrosoft.com)
   - Install Office apps (optional)
   - Migrate email (skip)

**✅ Verification**: You should see the Microsoft 365 Admin Center dashboard

---

## Phase 2: Microsoft Entra ID Configuration

### Step 2.1: Access Entra Admin Center

1. Go to: **https://entra.microsoft.com**
2. Sign in with admin credentials
3. Explore the interface:
   - **Overview**: Tenant information
   - **Users**: User management
   - **Groups**: Group management
   - **Devices**: Device registration

### Step 2.2: Verify Tenant Information

1. In Entra Admin Center, go to **Overview**
2. Note down:

```yaml
Tenant Information:
  Tenant Name: yourcompany.onmicrosoft.com
  Tenant ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Primary Domain: yourcompany.onmicrosoft.com
  Directory Quota: 50,000 objects (default)
```

**Save your Tenant ID** - You'll need it for various configurations.

### Step 2.3: Create Organizational Structure

#### Create Users

**Admin User (already exists):**
```
Name: Global Administrator
UPN: admin@yourcompany.onmicrosoft.com
Role: Global Administrator
```

**Create Test User:**

1. Go to **Users → All users**
2. Click **New user → Create new user**
3. Fill in details:

```yaml
User Details:
  Display Name: Test User
  User Principal Name: test.user@yourcompany.onmicrosoft.com
  
Auto-generate password: Yes (or set custom)
Send password in email: (your email)

Account enabled: Yes
```

4. Click **Review + create**
5. Save the temporary password

**Create Standard User:**

1. Create another user:

```yaml
Display Name: Vidal User
UPN: vidal.user@yourcompany.onmicrosoft.com
```

**PowerShell Method (Alternative):**

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Create user
$passwordProfile = @{
    Password = "TempPassword123!"
    ForceChangePasswordNextSignIn = $true
}

$newUser = @{
    AccountEnabled = $true
    DisplayName = "Test User"
    MailNickname = "testuser"
    UserPrincipalName = "test.user@yourcompany.onmicrosoft.com"
    PasswordProfile = $passwordProfile
}

New-MgUser @newUser
```

#### Create Security Groups

**Group 1: All Autopilot Devices (Dynamic)**

1. Go to **Groups → All groups**
2. Click **New group**
3. Configure:

```yaml
Group Type: Security
Group Name: Autopilot Devices
Group Description: All devices registered in Windows Autopilot
Membership type: Dynamic Device

Dynamic membership rules:
  Rule syntax: (device.devicePhysicalIds -any (_ -contains "[ZTDId]"))
```

4. Click **Create**

**Group 2: IT Administrators**

```yaml
Group Type: Security
Group Name: IT Administrators
Membership type: Assigned
Members: admin@yourcompany.onmicrosoft.com
```

**Group 3: Standard Users**

```yaml
Group Type: Security
Group Name: Standard Users
Membership type: Assigned
Members: test.user@, vidal.user@
```

**PowerShell Method:**

```powershell
# Create dynamic device group
$dynamicRule = '(device.devicePhysicalIds -any (_ -contains "[ZTDId]"))'

$groupParams = @{
    DisplayName = "Autopilot Devices"
    Description = "All devices registered in Windows Autopilot"
    MailEnabled = $false
    MailNickname = "AutopilotDevices"
    SecurityEnabled = $true
    GroupTypes = @("DynamicMembership")
    MembershipRule = $dynamicRule
    MembershipRuleProcessingState = "On"
}

New-MgGroup @groupParams
```

### Step 2.4: Configure Multi-Factor Authentication (MFA)

**Enable MFA for Admin:**

1. Go to **Protection → Authentication methods**
2. Click **Policies**
3. Select **Microsoft Authenticator**
4. Configure:

```yaml
Enable: Yes
Target: All users (or specific groups)

Authentication mode: Any
Show application name: Yes
Show geographic location: Yes
```

5. Save

**Test MFA Setup:**

1. Open incognito/private browser
2. Go to: **https://aka.ms/mfasetup**
3. Sign in with test.user@
4. Set up Microsoft Authenticator on phone
5. Complete verification

### Step 2.5: Configure Conditional Access (Optional)

**Basic Conditional Access Policy:**

1. Go to **Protection → Conditional Access**
2. Click **New policy**
3. Configure:

```yaml
Name: Require MFA for All Users
Assignments:
  Users: All users
  Cloud apps: All cloud apps
  
Access controls:
  Grant: Require multi-factor authentication
  
Enable policy: Report-only (for testing)
```

4. Create policy

---

## Phase 3: Microsoft Intune Setup

### Step 3.1: Access Intune Admin Center

1. Go to: **https://intune.microsoft.com**
2. Sign in with admin credentials
3. Accept any initial prompts

### Step 3.2: Configure MDM Authority

**Set Intune as MDM Authority:**

1. In Intune admin center, go to **Tenant administration → Tenant status**
2. Verify **MDM authority** is set to **Microsoft Intune**

If not set:
1. Go to **Devices → Enrollment → Windows enrollment**
2. Click **Automatic Enrollment**
3. Configure MDM settings

### Step 3.3: Configure Automatic MDM Enrollment

**Link Entra ID to Intune:**

1. Go to **https://entra.microsoft.com**
2. Navigate to **Mobility (MDM and MAM) → Microsoft Intune**
3. Configure:

```yaml
MDM User Scope: All
  (or select specific groups)

MDM Terms of use URL: (default)
MDM Discovery URL: (default)
MDM Compliance URL: (default)

MAM User Scope: None (or All if needed)
```

4. Click **Save**

**PowerShell Verification:**

```powershell
Connect-MgGraph -Scopes "Device.ReadWrite.All"

# Check MDM configuration
Get-MgOrganization | Select-Object -Property MobileDeviceManagementAuthority
```

### Step 3.4: Initial Intune Configuration

**Configure Intune Tenant:**

1. Go to **Tenant administration → Tenant status**
2. Review settings:
   - Tenant status: Active
   - Connector status: Healthy
   - Service health: All services operational

**Configure Device Restrictions:**

1. Go to **Devices → Configuration profiles**
2. Verify you have access to create policies

**Configure Compliance:**

1. Go to **Devices → Compliance policies**
2. Note: We'll create policies in later guides

---

## Phase 4: Licensing

### Step 4.1: Understand License Requirements

**For Windows Autopilot, you need ONE of:**

- ✅ **Microsoft 365 Business Premium** (Recommended for SMB)
- ✅ **Microsoft 365 E3** or **E5**
- ✅ **Enterprise Mobility + Security E3** or **E5**
- ✅ **Intune standalone license**

**What Each License Includes:**

| Feature | Business Premium | E3 | E5 |
|---------|-----------------|----|----|
| Entra ID P1 | ✅ | ✅ | ✅ |
| Entra ID P2 | ❌ | ❌ | ✅ |
| Intune | ✅ | ✅ | ✅ |
| Autopilot | ✅ | ✅ | ✅ |
| Windows 10/11 Enterprise | ❌ | ✅ | ✅ |
| Microsoft 365 Apps | ✅ | ✅ | ✅ |
| Advanced Threat Protection | ❌ | ❌ | ✅ |

### Step 4.2: Assign Licenses to Users

**Via Admin Center:**

1. Go to **https://admin.microsoft.com**
2. Navigate to **Users → Active users**
3. Select a user
4. Click **Licenses and apps**
5. Check **Microsoft 365 Business Premium** (or your license)
6. Expand and verify:
   - ✅ Microsoft Intune
   - ✅ Azure Active Directory Premium P1
   - ✅ Microsoft 365 Apps

7. Click **Save changes**

**Via PowerShell:**

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All", "Organization.Read.All"

# Get available SKUs
Get-MgSubscribedSku | Select-Object SkuPartNumber, ConsumedUnits, @{N='AvailableUnits';E={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}}

# Assign license to user
$userId = "test.user@yourcompany.onmicrosoft.com"
$skuId = "O365_BUSINESS_PREMIUM" # Or your SKU

$license = @{
    AddLicenses = @(
        @{
            SkuId = (Get-MgSubscribedSku -All | Where-Object {$_.SkuPartNumber -eq $skuId}).SkuId
        }
    )
}

Set-MgUserLicense -UserId $userId -BodyParameter $license
```

### Step 4.3: Verify License Assignment

**Check in Entra ID:**

1. Go to **https://entra.microsoft.com**
2. **Users → All users → [Select user]**
3. Click **Licenses**
4. Verify licenses are assigned and active

**Verify Intune Access:**

1. User should be able to access **https://portal.manage.microsoft.com**
2. Company Portal app should work on enrolled devices

---

## Phase 5: Initial Validation

### Step 5.1: Verify Entra ID Configuration

**Run Validation Checklist:**

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All", "User.Read.All", "Group.Read.All"

# Check tenant
$tenant = Get-MgOrganization
Write-Host "Tenant: $($tenant.DisplayName)" -ForegroundColor Green
Write-Host "Tenant ID: $($tenant.Id)" -ForegroundColor Green

# Check users
$users = Get-MgUser -All
Write-Host "`nTotal Users: $($users.Count)" -ForegroundColor Cyan

# Check groups
$groups = Get-MgGroup -All
Write-Host "Total Groups: $($groups.Count)" -ForegroundColor Cyan

# Check dynamic group
$dynamicGroup = Get-MgGroup -Filter "displayName eq 'Autopilot Devices'"
if ($dynamicGroup) {
    Write-Host "`n✅ Autopilot Devices group exists" -ForegroundColor Green
    Write-Host "   Rule: $($dynamicGroup.MembershipRule)" -ForegroundColor Gray
} else {
    Write-Host "`n❌ Autopilot Devices group NOT found" -ForegroundColor Red
}
```

### Step 5.2: Verify Intune Configuration

**Checklist:**

- [ ] Can access Intune admin center
- [ ] MDM authority is set to Intune
- [ ] MDM user scope configured
- [ ] Can create configuration profiles
- [ ] Can create compliance policies
- [ ] Can access Windows enrollment section

**PowerShell Verification:**

```powershell
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All"

# Check if Intune is configured
$intuneConfig = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement"

if ($intuneConfig) {
    Write-Host "✅ Intune is configured and accessible" -ForegroundColor Green
} else {
    Write-Host "❌ Intune not accessible" -ForegroundColor Red
}
```

### Step 5.3: Test User Sign-In

**Test Procedure:**

1. Open **private/incognito browser**
2. Go to **https://portal.office.com**
3. Sign in with test user
4. Verify:
   - ✅ Can access Office apps
   - ✅ MFA prompts if configured
   - ✅ No license errors

5. Go to **https://portal.manage.microsoft.com** (Company Portal)
6. Verify user can access

### Step 5.4: Environment Summary Report

**Create Summary Document:**

```markdown
## Environment Setup Summary

**Date**: 2024-11-20
**Completed By**: Admin Name

### Tenant Information
- Tenant Name: yourcompany.onmicrosoft.com
- Tenant ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
- License: Microsoft 365 Business Premium
- Trial End Date: [if applicable]

### Users Created
- admin@yourcompany.onmicrosoft.com (Global Admin)
- test.user@yourcompany.onmicrosoft.com (Standard User)
- vidal.user@yourcompany.onmicrosoft.com (Standard User)

### Groups Created
- Autopilot Devices (Dynamic Device Group)
- IT Administrators (Security Group)
- Standard Users (Security Group)

### Configuration Status
- ✅ Entra ID configured
- ✅ Intune enabled
- ✅ MDM scope configured
- ✅ MFA enabled
- ✅ Licenses assigned
- ✅ Dynamic groups created

### Next Steps
- Configure Autopilot deployment profile
- Create configuration policies
- Set up compliance policies
- Deploy first test device
```

---

## Troubleshooting

### Issue 1: Cannot Access Intune Portal

**Symptoms:**
- Error accessing intune.microsoft.com
- "Access denied" message

**Solutions:**

1. **Check License:**
```powershell
Get-MgUserLicenseDetail -UserId "admin@yourcompany.onmicrosoft.com"
```

2. **Check Admin Role:**
   - Go to Entra ID → Users → Select user → Assigned roles
   - Ensure user has **Intune Administrator** or **Global Administrator** role

3. **Assign Intune Admin Role:**
```powershell
# Get role
$roleId = (Get-MgDirectoryRole -Filter "displayName eq 'Intune Administrator'").Id

# Assign to user
$userId = "admin@yourcompany.onmicrosoft.com"
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $roleId -BodyParameter @{"@odata.id" = "https://graph.microsoft.com/v1.0/users/$userId"}
```

### Issue 2: MDM User Scope Not Configurable

**Symptoms:**
- Cannot set MDM user scope in Entra ID
- Option is grayed out

**Solutions:**

1. **Wait for provisioning**: New tenants may take 15-30 minutes
2. **Check license**: Ensure Intune license is assigned
3. **Try Intune portal**: Configure from **Devices → Enrollment → Windows → Automatic Enrollment**

### Issue 3: Dynamic Group Not Populating

**Symptoms:**
- Autopilot Devices group shows 0 members
- Devices not appearing after import

**Solutions:**

1. **Verify rule syntax:**
```
(device.devicePhysicalIds -any (_ -contains "[ZTDId]"))
```

2. **Check processing state**: Must be "On"
3. **Wait**: Dynamic groups can take up to 24 hours to process
4. **Force sync**: Delete and recreate the dynamic rule

### Issue 4: User Cannot Access Company Portal

**Symptoms:**
- "No licenses assigned" error
- Cannot enroll device

**Solutions:**

1. **Verify license:**
   - Admin Center → Users → Licenses
   - Ensure Intune Plan 1 is enabled

2. **Check MDM scope:**
   - Entra ID → Mobility → Microsoft Intune
   - MDM User Scope = All

3. **Wait**: License propagation can take 15 minutes

---

## Validation Checklist

Before proceeding to Autopilot configuration, ensure:

- [x] Microsoft 365 tenant created
- [x] Tenant ID documented
- [x] Admin account working
- [x] At least 2 test users created
- [x] Autopilot Devices dynamic group created
- [x] MFA configured and tested
- [x] Licenses assigned to all users
- [x] Intune accessible
- [x] MDM authority set to Intune
- [x] MDM user scope configured
- [x] Users can access Company Portal

---

## Next Steps

Once environment setup is complete, proceed to:

📄 **[02-autopilot-configuration.md](./02-autopilot-configuration.md)** - Configure Windows Autopilot deployment profiles

---

## Additional Resources

### Microsoft Documentation
- [Entra ID Documentation](https://learn.microsoft.com/entra/identity/)
- [Intune Documentation](https://learn.microsoft.com/mem/intune/)
- [Microsoft 365 Admin](https://learn.microsoft.com/microsoft-365/admin/)

### PowerShell Modules
```powershell
# Install required modules
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Microsoft.Graph.Intune -Scope CurrentUser
```

### Useful Links
- **Entra Admin Center**: https://entra.microsoft.com
- **Intune Admin Center**: https://intune.microsoft.com
- **M365 Admin Center**: https://admin.microsoft.com
- **Company Portal**: https://portal.manage.microsoft.com

---

*Last Updated: November 2024*
*Author: Vidal Reñao Lopelo*
*Repository: https://github.com/vidal-renao/intune-autopilot-lab*
