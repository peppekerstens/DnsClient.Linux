#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

<#
.SYNOPSIS
    Pester tests for DnsClient.Linux module.
.DESCRIPTION
    Tests module surface (function count), implemented cmdlet behaviour on Linux,
    and per-stub exported/no-throw/emits-warning checks.
    All tests require Linux — the module refuses to load on Windows by design.
    Describe blocks that require the module are skipped automatically on Windows.
    Run with: Invoke-Pester ./DnsClient.Linux.Tests.ps1 -Output Detailed
#>

BeforeDiscovery {
    $script:OnLinux = $IsLinux
    $script:ResolvectlAvailable = [bool](Get-Command resolvectl -ErrorAction SilentlyContinue)

    $script:ExpectedFunctions = @(
        # Implemented
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

    $script:StubFunctions = @(
        'Add-DnsClientNrptRule',
        'Get-DnsClientNrptGlobal',
        'Get-DnsClientNrptPolicy',
        'Get-DnsClientNrptRule',
        'Remove-DnsClientNrptRule',
        'Set-DnsClientNrptGlobal',
        'Set-DnsClientNrptRule',
        'Add-DnsClientDohServerAddress',
        'Get-DnsClientDohServerAddress',
        'Remove-DnsClientDohServerAddress',
        'Set-DnsClientDohServerAddress',
        'Get-DnsClientCache',
        'Register-DnsClient',
        'Set-DnsClient',
        'Set-DnsClientGlobalSetting',
        'Set-DnsClientServerAddress'
    )
}

BeforeAll {
    if ($IsLinux) {
        $ModulePath = Join-Path $PSScriptRoot 'DnsClient.Linux.psd1'
        Import-Module $ModulePath -Force
    }
}

AfterAll {
    if ($IsLinux) {
        Remove-Module DnsClient.Linux -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
Describe 'DnsClient.Linux module surface' -Skip:(-not $script:OnLinux) {

    It 'exports exactly 21 functions' {
        (Get-Module DnsClient.Linux).ExportedFunctions.Count | Should -Be 21
    }

    It 'exports 0 aliases' {
        (Get-Module DnsClient.Linux).ExportedAliases.Count | Should -Be 0
    }

    It "exports function '<Name>'" -ForEach ($script:ExpectedFunctions | ForEach-Object { @{ Name = $_ } }) {
        (Get-Module DnsClient.Linux).ExportedFunctions.Keys | Should -Contain $Name
    }
}

# ---------------------------------------------------------------------------
Describe 'Resolve-DnsName' -Skip:(-not $script:OnLinux) {

    It 'returns results for a known hostname without error' -Skip:(-not $script:ResolvectlAvailable) {
        { Resolve-DnsName -Name 'dns.google' } | Should -Not -Throw
    }

    It 'returns objects with required properties' -Skip:(-not $script:ResolvectlAvailable) {
        $result = Resolve-DnsName -Name 'dns.google' | Select-Object -First 1
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'Name'
        $result.PSObject.Properties.Name | Should -Contain 'Type'
        $result.PSObject.Properties.Name | Should -Contain 'TTL'
        $result.PSObject.Properties.Name | Should -Contain 'IPAddress'
    }

    It 'respects -Type A filter' -Skip:(-not $script:ResolvectlAvailable) {
        $result = Resolve-DnsName -Name 'dns.google' -Type A
        $result | ForEach-Object { $_.Type | Should -Be 'A' }
    }

    It 'resolves MX records' -Skip:(-not $script:ResolvectlAvailable) {
        $result = Resolve-DnsName -Name 'gmail.com' -Type MX
        $result | Should -Not -BeNullOrEmpty
        $result[0].PSObject.Properties.Name | Should -Contain 'NameExchange'
        $result[0].PSObject.Properties.Name | Should -Contain 'Preference'
    }

    It 'emits warning for -Server parameter' -Skip:(-not $script:ResolvectlAvailable) {
        Resolve-DnsName -Name 'dns.google' -Server '8.8.8.8' -WarningVariable w -WarningAction SilentlyContinue
        $w | Should -Not -BeNullOrEmpty
    }

    It 'throws when resolvectl is unavailable' -Skip:($script:ResolvectlAvailable) {
        { Resolve-DnsName -Name 'example.com' } | Should -Throw
    }
}

# ---------------------------------------------------------------------------
Describe 'Clear-DnsClientCache' -Skip:(-not $script:OnLinux) {

    It 'supports -WhatIf without error' {
        { Clear-DnsClientCache -WhatIf } | Should -Not -Throw
    }

    It 'does not throw when run normally' {
        { Clear-DnsClientCache -WarningAction SilentlyContinue -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

# ---------------------------------------------------------------------------
Describe 'Get-DnsClientServerAddress' -Skip:(-not $script:OnLinux) {

    It 'returns results without error' {
        { Get-DnsClientServerAddress } | Should -Not -Throw
    }

    It 'returns objects with required properties' {
        $result = Get-DnsClientServerAddress | Select-Object -First 1
        if ($result) {
            $result.PSObject.Properties.Name | Should -Contain 'InterfaceAlias'
            $result.PSObject.Properties.Name | Should -Contain 'ServerAddresses'
            $result.PSObject.Properties.Name | Should -Contain 'AddressFamily'
        }
    }

    It 'returns at least one result' {
        $result = @(Get-DnsClientServerAddress)
        $result | Should -Not -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
Describe 'Get-DnsClientGlobalSetting' -Skip:(-not $script:OnLinux) {

    It 'returns results without error' {
        { Get-DnsClientGlobalSetting } | Should -Not -Throw
    }

    It 'returns an object with SuffixSearchList property' {
        $result = Get-DnsClientGlobalSetting
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'SuffixSearchList'
    }
}

# ---------------------------------------------------------------------------
Describe 'Stub functions' -Skip:(-not $script:OnLinux) {

    It "'<Name>' is exported" -ForEach ($script:StubFunctions | ForEach-Object { @{ Name = $_ } }) {
        (Get-Module DnsClient.Linux).ExportedFunctions.Keys | Should -Contain $Name
    }

    It "'<Name>' does not throw" -ForEach ($script:StubFunctions | ForEach-Object { @{ Name = $_ } }) {
        { & $Name -WarningAction SilentlyContinue } | Should -Not -Throw
    }

    It "'<Name>' emits a not-implemented warning" -ForEach ($script:StubFunctions | ForEach-Object { @{ Name = $_ } }) {
        & $Name -WarningVariable w -WarningAction SilentlyContinue
        $w | Should -Not -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
Describe 'Get-DnsClient' -Skip:(-not $script:OnLinux) {

    It 'returns results without error' {
        { Get-DnsClient } | Should -Not -Throw
    }

    It 'returns objects with required properties' {
        $result = Get-DnsClient | Select-Object -First 1
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'InterfaceAlias'
        $result.PSObject.Properties.Name | Should -Contain 'InterfaceIndex'
        $result.PSObject.Properties.Name | Should -Contain 'ConnectionSpecificSuffix'
    }

    It 'returns at least one entry' {
        @(Get-DnsClient) | Should -Not -BeNullOrEmpty
    }

    It 'filters by InterfaceAlias' {
        $alias = (Get-DnsClient | Where-Object { $_.InterfaceAlias -ne 'global' } | Select-Object -First 1).InterfaceAlias
        if ($alias) {
            $results = Get-DnsClient -InterfaceAlias $alias
            $results | ForEach-Object { $_.InterfaceAlias | Should -Be $alias }
        }
    }
}
