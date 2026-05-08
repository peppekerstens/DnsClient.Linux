function Set-DnsClientServerAddress {
    <#
    .Synopsis
        Sets DNS server addresses associated with the TCP/IP properties on an interface.
    .Description
        NOT SUPPORTED on Linux. Set-DnsClientServerAddress requires modifying DNS server addresses safely requires distro-specific tools (nmcli, resolvectl); editing /etc/resolv.conf directly may be overwritten by NetworkManager.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/set-dnsclientserveraddress
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Set-DnsClientServerAddress is not supported on Linux. This cmdlet requires modifying DNS server addresses safely requires distro-specific tools (nmcli, resolvectl); editing /etc/resolv.conf directly may be overwritten by NetworkManager. Use the built-in DnsClient module on Windows.'
}
