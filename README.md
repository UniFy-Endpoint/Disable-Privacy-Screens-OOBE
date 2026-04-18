[![Download Latest Release](https://img.shields.io/github/v/release/UniFy-Endpoint/Disable-Privacy-Screens-OOBE?label=Download%20Latest&style=for-the-badge&logo=github)](https://github.com/UniFy-Endpoint/Disable-Privacy-Screens-OOBE/releases/latest)

# Disable Privacy OOBE (Autopilot Device Preparation / APv2)

This PowerShell script configures Windows Out-of-Box Experience (OOBE) registry settings for **Autopilot Device Preparation (APv2)** so that users do **not** see privacy-related setup choices and other first-run prompts during enrollment.

The script is intended to be deployed via **Microsoft Intune Platform Scripts** to a device group used for **APv2 Just-In-Time enrollment**.

> This repository focuses on **Autopilot Device Preparation (APv2)**, not classic “User-driven” or “Self-deploying” Windows Autopilot flows.

## What the script does

The script configures registry values to:

- Disable the **Privacy Experience** UI during OOBE
- Disable **Voice** assistance prompts during OOBE
- Set privacy consent/protection behavior
- Hide the **EULA** page
- Disable **First Logon Animation**

The script is **idempotent** (safe to run multiple times). It will:

- Create missing registry paths/values
- Update values when they exist but differ
- Leave values alone when already correct

## Important design choice: No OOBE detection

The script does **not** attempt to detect “OOBE state” via registry heuristics.

This is intentional for APv2:

- APv2 enrollment behavior can differ from traditional Windows setup/OOBE signals.
- OOBE detection based on registry values can be unreliable and may cause the script to exit unexpectedly.

Instead, the script relies on **Intune targeting**:

- Assign the script only to the **Autopilot Device Preparation** enrollment device group.
- Intune controls when/where the script runs.

## Compatibility

- **Architectures:** AMD64 (x64) and ARM64
- **PowerShell Host:** Must run in **64-bit** PowerShell
- **Context:** Designed to run as **SYSTEM** (Intune platform script with logged-on credentials = No)

## Registry settings applied

### `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE`

| Value Name | Type | Value | Purpose |
|---|---:|---:|---|
| `DisablePrivacyExperience` | DWORD | `1` | Disables Privacy Experience UI during OOBE |
| `DisableVoice` | DWORD | `1` | Disables voice assistance prompts during OOBE |
| `PrivacyConsentStatus` | DWORD | `1` | Sets privacy consent state |
| `ProtectYourPC` | DWORD | `3` | Applies recommended protection configuration |
| `HideEULAPage` | DWORD | `1` | Hides the EULA page during OOBE |

### `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`

| Value Name | Type | Value | Purpose |
|---|---:|---:|---|
| `EnableFirstLogonAnimation` | DWORD | `0` | Disables first logon animation |

## Deployment via Microsoft Intune (Platform Script)

### Recommended Intune configuration

Deploy as an **Intune Platform Script**:

1. Intune Admin Center → **Devices** → **Scripts** → **Add** → **Windows 10 and later**
2. Upload the `.ps1` script

Use these script settings:

- **Run this script using the logged on credentials:** `No`
- **Enforce script signature check:** `No`
- **Run script in 64-bit PowerShell Host:** `Yes`

### Assignments

Assign to a **device group** used for APv2 enrollment, such as:

- *Autopilot Device Preparation – Just-In-Time Enrollment Devices*

## Logging and troubleshooting

### Transcript logging

The script uses `Start-Transcript` to log to:

- `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OOBE-Privacy.log`

This log includes:

- Execution context (SYSTEM/user)
- Detected architecture
- Whether changes were created/updated/already correct
- Any warnings/errors

### Where to look in IME logs

IME logs are located at:

- `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`

Useful when validating execution during APv2.

## Test mode

The script supports a `-TestMode` switch.

When `-TestMode` is enabled:

- The script does **not** write to the registry.
- It logs what it **would** create/update.

Example:

```powershell
.\Disable-Privacy-OOBE-APv2.ps1 -TestMode
```

## Notes / operational considerations

- Review these settings with your organization’s privacy/compliance requirements.
- Because this is targeted to APv2 enrollment devices, avoid assigning it broadly to all devices unless that behavior is desired.

## Contributing

PRs and improvements are welcome—especially for:

- Additional logging/diagnostics
- Validation against newer Windows builds and Autopilot Device Preparation changes
