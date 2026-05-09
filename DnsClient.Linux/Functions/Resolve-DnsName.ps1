function Resolve-DnsName {
    <#
    .Synopsis
        Performs a DNS name query resolution for the specified name.
    .Description
        Uses `resolvectl query` (systemd-resolved) to resolve DNS names on Linux.
        Returns objects matching the Windows Resolve-DnsName output shape as closely
        as possible, with Name, Type, TTL, Section, and record-specific properties
        (IPAddress, NameHost, Strings, etc.).

        Requires systemd-resolved (standard on modern Ubuntu/Debian/Fedora/openSUSE).
        No additional packages needed — resolvectl ships with systemd.

        Unsupported Windows parameters: -DnsOnly, -DnssecCd, -DnssecOk,
        -LlmnrNetbiosOnly, -LlmnrOnly, -NetbiosFallback, -NoHostsFile,
        -NoIdn, -CacheOnly, -Server. These emit a warning and are ignored.

        Note: -Server is not supported by resolvectl query; the system resolver
        is always used. Use `resolvectl dns` to change per-interface DNS servers.

        PTR lookups: pass an IP address as Name (IPv4 or IPv6); the function
        converts it to the appropriate .in-addr.arpa or .ip6.arpa form.
    .Parameter Name
        The DNS name or IP address to resolve. Required.
    .Parameter Type
        The DNS record type to query. Default: A.
        Supported: A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT.
    .Parameter Server
        Not supported on Linux with resolvectl. Emits a warning and is ignored.
    .Parameter DnsOnly
        Not supported on Linux. Emits a warning and is ignored.
    .Parameter NoHostsFile
        Not supported on Linux. Emits a warning and is ignored.
    .Example
        # Resolve an A record
        Resolve-DnsName -Name 'google.com'

    .Example
        # Resolve MX records
        Resolve-DnsName -Name 'gmail.com' -Type MX

    .Example
        # Reverse lookup from an IP address
        Resolve-DnsName -Name '8.8.8.8' -Type PTR

    .Example
        # Resolve TXT records
        Resolve-DnsName -Name 'google.com' -Type TXT

    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/resolve-dnsname
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter()]
        [ValidateSet('A','AAAA','CNAME','MX','NS','PTR','SOA','SRV','TXT')]
        [string] $Type = 'A',

        [Parameter()]
        [string] $Server,

        [Parameter()]
        [switch] $DnsOnly,

        [Parameter()]
        [switch] $NoHostsFile
    )

    process {
        if ($Server)      { Write-Warning 'Resolve-DnsName: -Server is not supported on Linux with resolvectl. The system resolver will be used. Ignoring.' }
        if ($DnsOnly)     { Write-Warning 'Resolve-DnsName: -DnsOnly is not supported on Linux. Ignoring.' }
        if ($NoHostsFile) { Write-Warning 'Resolve-DnsName: -NoHostsFile is not supported on Linux. Ignoring.' }

        if (-not (Get-Command resolvectl -ErrorAction SilentlyContinue)) {
            $ex  = [System.InvalidOperationException]::new(
                'resolvectl not found. Ensure systemd-resolved is installed and running.'
            )
            $err = [System.Management.Automation.ErrorRecord]::new(
                $ex, 'Resolve-DnsName.ResolvectlNotFound',
                [System.Management.Automation.ErrorCategory]::NotInstalled, 'resolvectl'
            )
            $PSCmdlet.ThrowTerminatingError($err)
        }

        # For PTR queries, convert bare IP to arpa form
        $queryName = $Name
        if ($Type -eq 'PTR') {
            $ipv4 = [System.Net.IPAddress]::TryParse($Name, [ref]$null)
            if ($ipv4) {
                $addr = [System.Net.IPAddress]::Parse($Name)
                if ($addr.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    # IPv4 -> a.b.c.d => d.c.b.a.in-addr.arpa
                    $queryName = ($Name -split '\.' | Select-Object -Last 4)[-1..-4] -join '.' | ForEach-Object { "$_.in-addr.arpa" }
                    $octets = $Name -split '\.'
                    [array]::Reverse($octets)
                    $queryName = ($octets -join '.') + '.in-addr.arpa'
                } else {
                    # IPv6 -> expand, reverse nibbles, append .ip6.arpa
                    $expanded = $addr.GetAddressBytes() | ForEach-Object { $_.ToString('x2') }
                    $nibbles  = ($expanded -join '') -split '' | Where-Object { $_ -ne '' }
                    [array]::Reverse($nibbles)
                    $queryName = ($nibbles -join '.') + '.ip6.arpa'
                }
            }
        }

        # DNS type number to name map (for results that come back with numeric key.type)
        $typeNames = @{
            1  = 'A'; 2 = 'NS'; 5 = 'CNAME'; 6 = 'SOA'; 12 = 'PTR'
            15 = 'MX'; 16 = 'TXT'; 28 = 'AAAA'; 33 = 'SRV'
        }

        $rawLines = resolvectl query --type=$Type --json=short $queryName 2>&1

        # Check for error output
        $errorLines = $rawLines | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] -or ($_ -is [string] -and $_ -match 'resolve call failed|not found|failed') }
        if ($errorLines) {
            Write-Error "Resolve-DnsName: $queryName : $($errorLines -join '; ')"
            return
        }

        foreach ($line in $rawLines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            # Each line is a separate JSON object
            try {
                $rec = $line | ConvertFrom-Json -ErrorAction Stop
            } catch {
                Write-Debug "Resolve-DnsName: skipping non-JSON line: $line"
                continue
            }

            $recName = $rec.key.name
            $recType = if ($typeNames.ContainsKey([int]$rec.key.type)) { $typeNames[[int]$rec.key.type] } else { "TYPE$($rec.key.type)" }

            $obj = [ordered]@{
                PSTypeName = 'DnsClient.Linux.DnsRecord'
                Name       = $recName
                Type       = $recType
                TTL        = 0    # resolvectl --json=short does not expose TTL
                Section    = 'Answer'
            }

            switch ($recType) {
                'A' {
                    $obj['IPAddress'] = ($rec.address | ForEach-Object { $_ }) -join '.'
                }
                'AAAA' {
                    # 16 bytes -> IPv6 string via IPAddress
                    $bytes  = $rec.address
                    $obj['IPAddress'] = [System.Net.IPAddress]::new([byte[]]$bytes).ToString()
                }
                'CNAME' { $obj['NameHost'] = $rec.name }
                'NS'    { $obj['NameHost'] = $rec.name }
                'PTR'   { $obj['NameHost'] = $rec.name }
                'MX'    {
                    $obj['Preference']   = [int]$rec.priority
                    $obj['NameExchange'] = $rec.exchange
                }
                'TXT'   {
                    $obj['Strings'] = $rec.items -join ' '
                }
                'SOA'   {
                    $obj['PrimaryServer']          = $rec.mname
                    $obj['NameAdministrator']      = $rec.rname
                    $obj['SerialNumber']           = [int]$rec.serial
                    $obj['TimeToZoneRefresh']      = [int]$rec.refresh
                    $obj['TimeToZoneFailureRetry'] = [int]$rec.expire
                    $obj['TimeToExpiration']       = [int]$rec.expire
                    $obj['DefaultTTL']             = [int]$rec.minimum
                }
                'SRV'   {
                    $obj['Priority']   = [int]$rec.priority
                    $obj['Weight']     = [int]$rec.weight
                    $obj['Port']       = [int]$rec.port
                    $obj['NameTarget'] = $rec.name
                }
                default {
                    $obj['RecordData'] = $line
                }
            }

            [PSCustomObject]$obj
        }
    }
}
