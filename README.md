# 🚀 Modern Device Management Lab
## Microsoft Intune, Windows Autopilot & Entra ID

[![Microsoft 365](https://img.shields.io/badge/Microsoft_365-0078D4?style=for-the-badge&logo=microsoft&logoColor=white)](https://www.microsoft.com/microsoft-365)
[![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com)
[![Windows](https://img.shields.io/badge/Windows_11-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://docs.microsoft.com/powershell/)

> **Real-world enterprise device management lab showcasing zero-touch deployment, cloud-based configuration, and automated security policies.**

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Technologies Used](#-technologies-used)
- [Lab Environment](#-lab-environment)
- [Implementation Guide](#-implementation-guide)
- [Results & Impact](#-results--impact)
- [Documentation](#-documentation)
- [Future Enhancements](#-future-enhancements)
- [Contact](#-contact)

---

## 🎯 Overview

This lab demonstrates a complete **modern device management solution** using Microsoft's cloud-first approach. Traditional device deployment requires 2+ hours per device with manual configuration. This solution reduces that to **5 minutes** with **zero manual work** per device.

### **The Problem**
- ❌ Manual configuration on every device
- ❌ 200+ hours for 100 devices
- ❌ Configuration inconsistencies
- ❌ Human errors
- ❌ No scalability

### **The Solution**
- ✅ Configure once, deploy infinitely
- ✅ 5 hours total for 100 devices (98% time reduction)
- ✅ 100% configuration consistency
- ✅ Zero-touch deployment
- ✅ Infinite scalability

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Microsoft Cloud Services                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │              │  │              │  │              │      │
│  │  Entra ID    │  │   Intune     │  │  Autopilot   │      │
│  │              │  │              │  │              │      │
│  │ - Identity   │  │ - MDM/MAM    │  │ - Zero-Touch │      │
│  │ - Users      │  │ - Policies   │  │ - OOBE       │      │
│  │ - Groups     │  │ - Apps       │  │ - Profiles   │      │
│  │ - MFA        │  │ - Compliance │  │ - Dynamic    │      │
│  │              │  │              │  │   Groups     │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
│         └─────────────────┴─────────────────┘              │
│                           │                                │
└───────────────────────────┼────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   Managed Devices       │
              ├─────────────────────────┤
              │  • Windows 11 PCs       │
              │  • Laptops              │
              │  • Tablets              │
              │  • Future: Mobile       │
              └─────────────────────────┘
```

### **Configuration Flow**

```
1. Configure (One Time)          2. Import Device          3. Automatic Setup
   ┌────────────┐                   ┌────────────┐            ┌────────────┐
   │            │                   │            │            │            │
   │  Policies  │──────────────────▶│ Hash to    │───────────▶│  Autopilot │
   │  Security  │                   │  Intune    │            │    OOBE    │
   │  Apps      │                   │            │            │            │
   │  Groups    │                   └────────────┘            └────────────┘
   │            │                         │                         │
   └────────────┘                         │                         │
        │                                 │                         │
        │                                 ▼                         ▼
        │                          ┌────────────┐          ┌────────────┐
        │                          │  5 minutes │          │   Device   │
        └─────────────────────────▶│  per hash  │          │   Ready!   │
                                   └────────────┘          └────────────┘
```

---

## 🛠️ Technologies Used

### **Microsoft Cloud Platform**
- **Microsoft Entra ID** (formerly Azure AD)
  - Identity and Access Management
  - Multi-Factor Authentication (MFA)
  - Dynamic Groups
  - Conditional Access

- **Microsoft Intune**
  - Mobile Device Management (MDM)
  - Configuration Profiles
  - Endpoint Security
  - Compliance Policies
  - Application Deployment

- **Windows Autopilot**
  - Zero-Touch Deployment
  - User-Driven Provisioning
  - Automated Device Configuration

### **Tools & Scripts**
- **PowerShell** - Hardware hash extraction
- **Windows Configuration Designer** - Provisioning packages
- **VMware Workstation** - Lab environment
- **Windows 11 Pro** - Client devices

---

## 🔬 Lab Environment

### **Infrastructure**
```yaml
Tenant: Vidal Cloud Solutions
Domain: VidalCloudSolutions.onmicrosoft.com
License: Microsoft 365 Business Premium

Devices:
  - Type: Windows 11 Pro VM
  - Hostname Template: LAB-%SERIAL%
  - Management: Entra ID Joined
  - MDM: Microsoft Intune
  - State: Compliant ✅
```

### **Users**
- **Admin Account**: Global Administrator
- **Standard User**: Test deployment user
- **MFA**: Enabled with Microsoft Authenticator

### **Policies Configured**

#### **1. Configuration Profiles**
- Device restrictions
- WiFi configuration
- VPN settings
- Certificates
- Kiosk mode

#### **2. Endpoint Security**
- ✅ Microsoft Defender Antivirus
- ✅ BitLocker Disk Encryption
- ✅ Firewall Rules
- ✅ Attack Surface Reduction
- ✅ Account Protection

#### **3. Compliance Policies**
- Password requirements
- Encryption requirements
- Antivirus status
- OS version requirements

#### **4. Autopilot Profile**
```yaml
Deployment Mode: User-Driven
Join Type: Microsoft Entra Joined
User Account Type: Standard
Skip EULA: Yes
Skip Privacy Settings: Yes
Device Name Template: LAB-%SERIAL%
```

---

## 📚 Implementation Guide

### **Phase 1: Initial Setup (One-Time)**

#### **1.1 Configure Entra ID**
```powershell
# Create users
New-MgUser -DisplayName "Test User" -UserPrincipalName "user@domain.onmicrosoft.com"

# Create dynamic group for Autopilot devices
$dynamicRule = "(device.devicePhysicalIds -any (_ -contains `"[ZTDId]`"))"
New-MgGroup -DisplayName "Autopilot Devices" -GroupTypes "DynamicMembership" `
            -MembershipRule $dynamicRule
```

#### **1.2 Configure Intune MDM**
- Navigate: **Entra ID → Mobility (MDM & MAM)**
- Set **MDM user scope = All**
- Configure **MAM user scope** as needed

#### **1.3 Create Autopilot Profile**
```json
{
  "displayName": "Autopilot Standard User Setup",
  "deploymentMode": "UserDriven",
  "joinType": "azureADJoined",
  "userAccountType": "standard",
  "deviceNameTemplate": "LAB-%SERIAL%",
  "skipKeyboardSelection": true,
  "hideLicenseTerms": true,
  "hidePrivacySettings": true,
  "hideChangeAccountOptions": true
}
```

---

### **Phase 2: Device Enrollment**

#### **Method 1: From Installed Windows (Easiest for Labs)**

```powershell
# Open PowerShell as Administrator

# Set execution policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Install Autopilot script
Install-Script -Name Get-WindowsAutopilotInfo -Force

# Extract hardware hash to Desktop
Get-WindowsAutopilotInfo -OutputFile $env:USERPROFILE\Desktop\AutopilotHWID.csv
```

**Import to Intune:**
1. Go to **Intune → Devices → Windows → Windows enrollment → Devices**
2. Click **Import**
3. Select the CSV file
4. Wait 15-20 minutes for sync

#### **Method 2: During OOBE (New Devices)**

```cmd
# During Windows setup (language screen)
# Press Shift + F10

# Navigate to PowerShell
cd \Windows\System32\WindowsPowerShell\v1.0
.\PowerShell.exe

# Run extraction
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile C:\AutopilotHWID.csv
```

#### **Complete Method Documentation**
📄 See [6-Methods-Hardware-Hash-Extraction.md](./docs/6-methods-hardware-hash.md) for all methods including:
- OOBE extraction
- Installed Windows
- OEM/Manufacturer registration
- USB Provisioning packages
- Automated scripts for bulk deployment
- Extraction from Intune-enrolled devices

---

### **Phase 3: Deployment**

#### **3.1 Reset Device**
```powershell
# On the device to be deployed
systemreset -cleanpc
```

Or via Settings:
- **Settings → System → Recovery**
- **Reset this PC → Remove everything**

#### **3.2 Autopilot OOBE**
1. Device boots to OOBE
2. Connects to internet
3. Contacts Autopilot service
4. Applies profile automatically
5. User signs in with corporate credentials
6. Device configures itself:
   - Joins Entra ID
   - Enrolls in Intune
   - Applies all policies
   - Installs apps
   - Enforces compliance

#### **3.3 Verification**
```powershell
# Check Entra ID join status
dsregcmd /status

# Check Intune enrollment
Get-WmiObject -Namespace root\cimv2\mdm\dmmap -Class MDM_DevDetail_Ext01

# Check compliance
# Intune → Devices → Compliance → View device status
```

---

## 📊 Results & Impact

### **Time Comparison: 100 Devices**

| Method | Setup Time | Per Device | Total Time | Cost Factor |
|--------|-----------|------------|------------|-------------|
| **Traditional** | 0h | 2h | 200h | 100% |
| **Intune + Autopilot** | 4h | 0.05h | 9h | 4.5% |
| **Savings** | - | -1.95h | **191h** | **95.5%** |

### **Key Metrics**

```
⏱️  Time Saved: 98%
💰 Cost Reduction: 95%+
🎯 Configuration Accuracy: 100%
📈 Scalability: Unlimited
🔒 Security Compliance: Automated
👤 User Experience: Seamless
```

### **Business Impact**

#### **For a company with 500 employees:**
- **Traditional approach**: 1,000 hours = 125 work days = ~6 months for 1 person
- **Modern approach**: 22.5 hours = 3 work days
- **Saved**: 977.5 hours = **$48,875** (at $50/hour)

#### **Ongoing Operations:**
- **New employee onboarding**: 5 minutes vs 2 hours
- **Device replacement**: Instant vs half-day process
- **Configuration changes**: Push to all devices vs manual updates
- **Security patches**: Automated vs manual deployment

---

## 📁 Documentation

### **Repository Structure**
```
├── README.md                           # This file
├── docs/
│   ├── 01-environment-setup.md         # Initial configuration
│   ├── 02-autopilot-configuration.md   # Autopilot setup
│   ├── 03-policy-templates.md          # Configuration policies
│   ├── 04-security-baseline.md         # Security configurations
│   ├── 05-troubleshooting.md           # Common issues
│   └── 06-6-methods-hardware-hash.md   # All extraction methods
├── scripts/
│   ├── Get-AutopilotHash.ps1          # Hash extraction
│   ├── Bulk-Import-Devices.ps1        # Bulk operations
│   └── Compliance-Check.ps1           # Verification script
├── policies/
│   ├── configuration-profiles/         # Intune profiles (JSON)
│   ├── compliance-policies/            # Compliance rules
│   └── endpoint-security/              # Security baselines
└── images/
    ├── architecture-diagram.png
    ├── autopilot-flow.png
    └── comparison-chart.png
```

### **Key Documents**

📄 **[Complete Lab Guide](./docs/complete-lab-guide.md)**
- Step-by-step implementation
- Screenshots and examples
- Best practices

📄 **[6 Methods to Extract Hardware Hash](./docs/6-methods-hardware-hash.md)**
- OOBE extraction (new devices)
- Installed Windows (existing devices)
- OEM/Manufacturer registration
- USB provisioning packages
- Automated bulk scripts
- From Intune portal

📄 **[Security Baseline Configuration](./docs/security-baseline.md)**
- Endpoint protection
- BitLocker encryption
- Firewall rules
- Attack surface reduction

📄 **[Troubleshooting Guide](./docs/troubleshooting.md)**
- Common errors and solutions
- PowerShell fixes
- Sync issues

---

## 🚀 Future Enhancements

### **Phase 2: Mobile Device Management**
- [ ] iOS device enrollment
- [ ] Android device management
- [ ] App protection policies
- [ ] Mobile app deployment

### **Phase 3: Linux Integration**
- [ ] Microsoft Defender for Linux
- [ ] Azure Arc for server management
- [ ] Hybrid cloud monitoring

### **Phase 4: Advanced Security**
- [ ] Conditional Access policies
- [ ] Zero Trust implementation
- [ ] Privileged Identity Management
- [ ] Advanced Threat Protection

### **Phase 5: Automation**
- [ ] Azure Automation runbooks
- [ ] Automated device lifecycle
- [ ] Self-service device enrollment
- [ ] Integration with ServiceNow/ITSM

---

## 🎓 Skills Demonstrated

### **Cloud Technologies**
- Microsoft Entra ID administration
- Intune device management
- Azure cloud services
- Windows Autopilot deployment

### **Security & Compliance**
- Endpoint security configuration
- Compliance policy management
- Identity and access management
- Multi-factor authentication

### **Automation & Scripting**
- PowerShell scripting
- API integration
- Automated deployments
- Infrastructure as Code

### **IT Operations**
- Modern device management
- Zero-touch deployment
- Change management
- Documentation

---

## 📈 Real-World Applications

This lab demonstrates skills directly applicable to:

### **Enterprise IT Roles**
- **Systems Administrator**
- **Cloud Engineer**
- **Device Management Specialist**
- **Microsoft 365 Administrator**

### **Industries**
- Technology companies
- Financial services
- Healthcare organizations
- Educational institutions
- Government agencies

### **Use Cases**
- Remote workforce enablement
- BYOD (Bring Your Own Device) programs
- Merger & acquisition integrations
- Large-scale device refreshes
- New office deployments

---

## 🔗 Related Projects

- [Azure Infrastructure Lab](https://github.com/vidal-renao/azure-infrastructure)
- [Windows Server Configuration](https://github.com/vidal-renao/windows-server-lab)
- [PowerShell Automation Scripts](https://github.com/vidal-renao/powershell-scripts)

---

## 📞 Contact

**Vidal Reñao Lopelo**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/vidalrenao/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/vidal-renao)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:admin@vidalcloudsolutions.onmicrosoft.com)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ Acknowledgments

- Microsoft Learn documentation
- Microsoft Tech Community
- Windows Autopilot Community
- Intune Customer Success team

---

## 🏆 Certifications & Learning Path

This lab aligns with:
- **Microsoft 365 Certified: Modern Desktop Administrator Associate**
- **Microsoft Certified: Security, Compliance, and Identity Fundamentals**
- **Microsoft Certified: Azure Administrator Associate**

---

<div align="center">

### 🌟 If you found this helpful, please star this repository! 🌟

**Made with ❤️ for the IT Community**

</div>

---

*Last Updated: November 2025*
