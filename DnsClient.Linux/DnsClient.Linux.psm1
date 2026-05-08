#Requires -Version 7.2

# DnsClient.Linux.psm1
# Root module for DnsClient.Linux.
# Dot-sources all function files from the Functions\ subdirectory.

# Linux-only guard — this module wraps Linux DNS tools (dig, resolvectl) and must
# not be loaded on Windows. On Windows, use the built-in DnsClient module instead:
#   Import-Module DnsClient
if (-not $IsLinux) {
    throw (
        "DnsClient.Linux cannot be loaded on Windows. " +
        "On Windows, use the built-in 'DnsClient' module: Import-Module DnsClient`n" +
        "DnsClient.Linux is a Linux-only peer module that wraps dig and resolvectl."
    )
}

Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter '*.ps1' |
    Where-Object { $_.Name -notlike '*.Tests.ps1' } |
    ForEach-Object { . $_.FullName }
