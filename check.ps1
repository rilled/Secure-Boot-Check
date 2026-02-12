param (
    [switch]$Minimal,
    [string]$LogFile
)

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator." -ForegroundColor Red
    exit 1
}

# Check if LogFile directory exists & file is specified
if ($LogFile) {
    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        Write-Error "The directory for the log file does not exist: $logDir`nPlease create the directory or specify a valid path." -ForegroundColor Red
        return
    }
    if (-not ($LogFile -match '\.[a-zA-Z0-9]+$')) {
        Write-Error "No log file specified." -ForegroundColor Red
        return
    }
}

function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Output $line
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $line
    }
}

function Get-SecureBootCertStatus {
    Log "Starting Secure Boot check on $env:COMPUTERNAME..."
    $sbEnabled = Confirm-SecureBootUEFI 2>$null

    if (-not $sbEnabled) {
        Log "Secure Boot is either not supported or not enabled."
        return
    }

    if (-not $Minimal) { Log "Secure Boot is enabled. Checking certificates..." }

    try {
        $dbVar = Get-SecureBootUEFI -Name db
    } catch {
        Log "Error: Failed to read UEFI Secure Boot 'db' variable. Secure Boot may not be supported."
        return
    }

    # Convert Secure Boot db binary to string
    $dbBytes  = $dbVar.Bytes
    $dbString = [System.Text.Encoding]::ASCII.GetString($dbBytes)

    $expectedCerts = @(
        'Windows UEFI CA 2023',
        'Microsoft Corporation KEK 2K CA 2023',
        'Microsoft Option ROM UEFI CA 2023'
    )

    $foundCerts = @()
    foreach ($cert in $expectedCerts) {
        if ($dbString -match [regex]::Escape($cert)) {
            $foundCerts += $cert
        }
    }

    if ($foundCerts.Count -gt 0) {
        if ($Minimal) {
            Log "Updated Secure Boot certificates: TRUE"
            return
        }

        Log "Updated Secure Boot certificates: TRUE"
        Log "Detected 2023 certificate entries in UEFI db:"
        foreach ($c in $foundCerts) { Log "  - $c" }
    } else {
        if ($Minimal) {
            Log "Updated Secure Boot certificates: FALSE"
            return
        }

        Log "Updated Secure Boot certificates: FALSE"
        Log "The UEFI Secure Boot database appears to contain only older certificates."
    }

    if (-not $Minimal) {
        Log "`nCertificates/entries in DB containing 'Microsoft':"
        $dbString.Split([Environment]::NewLine) |
            Where-Object { $_ -match 'Microsoft' } |
            Select-Object -Unique |
            ForEach-Object { Log "  $_" }
    }
}

Get-SecureBootCertStatus