function Get-DnsClientNrptPolicy {
    <#
    .Synopsis
        Gets the Name Resolution Policy Table (NRPT) policies configured on the computer.
    .Description
        NOT SUPPORTED on Linux. Get-DnsClientNrptPolicy requires Windows NRPT policy (Group Policy applied rules).
        This cmdlet is a stub that emits a warning and returns nothing.
        On Windows, use the built-in DnsClient module: Import-Module DnsClient
    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientnrptpolicy
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()
    Write-Warning 'Get-DnsClientNrptPolicy is not supported on Linux. This cmdlet requires Windows NRPT policy (Group Policy applied rules). Use the built-in DnsClient module on Windows.'
}
