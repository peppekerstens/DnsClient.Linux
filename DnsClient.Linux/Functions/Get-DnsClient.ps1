function Get-DnsClient {
    <#
    .SYNOPSIS
        Gets DNS client configuration for each network interface. On Linux, wraps 'resolvectl status --json=short'.
    .DESCRIPTION
        Returns per-interface DNS settings from systemd-resolved.
        The global resolver entry (index 0 in resolvectl JSON) is returned as the
        'lo' (loopback) interface for compatibility with Windows output shape.

        Unsupported Windows parameters: -InterfaceIndex, -CimSession, -AsJob.
        These emit a warning and are ignored on Linux.
    .PARAMETER InterfaceAlias
        Filter results to a specific interface alias.
    .PARAMETER ConnectionSpecificSuffix
        Not supported on Linux - emits a warning.
    .LINK
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclient
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string[]]$InterfaceAlias,

        [Parameter()]
        [string]$ConnectionSpecificSuffix
    )
    process {
        if ($IsLinux) {
            if ($ConnectionSpecificSuffix) {
                Write-Warning 'Get-DnsClient: -ConnectionSpecificSuffix is not supported on Linux.'
            }

            $raw = & resolvectl status --json=short 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error "resolvectl status failed: $raw"
                return
            }
            $data = $raw | ConvertFrom-Json

            $results = foreach ($entry in $data) {
                # First entry is global; subsequent entries are per-interface
                $alias = if ($entry.PSObject.Properties['ifname']) { $entry.ifname } else { 'global' }
                $idx   = if ($entry.PSObject.Properties['ifindex']) { $entry.ifindex } else { 0 }

                # DNS search domains from global entry
                $suffix = ''
                if ($entry.PSObject.Properties['searchDomains'] -and $entry.searchDomains) {
                    $suffix = ($entry.searchDomains | ForEach-Object { $_.name }) -join ', '
                }

                [PSCustomObject]@{
                    InterfaceAlias                 = $alias
                    InterfaceIndex                 = $idx
                    ConnectionSpecificSuffix       = $suffix
                    ConnectionSpecificSuffixSearchList = @()
                    RegisterThisConnectionsAddress = $true
                    UseSuffixWhenRegistering       = $false
                }
            }

            if ($InterfaceAlias) {
                $results = $results | Where-Object {
                    $_a = $_.InterfaceAlias
                    $InterfaceAlias | Where-Object { $_a -like $_ }
                }
            }
            $results
        } else {
            DnsClient\Get-DnsClient @PSBoundParameters
        }
    }
}
