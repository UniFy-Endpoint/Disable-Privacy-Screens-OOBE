<#
.SYNOPSIS
    Configures registry settings to customize Windows Out-of-Box Experience (OOBE) system behavior, privacy experience, and related prompts during the OOBE phase in Autopilot Device Preparation.

.DESCRIPTION
    This script disables privacy screens, voice assistance, EULA page, and first logon animation.
    It supports both ARM64 and AMD64 (x64) architectures.
    Designed to be deployed via Intune Platform Scripts to Autopilot Device Preparation devices.

.PARAMETER TestMode
    When specified, the script simulates registry changes without applying them.
    Use this to test the script before deploying in production.

.EXAMPLE
    .\Disable-Privacy-OOBE-APv2_v1.8.ps1 -TestMode
    Runs the script in test mode to simulate changes without applying them.

.NOTES
    Author: Yoennis Olmo
    Version: v1.8
    Release Date: 2025-01-14

    Intune Info:
    Script type: Platform Script
    Assign to: (Devices) - Autopilot Device Preparation - Just-In-Time Enrollment Devices Group.
    Script Settings:
        Run this script using the logged on credentials: No
        Enforce script signature check: No
        Run script in 64-bit PowerShell Host: Yes    
#>

param(
    [switch]$TestMode
)

# Start logging for troubleshooting
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OOBE-Privacy.log"
Start-Transcript -Path $LogPath -Append -Force | Out-Null

if ($TestMode) {
    Write-Host "========== TEST MODE ENABLED ==========" -ForegroundColor Magenta
    Write-Host "No registry changes will be applied." -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
}

# Detect system architecture
$arch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
if ($arch -notin @("64-bit", "ARM64")) {
    Write-Warning "Unsupported architecture: $arch. Script supports only ARM64 and AMD64 systems. Exiting."
    Stop-Transcript | Out-Null
    exit 1
}
Write-Host "Architecture detected: $arch" -ForegroundColor Cyan

# Ensure we're running in 64-bit PowerShell
if ([Environment]::Is64BitProcess -ne $true) {
    Write-Warning "Script must run in 64-bit PowerShell. Exiting."
    Stop-Transcript | Out-Null
    exit 1
}
Write-Host "Running in 64-bit PowerShell: Yes" -ForegroundColor Cyan

# Registry paths
$OOBEPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
$SystemPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Registry settings to apply
$registrySettings = @(
    @{ Path = $OOBEPath; Name = "DisablePrivacyExperience"; Value = 1; Type = "DWord" },
    @{ Path = $OOBEPath; Name = "DisableVoice"; Value = 1; Type = "DWord" },
    @{ Path = $OOBEPath; Name = "PrivacyConsentStatus"; Value = 1; Type = "DWord" },
    @{ Path = $OOBEPath; Name = "ProtectYourPC"; Value = 3; Type = "DWord" },  # 3 = Full (recommended settings, sends diagnostic data to Microsoft)
    @{ Path = $OOBEPath; Name = "HideEULAPage"; Value = 1; Type = "DWord" },
    @{ Path = $SystemPolicyPath; Name = "EnableFirstLogonAnimation"; Value = 0; Type = "DWord" }
)

$changesMade = $false
$errorOccurred = $false

foreach ($setting in $registrySettings) {
    try {
        if (-not (Test-Path -Path $setting.Path)) {
            if ($TestMode) {
                Write-Host "[TEST MODE] Would create registry path: '$($setting.Path)'" -ForegroundColor Magenta
            } else {
                New-Item -Path $setting.Path -Force | Out-Null
            }
        }

        $existingValue = (Get-ItemProperty -Path $setting.Path -Name $setting.Name -ErrorAction SilentlyContinue).$($setting.Name)

        if ($null -eq $existingValue) {
            # Value doesn't exist, create it
            if ($TestMode) {
                Write-Host "[TEST MODE] Would CREATE '$($setting.Name)' with value '$($setting.Value)' in '$($setting.Path)'" -ForegroundColor Magenta
            } else {
                New-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType $setting.Type -Force | Out-Null
                Write-Host "Created '$($setting.Name)' with value '$($setting.Value)' in '$($setting.Path)'" -ForegroundColor Green
            }
            $changesMade = $true
        }
        elseif ($existingValue -ne $setting.Value) {
            # Value exists but differs, enforce our value
            if ($TestMode) {
                Write-Host "[TEST MODE] Would UPDATE '$($setting.Name)' from '$existingValue' to '$($setting.Value)' in '$($setting.Path)'" -ForegroundColor Magenta
            } else {
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Force
                Write-Host "Updated '$($setting.Name)' from '$existingValue' to '$($setting.Value)' in '$($setting.Path)'" -ForegroundColor Yellow
            }
            $changesMade = $true
        }
        else {
            Write-Host "'$($setting.Name)' already exists and is correctly set to '$($setting.Value)'." -ForegroundColor Gray
        }
    } catch {
        Write-Warning "Failed to process setting '$($setting.Name)': $_"
        $errorOccurred = $true
    }
}

if (-not $changesMade) {
    Write-Host "All registry settings already exist and are correctly configured. No changes made." -ForegroundColor Cyan
}

if ($TestMode) {
    Write-Host "========== TEST MODE COMPLETE ==========" -ForegroundColor Magenta
    Write-Host "Review the log file at: $LogPath" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

Stop-Transcript | Out-Null
if ($errorOccurred) {
    exit 1
}
exit 0