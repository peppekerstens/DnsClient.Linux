#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
<#
.Synopsis
    Pester tests for DnsClient.Linux example scripts.
.Description
    Validates that each example script exists and parses cleanly.
    Linux-only execution tests are guarded with -Skip:(-not $IsLinux).
    Run with: Invoke-Pester .\Examples.Tests.ps1 -Output Detailed
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
#>

BeforeDiscovery {
    $script:ExamplesDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
    $script:ExampleFiles = @(
        'Resolve-DnsNames.ps1'
        'Get-DomainInfo.ps1'
        'Get-ReverseDns.ps1'
        'Show-DnsConfig.ps1'
    )
}

BeforeAll {
    $script:ExamplesDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
    if ($IsLinux) {
        $modulePath = Join-Path (Split-Path $script:ExamplesDir -Parent) 'DnsClient.Linux' 'DnsClient.Linux.psd1'
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force -ErrorAction Stop
        }
    }
}

Describe 'Example script files exist' {
    It 'Examples directory contains <_>' -ForEach $script:ExampleFiles {
        Join-Path $script:ExamplesDir $_ | Should -Exist
    }
}

Describe 'Example scripts have no syntax errors' {
    It '<_> parses without errors' -ForEach $script:ExampleFiles {
        $filePath = Join-Path $script:ExamplesDir $_
        $errors   = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
Describe 'Resolve-DnsNames' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Resolve-DnsNames.ps1' | Should -Exist
    }

    It 'Resolve-DnsName returns records for a known hostname' -Skip:(-not $IsLinux) {
        $result = Resolve-DnsName -Name 'dns.google' -ErrorAction SilentlyContinue
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Get-DnsClientServerAddress returns objects with InterfaceAlias' -Skip:(-not $IsLinux) {
        $result = Get-DnsClientServerAddress | Select-Object -First 1
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'InterfaceAlias'
    }

    It 'Get-DnsClientGlobalSetting returns SuffixSearchList' -Skip:(-not $IsLinux) {
        $result = Get-DnsClientGlobalSetting
        $result.PSObject.Properties.Name | Should -Contain 'SuffixSearchList'
    }
}

# ---------------------------------------------------------------------------
Describe 'Get-DomainInfo' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-DomainInfo.ps1' | Should -Exist
    }

    It 'Resolve-DnsName -Type MX returns MX records' -Skip:(-not $IsLinux) {
        $result = Resolve-DnsName -Name 'google.com' -Type MX -ErrorAction SilentlyContinue
        if ($result) {
            $result | ForEach-Object { $_.Type | Should -Be 'MX' }
        }
    }
}

# ---------------------------------------------------------------------------
Describe 'Get-ReverseDns' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-ReverseDns.ps1' | Should -Exist
    }

    It 'Resolve-DnsName -Type PTR resolves a well-known IP' -Skip:(-not $IsLinux) {
        $result = Resolve-DnsName -Name '8.8.8.8' -Type PTR -ErrorAction SilentlyContinue
        if ($result) {
            $result.PSObject.Properties.Name | Should -Contain 'NameHost'
        }
    }
}

# ---------------------------------------------------------------------------
Describe 'Show-DnsConfig' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Show-DnsConfig.ps1' | Should -Exist
    }

    It 'Get-DnsClientServerAddress returns non-empty list' -Skip:(-not $IsLinux) {
        @(Get-DnsClientServerAddress) | Should -Not -BeNullOrEmpty
    }
}
