<#
.SYNOPSIS
    Verify Windows Autopilot device registration and compliance status.

.DESCRIPTION
    This script checks if devices are properly registered in Windows Autopilot,
    verifies Entra ID join status, Intune enrollment, and compliance state.

.PARAMETER ComputerName
    Name of computer(s) to check. Defaults to local computer.

.PARAMETER CheckAutopilot
    Verify if device is registered in Autopilot.

.PARAMETER CheckEntraID
    Verify Entra ID (Azure AD) join status.

.PARAMETER CheckIntune
    Verify Intune MDM enrollment status.

.PARAMETER CheckCompliance
    Check device compliance status in Intune.

.PARAMETER ExportReport
    Export detailed report to CSV file.

.PARAMETER ReportPath
    Path for exported report. Defaults to Desktop.

.EXAMPLE
    .\Compliance-Check.ps1
    Check local device status (all checks)

.EXAMPLE
    .\Compliance-Check.ps1 -ComputerName "PC01","PC02"
    Check multiple remote computers

.EXAMPLE
    .\Compliance-Check.ps1 -ExportReport -ReportPath "C:\Reports"
    Check and export detailed report

.EXAMPLE
    .\Compliance-Check.ps1 -CheckAutopilot -CheckCompliance
    Run specific checks only

.NOTES
    Author: Vidal Reñao Lopelo
    Version: 1.0
    Requires: Administrator privileges, Microsoft.Graph.Intune module
    
.LINK
    https://github.com/vidal-renao/intune-autopilot-lab
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter()]
    [switch]$CheckAutopilot,
    
    [Parameter()]
    [switch]$CheckEntraID,
    
    [Parameter()]
    [switch]$CheckIntune,
    
    [Parameter()]
    [switch]$CheckCompliance,
    
    [Parameter()]
    [switch]$ExportReport,
    
    [Parameter()]
    [string]$ReportPath = "$env:USERPROFILE\Desktop"
)

$ErrorActionPreference = "Continue"

# If no specific checks selected, run all
$runAllChecks = -not ($CheckAutopilot -or $CheckEntraID -or $CheckIntune -or $CheckCompliance)

# Color output
function Write-Status {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Check")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        Info    = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
        Check   = "Magenta"
    }
    
    $icons = @{
        Info    = "ℹ️"
        Success = "✅"
        Warning = "⚠️"
        Error   = "❌"
        Check   = "🔍"
    }
    
    Write-Host "$($icons[$Type]) $Message" -ForegroundColor $colors[$Type]
}

# Check Entra ID join status
function Test-EntraIDJoin {
    param([string]$Computer)
    
    Write-Status "Checking Entra ID (Azure AD) Join Status..." -Type Check
    
    try {
        $dsregStatus = if ($Computer -eq $env:COMPUTERNAME) {
            dsregcmd /status
        }
        else {
            Invoke-Command -ComputerName $Computer -ScriptBlock { dsregcmd /status }
        }
        
        $azureAdJoined = $dsregStatus | Select-String "AzureAdJoined\s+:\s+YES"
        $deviceId = ($dsregStatus | Select-String "DeviceId\s+:\s+(.+)").Matches.Groups[1].Value
        $tenantId = ($dsregStatus | Select-String "TenantId\s+:\s+(.+)").Matches.Groups[1].Value
        
        if ($azureAdJoined) {
            Write-Status "Device is Entra ID Joined" -Type Success
            Write-Host "  Device ID: $deviceId" -ForegroundColor Gray
            Write-Host "  Tenant ID: $tenantId" -ForegroundColor Gray
            
            return @{
                Status     = "Joined"
                DeviceId   = $deviceId
                TenantId   = $tenantId
                IsJoined   = $true
            }
        }
        else {
            Write-Status "Device is NOT Entra ID Joined" -Type Error
            return @{
                Status     = "Not Joined"
                IsJoined   = $false
            }
        }
    }
    catch {
        Write-Status "Failed to check Entra ID status: $_" -Type Error
        return @{
            Status     = "Error"
            Error      = $_.Exception.Message
            IsJoined   = $false
        }
    }
}

# Check Intune enrollment
function Test-IntuneEnrollment {
    param([string]$Computer)
    
    Write-Status "Checking Intune MDM Enrollment..." -Type Check
    
    try {
        $mdmStatus = if ($Computer -eq $env:COMPUTERNAME) {
            Get-WmiObject -Namespace root\cimv2\mdm\dmmap -Class MDM_DevDetail_Ext01 -ErrorAction Stop
        }
        else {
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                Get-WmiObject -Namespace root\cimv2\mdm\dmmap -Class MDM_DevDetail_Ext01
            }
        }
        
        if ($mdmStatus) {
            Write-Status "Device is enrolled in Intune" -Type Success
            Write-Host "  Device Name: $($mdmStatus.DeviceName)" -ForegroundColor Gray
            Write-Host "  Enrolled: $(Get-Date $mdmStatus.EnrollmentTime)" -ForegroundColor Gray
            
            return @{
                Status         = "Enrolled"
                DeviceName     = $mdmStatus.DeviceName
                EnrollmentTime = $mdmStatus.EnrollmentTime
                IsEnrolled     = $true
            }
        }
        else {
            Write-Status "Device is NOT enrolled in Intune" -Type Error
            return @{
                Status     = "Not Enrolled"
                IsEnrolled = $false
            }
        }
    }
    catch {
        Write-Status "Failed to check Intune enrollment: $_" -Type Warning
        return @{
            Status     = "Unknown"
            Error      = $_.Exception.Message
            IsEnrolled = $false
        }
    }
}

# Check Autopilot registration
function Test-AutopilotRegistration {
    param([string]$Computer)
    
    Write-Status "Checking Windows Autopilot Registration..." -Type Check
    
    try {
        # Get serial number
        $serialNumber = if ($Computer -eq $env:COMPUTERNAME) {
            (Get-WmiObject -Class Win32_BIOS).SerialNumber
        }
        else {
            Invoke-Command -ComputerName $Computer -ScriptBlock {
                (Get-WmiObject -Class Win32_BIOS).SerialNumber
            }
        }
        
        Write-Host "  Serial Number: $serialNumber" -ForegroundColor Gray
        
        # Connect to Graph if not already connected
        $context = Get-MgContext
        if ($null -eq $context) {
            Write-Status "Connecting to Microsoft Graph..." -Type Info
            Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All" -ErrorAction Stop | Out-Null
        }
        
        # Check Autopilot registration
        $autopilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "serialNumber eq '$serialNumber'" -ErrorAction Stop
        
        if ($autopilotDevice) {
            Write-Status "Device IS registered in Autopilot" -Type Success
            Write-Host "  Group Tag: $($autopilotDevice.groupTag)" -ForegroundColor Gray
            Write-Host "  Deployment Profile: $($autopilotDevice.deploymentProfileAssignmentStatus)" -Type Gray
            Write-Host "  Assigned User: $($autopilotDevice.userPrincipalName)" -ForegroundColor Gray
            
            return @{
                Status              = "Registered"
                SerialNumber        = $serialNumber
                GroupTag            = $autopilotDevice.groupTag
                DeploymentProfile   = $autopilotDevice.deploymentProfileAssignmentStatus
                AssignedUser        = $autopilotDevice.userPrincipalName
                IsRegistered        = $true
            }
        }
        else {
            Write-Status "Device is NOT registered in Autopilot" -Type Error
            Write-Host "  Serial Number: $serialNumber" -ForegroundColor Gray
            
            return @{
                Status       = "Not Registered"
                SerialNumber = $serialNumber
                IsRegistered = $false
            }
        }
    }
    catch {
        Write-Status "Failed to check Autopilot registration: $_" -Type Error
        return @{
            Status       = "Error"
            SerialNumber = $serialNumber
            Error        = $_.Exception.Message
            IsRegistered = $false
        }
    }
}

# Check compliance status
function Test-ComplianceStatus {
    param([string]$Computer)
    
    Write-Status "Checking Device Compliance Status..." -Type Check
    
    try {
        # Get device from Intune
        $context = Get-MgContext
        if ($null -eq $context) {
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -ErrorAction Stop | Out-Null
        }
        
        $device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$Computer'" -ErrorAction Stop
        
        if ($device) {
            $complianceState = $device.complianceState
            $lastSync = $device.lastSyncDateTime
            
            $statusMessage = switch ($complianceState) {
                "compliant"     { "Compliant"; $statusType = "Success" }
                "noncompliant"  { "Non-Compliant"; $statusType = "Error" }
                "conflict"      { "Conflict"; $statusType = "Warning" }
                "error"         { "Error"; $statusType = "Error" }
                "inGracePeriod" { "In Grace Period"; $statusType = "Warning" }
                default         { "Unknown"; $statusType = "Warning" }
            }
            
            Write-Status "Compliance Status: $statusMessage" -Type $statusType
            Write-Host "  Last Sync: $lastSync" -ForegroundColor Gray
            Write-Host "  OS Version: $($device.osVersion)" -ForegroundColor Gray
            
            return @{
                Status           = $statusMessage
                ComplianceState  = $complianceState
                LastSync         = $lastSync
                OSVersion        = $device.osVersion
                IsCompliant      = ($complianceState -eq "compliant")
            }
        }
        else {
            Write-Status "Device not found in Intune" -Type Error
            return @{
                Status      = "Not Found"
                IsCompliant = $false
            }
        }
    }
    catch {
        Write-Status "Failed to check compliance status: $_" -Type Error
        return @{
            Status      = "Error"
            Error       = $_.Exception.Message
            IsCompliant = $false
        }
    }
}

# Generate summary report
function New-ComplianceReport {
    param([array]$Results, [string]$OutputPath)
    
    Write-Status "Generating compliance report..." -Type Check
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $reportFile = Join-Path -Path $OutputPath -ChildPath "ComplianceReport-$timestamp.csv"
        
        $Results | Export-Csv -Path $reportFile -NoTypeInformation
        
        Write-Status "Report saved: $reportFile" -Type Success
        
        # Generate summary
        $totalDevices = $Results.Count
        $entraJoined = ($Results | Where-Object { $_.EntraID_IsJoined }).Count
        $intuneEnrolled = ($Results | Where-Object { $_.Intune_IsEnrolled }).Count
        $autopilotRegistered = ($Results | Where-Object { $_.Autopilot_IsRegistered }).Count
        $compliant = ($Results | Where-Object { $_.Compliance_IsCompliant }).Count
        
        Write-Host ""
        Write-Status "========================================" -Type Info
        Write-Status "Summary Report" -Type Info
        Write-Status "========================================" -Type Info
        Write-Host "Total Devices Checked: $totalDevices" -ForegroundColor Cyan
        Write-Host "Entra ID Joined: $entraJoined / $totalDevices" -ForegroundColor $(if($entraJoined -eq $totalDevices){'Green'}else{'Yellow'})
        Write-Host "Intune Enrolled: $intuneEnrolled / $totalDevices" -ForegroundColor $(if($intuneEnrolled -eq $totalDevices){'Green'}else{'Yellow'})
        Write-Host "Autopilot Registered: $autopilotRegistered / $totalDevices" -ForegroundColor $(if($autopilotRegistered -eq $totalDevices){'Green'}else{'Yellow'})
        Write-Host "Compliant: $compliant / $totalDevices" -ForegroundColor $(if($compliant -eq $totalDevices){'Green'}else{'Yellow'})
        
        return $reportFile
    }
    catch {
        Write-Status "Failed to generate report: $_" -Type Error
        return $null
    }
}

# Main execution
function Start-ComplianceCheck {
    Write-Status "========================================" -Type Info
    Write-Status "Device Compliance Check Tool" -Type Info
    Write-Status "========================================" -Type Info
    Write-Host ""
    
    $allResults = @()
    
    foreach ($computer in $ComputerName) {
        Write-Status "Checking device: $computer" -Type Info
        Write-Host ""
        
        $result = [PSCustomObject]@{
            ComputerName = $computer
            CheckDate    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        # Run checks
        if ($runAllChecks -or $CheckEntraID) {
            $entraResult = Test-EntraIDJoin -Computer $computer
            $result | Add-Member -NotePropertyName "EntraID_Status" -NotePropertyValue $entraResult.Status
            $result | Add-Member -NotePropertyName "EntraID_IsJoined" -NotePropertyValue $entraResult.IsJoined
            $result | Add-Member -NotePropertyName "EntraID_DeviceId" -NotePropertyValue $entraResult.DeviceId
            Write-Host ""
        }
        
        if ($runAllChecks -or $CheckIntune) {
            $intuneResult = Test-IntuneEnrollment -Computer $computer
            $result | Add-Member -NotePropertyName "Intune_Status" -NotePropertyValue $intuneResult.Status
            $result | Add-Member -NotePropertyName "Intune_IsEnrolled" -NotePropertyValue $intuneResult.IsEnrolled
            $result | Add-Member -NotePropertyName "Intune_EnrollmentTime" -NotePropertyValue $intuneResult.EnrollmentTime
            Write-Host ""
        }
        
        if ($runAllChecks -or $CheckAutopilot) {
            $autopilotResult = Test-AutopilotRegistration -Computer $computer
            $result | Add-Member -NotePropertyName "Autopilot_Status" -NotePropertyValue $autopilotResult.Status
            $result | Add-Member -NotePropertyName "Autopilot_IsRegistered" -NotePropertyValue $autopilotResult.IsRegistered
            $result | Add-Member -NotePropertyName "Autopilot_GroupTag" -NotePropertyValue $autopilotResult.GroupTag
            $result | Add-Member -NotePropertyName "Autopilot_SerialNumber" -NotePropertyValue $autopilotResult.SerialNumber
            Write-Host ""
        }
        
        if ($runAllChecks -or $CheckCompliance) {
            $complianceResult = Test-ComplianceStatus -Computer $computer
            $result | Add-Member -NotePropertyName "Compliance_Status" -NotePropertyValue $complianceResult.Status
            $result | Add-Member -NotePropertyName "Compliance_IsCompliant" -NotePropertyValue $complianceResult.IsCompliant
            $result | Add-Member -NotePropertyName "Compliance_LastSync" -NotePropertyValue $complianceResult.LastSync
            Write-Host ""
        }
        
        $allResults += $result
        
        Write-Status "----------------------------------------" -Type Info
        Write-Host ""
    }
    
    # Export report if requested
    if ($ExportReport) {
        New-ComplianceReport -Results $allResults -OutputPath $ReportPath
    }
    
    return $allResults
}

# Execute
try {
    $results = Start-ComplianceCheck
    
    Write-Host ""
    Write-Status "========================================" -Type Info
    Write-Status "Check completed successfully!" -Type Success
    Write-Status "========================================" -Type Info
}
catch {
    Write-Status "Unexpected error: $_" -Type Error
    Write-Status "Stack Trace: $($_.ScriptStackTrace)" -Type Error
    exit 1
}

Write-Host ""
Write-Status "Script completed!" -Type Success
