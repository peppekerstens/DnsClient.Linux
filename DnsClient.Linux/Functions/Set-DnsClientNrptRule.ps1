function Set-DnsClientNrptRule {
    <#
    .Synopsis
        Updates the specified DNS client NRPT rule.
    .Description
        NOT SUPPORTED on Linux. Set-DnsClientNrptRule requires Windows NRPT.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/set-dnsclientnrptrule
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Set-DnsClientNrptRule is not supported on Linux. This cmdlet requires Windows NRPT. Use the built-in DnsClient module on Windows.'
}
