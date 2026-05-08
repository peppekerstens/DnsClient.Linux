function Register-DnsClient {
    <#
    .Synopsis
        Registers all of the IP addresses on the computer onto the configured DNS server.
    .Description
        NOT SUPPORTED on Linux. Register-DnsClient requires Windows dynamic DNS registration with the configured DNS server; no Linux equivalent.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/register-dnsclient
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Register-DnsClient is not supported on Linux. This cmdlet requires Windows dynamic DNS registration with the configured DNS server; no Linux equivalent. Use the built-in DnsClient module on Windows.'
}
