function Set-DnsClientNrptGlobal {
    <#
    .Synopsis
        Modifies the global Name Resolution Policy Table (NRPT) settings.
    .Description
        NOT SUPPORTED on Linux. Set-DnsClientNrptGlobal requires Windows NRPT.
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/set-dnsclientnrptglobal
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Set-DnsClientNrptGlobal is not supported on Linux. This cmdlet requires Windows NRPT. Use the built-in DnsClient module on Windows.'
}
