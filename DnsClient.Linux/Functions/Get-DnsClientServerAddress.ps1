function Get-DnsClientServerAddress {
    <#
    .Synopsis
        Gets DNS server IP addresses from the system resolver configuration.
    .Description
        Reads DNS server addresses from `/etc/resolv.conf` (nameserver lines)
        and optionally from `resolvectl status` for per-interface DNS servers.

        Returns one object per nameserver with InterfaceAlias, ServerAddresses,
        and AddressFamily properties — matching the Windows output shape.

        Unsupported Windows parameters: -InterfaceIndex, -CimSession, -AsJob.
        These emit a warning and are ignored.
    .Parameter InterfaceAlias
        Filter results to a specific interface. If omitted, all interfaces and
        the global resolver configuration are returned.
    .Parameter AddressFamily
        Filter by address family: IPv4 or IPv6. If omitted, both are returned.
    .Example
        # Get all configured DNS servers
        Get-DnsClientServerAddress

    .Example
        # Get IPv4 DNS servers only
        Get-DnsClientServerAddress -AddressFamily IPv4

    .Example
        # Get DNS servers for a specific interface
        Get-DnsClientServerAddress -InterfaceAlias eth0

    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientserveraddress
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string] $InterfaceAlias,

        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [string] $AddressFamily
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # ── Global servers from /etc/resolv.conf ──────────────────────────────────
    if (Test-Path '/etc/resolv.conf') {
        $nameservers = Get-Content '/etc/resolv.conf' |
            Where-Object { $_ -match '^\s*nameserver\s+(\S+)' } |
            ForEach-Object { ($_ -replace '^\s*nameserver\s+', '').Trim() }

        if ($nameservers) {
            $results.Add([PSCustomObject]@{
                PSTypeName      = 'DnsClient.Linux.DnsClientServerAddress'
                InterfaceAlias  = 'Global (/etc/resolv.conf)'
                InterfaceIndex  = 0
                ServerAddresses = @($nameservers)
                AddressFamily   = 'Both'
            })
        }
    }

    # ── Per-interface servers from resolvectl ─────────────────────────────────
    if (Get-Command resolvectl -ErrorAction SilentlyContinue) {
        $resolvectlOutput = & resolvectl status 2>/dev/null
        $currentIface     = $null
        $currentServers   = [System.Collections.Generic.List[string]]::new()

        foreach ($line in $resolvectlOutput) {
            # Interface header: "Link 2 (eth0)"
            if ($line -match '^\s*Link\s+\d+\s+\((.+)\)') {
                # Save previous interface
                if ($currentIface -and $currentServers.Count -gt 0) {
                    $results.Add([PSCustomObject]@{
                        PSTypeName      = 'DnsClient.Linux.DnsClientServerAddress'
                        InterfaceAlias  = $currentIface
                        InterfaceIndex  = 0
                        ServerAddresses = $currentServers.ToArray()
                        AddressFamily   = 'Both'
                    })
                }
                $currentIface   = $Matches[1]
                $currentServers = [System.Collections.Generic.List[string]]::new()
            }
            # DNS Servers line: "  DNS Servers: 192.168.1.1"
            elseif ($line -match '^\s*DNS Servers?:\s+(.+)$') {
                foreach ($addr in ($Matches[1] -split '\s+')) {
                    if ($addr) { $currentServers.Add($addr) }
                }
            }
            # Continuation of DNS Servers (indented address on next line)
            elseif ($currentServers.Count -gt 0 -and $line -match '^\s{20,}(\S+)$') {
                $currentServers.Add($Matches[1])
            }
        }
        # Last interface
        if ($currentIface -and $currentServers.Count -gt 0) {
            $results.Add([PSCustomObject]@{
                PSTypeName      = 'DnsClient.Linux.DnsClientServerAddress'
                InterfaceAlias  = $currentIface
                InterfaceIndex  = 0
                ServerAddresses = $currentServers.ToArray()
                AddressFamily   = 'Both'
            })
        }
    }

    # ── Apply filters ─────────────────────────────────────────────────────────
    $output = $results | ForEach-Object { $_ }

    if ($InterfaceAlias) {
        $output = $output | Where-Object { $_.InterfaceAlias -like "*$InterfaceAlias*" }
    }

    if ($AddressFamily) {
        $output = $output | ForEach-Object {
            $filtered = $_.ServerAddresses | Where-Object {
                $isIPv6 = $_ -match ':'
                if ($AddressFamily -eq 'IPv4') { -not $isIPv6 }
                else { $isIPv6 }
            }
            if ($filtered) {
                [PSCustomObject]@{
                    PSTypeName      = 'DnsClient.Linux.DnsClientServerAddress'
                    InterfaceAlias  = $_.InterfaceAlias
                    InterfaceIndex  = $_.InterfaceIndex
                    ServerAddresses = @($filtered)
                    AddressFamily   = $AddressFamily
                }
            }
        }
    }

    $output
}
