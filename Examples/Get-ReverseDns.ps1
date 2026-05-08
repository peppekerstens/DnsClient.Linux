param(
    [string[]]$IpAddresses = @('8.8.8.8', '1.1.1.1', '9.9.9.9')
)
<#
.SYNOPSIS
    Perform reverse DNS lookups for a list of IP addresses.
.DESCRIPTION
    Demonstrates PTR record resolution via Resolve-DnsName.
.EXAMPLE
    ./Get-ReverseDns.ps1
    ./Get-ReverseDns.ps1 -IpAddresses '8.8.4.4','208.67.222.222'
#>

Import-Module (Join-Path $PSScriptRoot '..' 'DnsClient.Linux' 'DnsClient.Linux.psd1') -Force

Write-Host "`n=== Reverse DNS Lookups ===" -ForegroundColor Cyan
foreach ($ip in $IpAddresses) {
    $result = Resolve-DnsName -Name $ip -Type PTR -ErrorAction SilentlyContinue
    if ($result) {
        Write-Host ("  {0,-20} -> {1}" -f $ip, ($result.NameHost -join ', '))
    } else {
        Write-Host ("  {0,-20} -> (no PTR record)" -f $ip)
    }
}
