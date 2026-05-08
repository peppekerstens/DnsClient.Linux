function Add-DnsClientNrptRule {
    <#
    .Synopsis
        Adds a rule to the Name Resolution Policy Table (NRPT).
    .Description
        NOT SUPPORTED on Linux. Add-DnsClientNrptRule requires Windows Name Resolution Policy Table (NRPT), a Group Policy DNS routing feature not present on Linux.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/add-dnsclientnrptrule
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Add-DnsClientNrptRule is not supported on Linux. This cmdlet requires Windows Name Resolution Policy Table (NRPT), a Group Policy DNS routing feature not present on Linux. Use the built-in DnsClient module on Windows.'
}
