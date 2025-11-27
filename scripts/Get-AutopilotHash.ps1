<#
.SYNOPSIS
    Extract Windows Autopilot hardware hash from local or remote computers.

.DESCRIPTION
    This script extracts the hardware hash (hardware ID) required for Windows Autopilot
    registration. It can process local or remote computers and supports various output options.

.PARAMETER ComputerName
    Name of the computer(s) to extract hash from. Defaults to local computer.

.PARAMETER OutputPath
    Path where CSV file will be saved. Defaults to Desktop.

.PARAMETER GroupTag
    Optional group tag to assign to the device in Autopilot.

.PARAMETER AssignedUser
    Optional user to pre-assign to the device (UPN format).

.PARAMETER Append
    Append to existing CSV file instead of overwriting.

.PARAMETER Online
    Upload directly to Intune (requires authentication).

.EXAMPLE
    .\Get-AutopilotHash.ps1
    Extracts hash from local computer to Desktop

.EXAMPLE
    .\Get-AutopilotHash.ps1 -GroupTag "Finance-Dept"
    Extracts hash with group tag

.EXAMPLE
    .\Get-AutopilotHash.ps1 -ComputerName "PC01","PC02" -OutputPath "C:\Hashes"
    Extracts hashes from multiple remote computers

.EXAMPLE
    .\Get-AutopilotHash.ps1 -Online
    Directly uploads to Intune

.NOTES
    Author: Vidal Reñao Lopelo
    Version: 1.0
    Requires: PowerShell 5.1 or later, Administrator privileges
    
.LINK
    https://github.com/vidal-renao/intune-autopilot-lab
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter()]
    [string]$OutputPath = "$env:USERPROFILE\Desktop",
    
    [Parameter()]
    [string]$GroupTag,
    
    [Parameter()]
    [string]$AssignedUser,
    
    [Parameter()]
    [switch]$Append,
    
    [Parameter()]
    [switch]$Online,
    
    [Parameter()]
    [switch]$ShowProgress
)

#Requires -RunAsAdministrator

# Script configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = if ($ShowProgress) { "Continue" } else { "SilentlyContinue" }

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        Info    = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }
    
    $icons = @{
        Info    = "ℹ️"
        Success = "✅"
        Warning = "⚠️"
        Error   = "❌"
    }
    
    Write-Host "$($icons[$Type]) $Message" -ForegroundColor $colors[$Type]
}

# Check if script is required
function Test-ScriptInstalled {
    try {
        $script = Get-InstalledScript -Name "Get-WindowsAutopilotInfo" -ErrorAction SilentlyContinue
        return $null -ne $script
    }
    catch {
        return $false
    }
}

# Install required script
function Install-AutopilotScript {
    Write-ColorOutput "Installing Get-WindowsAutopilotInfo script..." -Type Info
    
    try {
        # Check for NuGet provider
        $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nuget) {
            Write-ColorOutput "Installing NuGet provider..." -Type Info
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
        }
        
        # Set PSGallery as trusted
        $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($gallery.InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        
        # Install the script
        Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
        
        Write-ColorOutput "Script installed successfully" -Type Success
        return $true
    }
    catch {
        Write-ColorOutput "Failed to install script: $_" -Type Error
        return $false
    }
}

# Validate output path
function Test-OutputPath {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        try {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-ColorOutput "Created output directory: $Path" -Type Success
            return $true
        }
        catch {
            Write-ColorOutput "Failed to create output directory: $_" -Type Error
            return $false
        }
    }
    return $true
}

# Main execution
function Start-HashExtraction {
    Write-ColorOutput "Windows Autopilot Hash Extraction Tool" -Type Info
    Write-ColorOutput "======================================" -Type Info
    Write-Host ""
    
    # Check administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-ColorOutput "This script requires Administrator privileges" -Type Error
        Write-ColorOutput "Please run PowerShell as Administrator" -Type Warning
        exit 1
    }
    
    # Check/Install required script
    if (-not (Test-ScriptInstalled)) {
        Write-ColorOutput "Get-WindowsAutopilotInfo script not found" -Type Warning
        $install = Read-Host "Would you like to install it now? (Y/N)"
        if ($install -eq 'Y') {
            if (-not (Install-AutopilotScript)) {
                exit 1
            }
        }
        else {
            Write-ColorOutput "Script installation cancelled" -Type Error
            exit 1
        }
    }
    
    # Validate output path
    if (-not $Online) {
        if (-not (Test-OutputPath -Path $OutputPath)) {
            exit 1
        }
    }
    
    # Build parameters for Get-WindowsAutopilotInfo
    $params = @{}
    
    if ($Online) {
        $params['Online'] = $true
        Write-ColorOutput "Mode: Direct upload to Intune" -Type Info
    }
    else {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = if ($ComputerName -eq $env:COMPUTERNAME) {
            "$env:COMPUTERNAME-$timestamp-Autopilot.csv"
        }
        else {
            "AutopilotHashes-$timestamp.csv"
        }
        
        $outputFile = Join-Path -Path $OutputPath -ChildPath $fileName
        $params['OutputFile'] = $outputFile
        
        if ($Append) {
            $params['Append'] = $true
        }
        
        Write-ColorOutput "Output file: $outputFile" -Type Info
    }
    
    if ($GroupTag) {
        $params['GroupTag'] = $GroupTag
        Write-ColorOutput "Group Tag: $GroupTag" -Type Info
    }
    
    if ($AssignedUser) {
        $params['AssignedUser'] = $AssignedUser
        Write-ColorOutput "Assigned User: $AssignedUser" -Type Info
    }
    
    # Process computers
    Write-Host ""
    Write-ColorOutput "Processing $($ComputerName.Count) computer(s)..." -Type Info
    Write-Host ""
    
    $successCount = 0
    $failCount = 0
    
    foreach ($computer in $ComputerName) {
        try {
            Write-ColorOutput "Processing: $computer" -Type Info
            
            if ($computer -ne $env:COMPUTERNAME) {
                # Remote computer
                $params['ComputerName'] = $computer
            }
            
            # Execute extraction
            Get-WindowsAutopilotInfo @params
            
            Write-ColorOutput "Successfully extracted hash from $computer" -Type Success
            $successCount++
        }
        catch {
            Write-ColorOutput "Failed to extract hash from $computer : $_" -Type Error
            $failCount++
        }
    }
    
    # Summary
    Write-Host ""
    Write-ColorOutput "======================================" -Type Info
    Write-ColorOutput "Extraction Summary" -Type Info
    Write-ColorOutput "======================================" -Type Info
    Write-ColorOutput "Total Computers: $($ComputerName.Count)" -Type Info
    Write-ColorOutput "Successful: $successCount" -Type Success
    if ($failCount -gt 0) {
        Write-ColorOutput "Failed: $failCount" -Type Error
    }
    
    if (-not $Online -and $successCount -gt 0) {
        Write-Host ""
        Write-ColorOutput "Next Steps:" -Type Info
        Write-ColorOutput "1. Go to https://intune.microsoft.com" -Type Info
        Write-ColorOutput "2. Navigate to: Devices → Windows → Windows enrollment → Devices" -Type Info
        Write-ColorOutput "3. Click 'Import' and select the CSV file" -Type Info
        Write-ColorOutput "4. Wait 15-20 minutes for sync to complete" -Type Info
    }
}

# Execute
try {
    Start-HashExtraction
}
catch {
    Write-ColorOutput "Unexpected error: $_" -Type Error
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -Type Error
    exit 1
}

# End of script
Write-Host ""
Write-ColorOutput "Script completed!" -Type Success
