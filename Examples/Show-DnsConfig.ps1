param()
<#
.SYNOPSIS
    Show the current DNS resolver configuration on this Linux host.
.DESCRIPTION
    Displays configured DNS servers per interface and the global search suffix list.
.EXAMPLE
    ./Show-DnsConfig.ps1
#>

Import-Module (Join-Path $PSScriptRoot '..' 'DnsClient.Linux' 'DnsClient.Linux.psd1') -Force

Write-Host "`n=== DNS Server Addresses ===" -ForegroundColor Cyan
Get-DnsClientServerAddress | ForEach-Object {
    Write-Host ("  [{0}]  {1}" -f $_.InterfaceAlias, ($_.ServerAddresses -join ', '))
}

Write-Host "`n=== Global Search Suffixes ===" -ForegroundColor Cyan
$global = Get-DnsClientGlobalSetting
if ($global.SuffixSearchList.Count -gt 0) {
    $global.SuffixSearchList | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  (none configured)"
}
