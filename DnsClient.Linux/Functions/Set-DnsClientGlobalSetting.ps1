function Set-DnsClientGlobalSetting {
    <#
    .Synopsis
        Sets the DNS client global settings on the computer.
    .Description
        NOT SUPPORTED on Linux. Set-DnsClientGlobalSetting requires modifying global DNS settings safely requires distro-specific tools (nmcli, resolvectl, /etc/resolv.conf); too complex and risky to generalize.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/set-dnsclientglobalsetting
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Set-DnsClientGlobalSetting is not supported on Linux. This cmdlet requires modifying global DNS settings safely requires distro-specific tools (nmcli, resolvectl, /etc/resolv.conf); too complex and risky to generalize. Use the built-in DnsClient module on Windows.'
}
