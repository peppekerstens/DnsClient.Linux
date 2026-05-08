param(
    [string]$Domain = 'example.com'
)
<#
.SYNOPSIS
    Query multiple DNS record types for a domain.
.DESCRIPTION
    Shows A, AAAA, MX, NS, and TXT records for a given domain.
.EXAMPLE
    ./Get-DomainInfo.ps1
    ./Get-DomainInfo.ps1 -Domain 'github.com'
#>

Import-Module (Join-Path $PSScriptRoot '..' 'DnsClient.Linux' 'DnsClient.Linux.psd1') -Force

foreach ($type in @('A', 'AAAA', 'MX', 'NS', 'TXT')) {
    Write-Host "`n--- $type records for $Domain ---" -ForegroundColor Cyan
    $records = Resolve-DnsName -Name $Domain -Type $type -ErrorAction SilentlyContinue
    if ($records) {
        $records | Format-Table -AutoSize
    } else {
        Write-Host "  (none)"
    }
}
