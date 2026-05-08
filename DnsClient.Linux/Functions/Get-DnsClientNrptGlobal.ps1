function Get-DnsClientNrptGlobal {
    <#
    .Synopsis
        Gets the global Name Resolution Policy Table (NRPT) settings.
    .Description
        NOT SUPPORTED on Linux. Get-DnsClientNrptGlobal requires Windows NRPT global settings.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientnrptglobal
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Get-DnsClientNrptGlobal is not supported on Linux. This cmdlet requires Windows NRPT global settings. Use the built-in DnsClient module on Windows.'
}
