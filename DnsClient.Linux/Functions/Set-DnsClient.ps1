function Set-DnsClient {
    <#
    .Synopsis
        Sets the interface-specific DNS client configurations on the computer.
    .Description
        NOT SUPPORTED on Linux. Set-DnsClient requires Windows interface-specific DNS settings via CIM; use `resolvectl` or edit /etc/resolv.conf on Linux.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/set-dnsclient
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Set-DnsClient is not supported on Linux. This cmdlet requires Windows interface-specific DNS settings via CIM; use `resolvectl` or edit /etc/resolv.conf on Linux. Use the built-in DnsClient module on Windows.'
}
