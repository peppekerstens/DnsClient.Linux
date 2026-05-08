function Get-DnsClient {
    <#
    .Synopsis
        Gets details of the network interfaces configured on a specified computer.
    .Description
        NOT SUPPORTED on Linux. Get-DnsClient requires Windows-specific interface DNS settings via CIM/WMI; use `resolvectl status` on Linux.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclient
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Get-DnsClient is not supported on Linux. This cmdlet requires Windows-specific interface DNS settings via CIM/WMI; use `resolvectl status` on Linux. Use the built-in DnsClient module on Windows.'
}
