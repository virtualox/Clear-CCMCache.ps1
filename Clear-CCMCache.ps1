<#
.SYNOPSIS
Clears old and unused content from the CCMCache folder.

.DESCRIPTION
This script detects and removes old and unused content from the CCMCache folder based on the specified number of days. It helps manage the storage space used by the CCMCache.

.PARAMETER Detect
Detects old and unused content in the CCMCache folder without deleting.

.PARAMETER Clean
Cleans old and unused content from the CCMCache folder. If no option is provided, this is the default.

.PARAMETER Help
Shows the help message.

.PARAMETER Days
Specifies the number of days to keep files in the CCMCache folder. Default is 30 days.

.EXAMPLE
.\Clear-CCMCache.ps1 -Detect

.EXAMPLE
.\Clear-CCMCache.ps1 -Clean

.EXAMPLE
.\Clear-CCMCache.ps1 -Help

.EXAMPLE
.\Clear-CCMCache.ps1 -Clean -Days 14

.EXAMPLE
.\Clear-CCMCache.ps1 -Detect -Days 14

.NOTES
This script is designed for administrators and developers who need to manage the CCMCache folder storage space.

#>

# Ensure the script runs with administrative privileges
#Requires -RunAsAdministrator

[CmdletBinding(PositionalBinding=$False)]
param(
    [switch]$Detect,
    [switch]$Clean,
    [switch]$Help,
    [int]$Days = 30
)

function Show-Help {
    @"
Usage: .\Clear-CCMCache.ps1 [-Detect] [-Clean] [-Help] [-Days ##]

-Detect : Detect old and unused content in the CCMCache folder.
-Clean  : Clean old and unused content from the CCMCache folder. If no option is provided, this is the default.
-Help   : Show this help message.
-Days   : Set the number of days to keep files in the CCMCache folder. Default is 30 days.

Examples:
  .\Clear-CCMCache.ps1 -Detect
  .\Clear-CCMCache.ps1 -Clean
  .\Clear-CCMCache.ps1 -Help
  .\Clear-CCMCache.ps1 -Clean -Days 14
  .\Clear-CCMCache.ps1 -Detect -Days 14
"@
}

if ($Help) {
    Show-Help
    exit
}

if (-not $Detect -and -not $Clean) {
    $Clean = $true
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Error "This script does not support PowerShell 7.x. Please use Windows PowerShell 5.1. Exiting..."
    exit 1
}

# Get CCMCache path
try {
    $CachePath = (Get-WmiObject -Namespace "ROOT\ccm\SoftMgmtAgent" -Class "CacheConfig" -Filter "ConfigKey='Cache'").Location
} catch {
    Write-Error "Failed to retrieve CCMCache path. Exiting script."
    exit 1
}

# Test if the $CachePath was successfully retrieved and exit script if not
if ([string]::IsNullOrEmpty($CachePath)) {
    Write-Error "CachePath is null or empty. Exiting script."
    exit 1
}

# Get items not referenced for more than the specified days
$OldCache = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent" | Where-Object {
    ($([datetime]::Now) - ([System.Management.ManagementDateTimeConverter]::ToDateTime($_.LastReferenced))).Days -gt $Days
}

if ($Detect) {
    if ($OldCache) {
        Write-Output "Old and unused content detected:"
        $OldCache | Select-Object Location, LastReferenced
    } else {
        Write-Output "No old or unused content found."
    }
}

if ($Clean) {
    if ($OldCache) {
        # Delete items on disk
        $OldCache | ForEach-Object { 
            try {
                Remove-Item -Path $_.Location -Recurse -Force -ErrorAction Stop 
                Write-Output "Deleted: $_.Location"
            } catch {
                Write-Warning "Failed to delete: $_.Location"
            }
        }

        # Delete items in WMI
        $OldCache | ForEach-Object {
            try {
                $_ | Remove-WmiObject -ErrorAction Stop
                Write-Output "Removed WMI object: $_.Location"
            } catch {
                Write-Warning "Failed to remove WMI object: $_.Location"
            }
        }
    } else {
        Write-Output "No old or unused content to clean."
    }

    # Get all cached items from disk
    try {
        $CacheFoldersDisk = Get-ChildItem -Path $CachePath -ErrorAction Stop | Select-Object -ExpandProperty FullName
    } catch {
        Write-Error "Failed to retrieve cached items from disk. Exiting script."
        exit 1
    }

    # Get all cached items from WMI
    try {
        $CacheFoldersWMI = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent" | Select-Object -ExpandProperty Location
    } catch {
        Write-Error "Failed to retrieve cached items from WMI. Exiting script."
        exit 1
    }

    # Remove orphaned folders from disk
    $OrphanedFolders = $CacheFoldersDisk | Where-Object { $_ -notin $CacheFoldersWMI }
    foreach ($folder in $OrphanedFolders) {
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Output "Removed orphaned folder from disk: $folder"
        } catch {
            Write-Warning "Failed to remove orphaned folder: $folder"
        }
    }

    # Remove orphaned WMI objects
    $OrphanedWMIObjects = $CacheFoldersWMI | Where-Object { $_ -notin $CacheFoldersDisk }
    foreach ($wmiObj in $OrphanedWMIObjects) {
        try {
            $wmiObject = Get-WmiObject -Namespace "ROOT\ccm\SoftMgmtAgent" -Query "SELECT * FROM CacheInfoEx WHERE Location='$wmiObj'"
            if ($wmiObject) {
                $wmiObject | Remove-WmiObject -ErrorAction Stop
                Write-Output "Removed orphaned WMI object: $wmiObj"
            }
        } catch {
            Write-Warning "Failed to remove orphaned WMI object: $wmiObj"
        }
    }
}
