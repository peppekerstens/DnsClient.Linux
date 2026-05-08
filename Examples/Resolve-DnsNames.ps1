param(
    [string[]]$Names = @('dns.google', 'one.one.one.one', 'example.com'),
    [string]  $Type  = 'A'
)
<#
.SYNOPSIS
    Resolve one or more hostnames and display DNS server configuration.
.DESCRIPTION
    Demonstrates Resolve-DnsName, Get-DnsClientServerAddress, and
    Get-DnsClientGlobalSetting from the DnsClient.Linux module.
.EXAMPLE
    ./Resolve-DnsNames.ps1
    ./Resolve-DnsNames.ps1 -Names 'github.com','microsoft.com' -Type AAAA
#>

Import-Module (Join-Path $PSScriptRoot '..' 'DnsClient.Linux' 'DnsClient.Linux.psd1') -Force

# Show configured DNS servers
Write-Host "`n=== DNS Client Server Addresses ===" -ForegroundColor Cyan
Get-DnsClientServerAddress | Format-Table InterfaceAlias, AddressFamily, ServerAddresses -AutoSize

# Show global DNS search suffix list
Write-Host "`n=== DNS Client Global Settings ===" -ForegroundColor Cyan
$global = Get-DnsClientGlobalSetting
Write-Host "Suffix search list: $($global.SuffixSearchList -join ', ')"

# Resolve each name
Write-Host "`n=== DNS Resolution ($Type records) ===" -ForegroundColor Cyan
foreach ($name in $Names) {
    Write-Host "`nResolving: $name" -ForegroundColor Yellow
    Resolve-DnsName -Name $name -Type $Type |
        Select-Object Name, Type, TTL, IPAddress |
        Format-Table -AutoSize
}
