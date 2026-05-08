function Remove-DnsClientDohServerAddress {
    <#
    .Synopsis
        Removes a DNS-over-HTTPS (DoH) server address from the DoH server list.
    .Description
        NOT SUPPORTED on Linux. Remove-DnsClientDohServerAddress requires Windows DNS-over-HTTPS configuration.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/remove-dnsclientdohserveraddress
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Remove-DnsClientDohServerAddress is not supported on Linux. This cmdlet requires Windows DNS-over-HTTPS configuration. Use the built-in DnsClient module on Windows.'
}
