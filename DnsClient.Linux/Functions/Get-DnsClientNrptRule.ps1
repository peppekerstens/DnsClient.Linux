function Get-DnsClientNrptRule {
    <#
    .Synopsis
        Retrieves the DNS client NRPT rules for the specified computer.
    .Description
        NOT SUPPORTED on Linux. Get-DnsClientNrptRule requires Windows NRPT rules.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientnrptrule
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Get-DnsClientNrptRule is not supported on Linux. This cmdlet requires Windows NRPT rules. Use the built-in DnsClient module on Windows.'
}
