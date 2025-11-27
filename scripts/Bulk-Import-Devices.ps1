<#
.SYNOPSIS
    Bulk import Windows Autopilot hardware hashes to Microsoft Intune.

.DESCRIPTION
    This script automates the bulk import of Autopilot hardware hashes from CSV files.
    It can merge multiple CSV files, validate data, and upload to Intune with progress tracking.

.PARAMETER SourcePath
    Path to CSV file or folder containing multiple CSV files.

.PARAMETER GroupTag
    Optional group tag to apply to all imported devices.

.PARAMETER Merge
    Merge multiple CSV files into one before importing.

.PARAMETER Validate
    Validate CSV files before importing.

.PARAMETER WhatIf
    Show what would be imported without actually importing.

.EXAMPLE
    .\Bulk-Import-Devices.ps1 -SourcePath "C:\Hashes"
    Import all CSV files from folder

.EXAMPLE
    .\Bulk-Import-Devices.ps1 -SourcePath "C:\Hashes" -Merge -GroupTag "Finance"
    Merge all CSVs and apply group tag

.EXAMPLE
    .\Bulk-Import-Devices.ps1 -SourcePath ".\devices.csv" -Validate -WhatIf
    Validate and preview import without executing

.NOTES
    Author: Vidal Reñao Lopelo
    Version: 1.0
    Requires: Microsoft.Graph.Intune module
    
.LINK
    https://github.com/vidal-renao/intune-autopilot-lab
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    
    [Parameter()]
    [string]$GroupTag,
    
    [Parameter()]
    [switch]$Merge,
    
    [Parameter()]
    [switch]$Validate,
    
    [Parameter()]
    [switch]$Force
)

#Requires -Modules Microsoft.Graph.Intune

$ErrorActionPreference = "Stop"

# Color output
function Write-Message {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Progress")]
        [string]$Type = "Info"
    )
    
    $colors = @{
        Info     = "Cyan"
        Success  = "Green"
        Warning  = "Yellow"
        Error    = "Red"
        Progress = "Magenta"
    }
    
    $prefix = switch ($Type) {
        "Info"     { "ℹ️" }
        "Success"  { "✅" }
        "Warning"  { "⚠️" }
        "Error"    { "❌" }
        "Progress" { "🔄" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $colors[$Type]
}

# Validate CSV structure
function Test-AutopilotCSV {
    param([string]$Path)
    
    try {
        $data = Import-Csv -Path $Path
        
        # Required columns
        $requiredColumns = @(
            'Device Serial Number',
            'Windows Product ID',
            'Hardware Hash'
        )
        
        $actualColumns = $data[0].PSObject.Properties.Name
        $missingColumns = $requiredColumns | Where-Object { $_ -notin $actualColumns }
        
        if ($missingColumns) {
            Write-Message "Missing columns in $Path : $($missingColumns -join ', ')" -Type Error
            return $false
        }
        
        # Check for empty values
        $emptySerials = $data | Where-Object { [string]::IsNullOrWhiteSpace($_.'Device Serial Number') }
        $emptyHashes = $data | Where-Object { [string]::IsNullOrWhiteSpace($_.'Hardware Hash') }
        
        if ($emptySerials) {
            Write-Message "$($emptySerials.Count) rows with empty serial numbers" -Type Warning
        }
        
        if ($emptyHashes) {
            Write-Message "$($emptyHashes.Count) rows with empty hardware hashes" -Type Warning
        }
        
        # Check for duplicates
        $duplicates = $data | Group-Object 'Device Serial Number' | Where-Object { $_.Count -gt 1 }
        
        if ($duplicates) {
            Write-Message "Duplicate serial numbers found:" -Type Warning
            $duplicates | ForEach-Object {
                Write-Host "  - $($_.Name) (appears $($_.Count) times)" -ForegroundColor Yellow
            }
        }
        
        Write-Message "CSV validation passed: $Path" -Type Success
        Write-Message "  Devices: $($data.Count)" -Type Info
        
        return $true
    }
    catch {
        Write-Message "Failed to validate $Path : $_" -Type Error
        return $false
    }
}

# Merge multiple CSV files
function Merge-AutopilotCSV {
    param(
        [string[]]$Files,
        [string]$OutputPath
    )
    
    Write-Message "Merging $($Files.Count) CSV files..." -Type Progress
    
    $allData = @()
    
    foreach ($file in $Files) {
        try {
            $data = Import-Csv -Path $file
            $allData += $data
            Write-Message "  Added $($data.Count) devices from $(Split-Path $file -Leaf)" -Type Info
        }
        catch {
            Write-Message "  Failed to read $file : $_" -Type Error
        }
    }
    
    # Remove duplicates based on Serial Number
    $uniqueData = $allData | Sort-Object -Property 'Device Serial Number' -Unique
    
    $duplicatesRemoved = $allData.Count - $uniqueData.Count
    if ($duplicatesRemoved -gt 0) {
        Write-Message "Removed $duplicatesRemoved duplicate entries" -Type Warning
    }
    
    # Add group tag if specified
    if ($GroupTag) {
        $uniqueData | ForEach-Object {
            $_ | Add-Member -NotePropertyName 'Group Tag' -NotePropertyValue $GroupTag -Force
        }
        Write-Message "Applied group tag: $GroupTag" -Type Info
    }
    
    # Export merged file
    $uniqueData | Export-Csv -Path $OutputPath -NoTypeInformation
    
    Write-Message "Merged file created: $OutputPath" -Type Success
    Write-Message "  Total unique devices: $($uniqueData.Count)" -Type Success
    
    return $OutputPath
}

# Connect to Microsoft Graph
function Connect-AutopilotService {
    Write-Message "Connecting to Microsoft Graph..." -Type Progress
    
    try {
        # Check if already connected
        $context = Get-MgContext
        
        if ($null -eq $context) {
            Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All" -ErrorAction Stop
        }
        
        Write-Message "Connected to tenant: $($context.TenantId)" -Type Success
        return $true
    }
    catch {
        Write-Message "Failed to connect: $_" -Type Error
        return $false
    }
}

# Import devices to Intune
function Import-AutopilotDevices {
    param([string]$CsvPath)
    
    Write-Message "Importing devices to Intune..." -Type Progress
    
    try {
        $devices = Import-Csv -Path $CsvPath
        $totalDevices = $devices.Count
        $imported = 0
        $failed = 0
        
        Write-Message "Total devices to import: $totalDevices" -Type Info
        
        foreach ($device in $devices) {
            try {
                $deviceData = @{
                    serialNumber = $device.'Device Serial Number'
                    hardwareIdentifier = $device.'Hardware Hash'
                    productKey = $device.'Windows Product ID'
                }
                
                if ($device.'Group Tag') {
                    $deviceData['groupTag'] = $device.'Group Tag'
                }
                
                if ($PSCmdlet.ShouldProcess($device.'Device Serial Number', "Import to Autopilot")) {
                    New-MgDeviceManagementWindowsAutopilotDeviceIdentity -BodyParameter $deviceData | Out-Null
                    $imported++
                    Write-Progress -Activity "Importing Devices" -Status "Processed $imported of $totalDevices" `
                                   -PercentComplete (($imported / $totalDevices) * 100)
                }
                
            }
            catch {
                Write-Message "Failed to import device $($device.'Device Serial Number'): $_" -Type Error
                $failed++
            }
        }
        
        Write-Progress -Activity "Importing Devices" -Completed
        
        Write-Host ""
        Write-Message "Import Summary:" -Type Info
        Write-Message "  Successfully imported: $imported" -Type Success
        if ($failed -gt 0) {
            Write-Message "  Failed: $failed" -Type Error
        }
        
        return $imported
    }
    catch {
        Write-Message "Import failed: $_" -Type Error
        return 0
    }
}

# Main execution
function Start-BulkImport {
    Write-Message "========================================" -Type Info
    Write-Message "Autopilot Bulk Import Tool" -Type Info
    Write-Message "========================================" -Type Info
    Write-Host ""
    
    # Validate source path
    if (-not (Test-Path $SourcePath)) {
        Write-Message "Source path not found: $SourcePath" -Type Error
        exit 1
    }
    
    # Get CSV files
    $csvFiles = if ((Get-Item $SourcePath) -is [System.IO.DirectoryInfo]) {
        Get-ChildItem -Path $SourcePath -Filter "*.csv" -File
    }
    else {
        Get-Item $SourcePath
    }
    
    if ($csvFiles.Count -eq 0) {
        Write-Message "No CSV files found in: $SourcePath" -Type Error
        exit 1
    }
    
    Write-Message "Found $($csvFiles.Count) CSV file(s)" -Type Info
    Write-Host ""
    
    # Validate CSV files
    if ($Validate -or $PSBoundParameters.ContainsKey('WhatIf')) {
        Write-Message "Validating CSV files..." -Type Progress
        Write-Host ""
        
        $validFiles = @()
        foreach ($file in $csvFiles) {
            if (Test-AutopilotCSV -Path $file.FullName) {
                $validFiles += $file
            }
        }
        
        Write-Host ""
        Write-Message "Valid files: $($validFiles.Count) / $($csvFiles.Count)" -Type Info
        
        if ($validFiles.Count -eq 0) {
            Write-Message "No valid CSV files to import" -Type Error
            exit 1
        }
        
        $csvFiles = $validFiles
    }
    
    # Merge files if requested
    $importFile = if ($Merge -and $csvFiles.Count -gt 1) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $mergedPath = Join-Path -Path $env:TEMP -ChildPath "AutopilotMerged-$timestamp.csv"
        
        Write-Host ""
        Merge-AutopilotCSV -Files $csvFiles.FullName -OutputPath $mergedPath
        
        $mergedPath
    }
    elseif ($csvFiles.Count -eq 1) {
        $csvFiles[0].FullName
    }
    else {
        Write-Message "Multiple CSV files found. Use -Merge to combine them." -Type Error
        exit 1
    }
    
    # Exit if WhatIf
    if ($PSBoundParameters.ContainsKey('WhatIf')) {
        Write-Host ""
        Write-Message "WhatIf: Import would process file: $importFile" -Type Info
        $preview = Import-Csv -Path $importFile | Select-Object -First 5
        $preview | Format-Table 'Device Serial Number', 'Group Tag' -AutoSize
        Write-Message "... and $((Import-Csv $importFile).Count - 5) more devices" -Type Info
        exit 0
    }
    
    # Connect to Graph
    Write-Host ""
    if (-not (Connect-AutopilotService)) {
        exit 1
    }
    
    # Import devices
    Write-Host ""
    $imported = Import-AutopilotDevices -CsvPath $importFile
    
    if ($imported -gt 0) {
        Write-Host ""
        Write-Message "========================================" -Type Info
        Write-Message "Import completed successfully!" -Type Success
        Write-Message "========================================" -Type Info
        Write-Host ""
        Write-Message "Next Steps:" -Type Info
        Write-Message "1. Wait 15-20 minutes for devices to sync" -Type Info
        Write-Message "2. Check Intune portal: Devices → Windows enrollment → Devices" -Type Info
        Write-Message "3. Verify devices appear with correct group tags" -Type Info
        Write-Message "4. Assign Autopilot deployment profiles if needed" -Type Info
    }
}

# Execute
try {
    Start-BulkImport
}
catch {
    Write-Message "Unexpected error: $_" -Type Error
    Write-Message "Stack Trace: $($_.ScriptStackTrace)" -Type Error
    exit 1
}

Write-Host ""
Write-Message "Script completed!" -Type Success
