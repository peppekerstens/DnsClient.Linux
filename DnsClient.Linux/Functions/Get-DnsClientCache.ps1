function Get-DnsClientCache {
    <#
    .Synopsis
        Retrieves the contents of the local DNS client cache.
    .Description
        NOT SUPPORTED on Linux. Get-DnsClientCache requires Windows DNS resolver cache inspection; systemd-resolved does not expose cache entries.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientcache
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Get-DnsClientCache is not supported on Linux. This cmdlet requires Windows DNS resolver cache inspection; systemd-resolved does not expose cache entries. Use the built-in DnsClient module on Windows.'
}
