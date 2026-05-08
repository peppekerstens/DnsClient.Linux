function Remove-DnsClientNrptRule {
    <#
    .Synopsis
        Removes a rule from the Name Resolution Policy Table (NRPT).
    .Description
        NOT SUPPORTED on Linux. Remove-DnsClientNrptRule requires Windows NRPT.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/remove-dnsclientnrptrule
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Remove-DnsClientNrptRule is not supported on Linux. This cmdlet requires Windows NRPT. Use the built-in DnsClient module on Windows.'
}
