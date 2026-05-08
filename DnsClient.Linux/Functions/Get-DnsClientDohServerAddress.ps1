function Get-DnsClientDohServerAddress {
    <#
    .Synopsis
        Gets the DNS-over-HTTPS (DoH) server addresses from the DoH server list.
    .Description
        NOT SUPPORTED on Linux. Get-DnsClientDohServerAddress requires Windows DNS-over-HTTPS configuration.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientdohserveraddress
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Get-DnsClientDohServerAddress is not supported on Linux. This cmdlet requires Windows DNS-over-HTTPS configuration. Use the built-in DnsClient module on Windows.'
}
