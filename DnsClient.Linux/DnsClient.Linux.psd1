#
# Module manifest for module 'DnsClient.Linux'
#

@{
    RootModule        = 'DnsClient.Linux.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b2c3d4e5-f6a7-8901-bcde-f12345678901'
    Author            = 'Peppe Kerstens'
    CompanyName       = ''
    Copyright         = '(c) Peppe Kerstens. GPL-3.0 license.'
    Description       = 'PowerShell module for Linux providing cmdlet parity with the Windows DnsClient module. Implements Resolve-DnsName, Clear-DnsClientCache, Get-DnsClientServerAddress, Get-DnsClientGlobalSetting using dig and resolvectl.'
    PowerShellVersion = '7.2'
    RequiredModules   = @()

    FunctionsToExport = @(
        # Fully implemented
        'Resolve-DnsName',
        'Clear-DnsClientCache',
        'Get-DnsClientServerAddress',
        'Get-DnsClientGlobalSetting',
        # Stubs — NRPT
        'Add-DnsClientNrptRule',
        'Get-DnsClientNrptGlobal',
        'Get-DnsClientNrptPolicy',
        'Get-DnsClientNrptRule',
        'Remove-DnsClientNrptRule',
        'Set-DnsClientNrptGlobal',
        'Set-DnsClientNrptRule',
        # Stubs — DoH
        'Add-DnsClientDohServerAddress',
        'Get-DnsClientDohServerAddress',
        'Remove-DnsClientDohServerAddress',
        'Set-DnsClientDohServerAddress',
        # Stubs — misc
        'Get-DnsClient',
        'Get-DnsClientCache',
        'Register-DnsClient',
        'Set-DnsClient',
        'Set-DnsClientGlobalSetting',
        'Set-DnsClientServerAddress'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Linux', 'DNS', 'DnsClient', 'Resolve-DnsName', 'dig', 'resolvectl', 'CrossPlatform')
            LicenseUri   = 'https://github.com/peppekerstens/DnsClient.Linux/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/peppekerstens/DnsClient.Linux'
            ReleaseNotes = @'
0.1.0 - Initial release. Resolve-DnsName (dig), Clear-DnsClientCache (resolvectl/nscd), Get-DnsClientServerAddress (/etc/resolv.conf + resolvectl), Get-DnsClientGlobalSetting (search domains) implemented. 17 stubs for NRPT, DoH, and remaining DnsClient cmdlets.
'@
        }
    }
}
