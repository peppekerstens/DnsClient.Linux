function Add-DnsClientDohServerAddress {
    <#
    .Synopsis
        Adds a DNS-over-HTTPS (DoH) server address to the DoH server list.
    .Description
        NOT SUPPORTED on Linux. Add-DnsClientDohServerAddress requires Windows DNS-over-HTTPS client configuration (Windows 11/Server 2022 feature).
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/add-dnsclientdohserveraddress
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Add-DnsClientDohServerAddress is not supported on Linux. This cmdlet requires Windows DNS-over-HTTPS client configuration (Windows 11/Server 2022 feature). Use the built-in DnsClient module on Windows.'
}
