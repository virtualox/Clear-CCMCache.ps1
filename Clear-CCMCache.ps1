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

# Get CCMCache path
$CachePath = ([wmi]"ROOT\ccm\SoftMgmtAgent:CacheConfig.ConfigKey='Cache'").Location

# Get items not referenced for more than the specified days
$OldCache = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent" | Where-Object { ([datetime]::Now - ([System.Management.ManagementDateTimeConverter]::ToDateTime($_.LastReferenced))).Days -gt $Days }

if ($Detect) {
    # Report old items
    if ($OldCache) { $false } else { $true }
}

if ($Clean) {
    # Delete items on disk
    $OldCache | ForEach-Object { Remove-Item -Path $_.Location -Recurse -Force -ErrorAction SilentlyContinue }

    # Delete items in WMI
    $OldCache | Remove-WmiObject

    # Get all cached items from disk
    $CacheFoldersDisk = (Get-ChildItem $CachePath).FullName

    # Get all cached items from WMI
    $CacheFoldersWMI = Get-WmiObject -Query "SELECT * FROM CacheInfoEx" -Namespace "ROOT\ccm\SoftMgmtAgent"

    # Remove orphaned folders from disk
    $CacheFoldersDisk | ForEach-Object { if ($_ -notin $CacheFoldersWMI.Location) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue } }

    # Remove orphaned WMI objects
    $CacheFoldersWMI | ForEach-Object { if ($_.Location -notin $CacheFoldersDisk) { $_ | Remove-WmiObject } }
}
