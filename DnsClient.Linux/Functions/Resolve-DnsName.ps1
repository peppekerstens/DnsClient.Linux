function Resolve-DnsName {
    <#
    .Synopsis
        Performs a DNS name query resolution for the specified name.
    .Description
        Uses `dig` to resolve DNS names on Linux. Returns objects matching the
        Windows Resolve-DnsName output shape as closely as possible, with
        Name, Type, TTL, Section, and record-specific properties (IPAddress,
        NameHost, Strings, etc.).

        Requires `dig` (part of the `bind-utils` or `dnsutils` package):
          sudo apt install dnsutils   (Debian/Ubuntu)
          sudo dnf install bind-utils (RHEL/Fedora)

        Unsupported Windows parameters: -DnsOnly, -DnssecCd, -DnssecOk,
        -LlmnrNetbiosOnly, -LlmnrOnly, -NetbiosFallback, -NoHostsFile,
        -NoIdn, -CacheOnly. These emit a warning and are ignored.
    .Parameter Name
        The DNS name to resolve. Required.
    .Parameter Type
        The DNS record type to query. Default: A.
        Supported: A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT, ANY.
    .Parameter Server
        The DNS server to query. If omitted, uses the system resolver.
    .Parameter DnsOnly
        Not supported on Linux. Emits a warning and is ignored.
    .Parameter NoHostsFile
        Not supported on Linux. Emits a warning and is ignored.
    .Example
        # Resolve an A record
        Resolve-DnsName -Name 'google.com'

    .Example
        # Resolve MX records
        Resolve-DnsName -Name 'google.com' -Type MX

    .Example
        # Resolve using a specific DNS server
        Resolve-DnsName -Name 'google.com' -Server '8.8.8.8'

    .Example
        # Reverse lookup
        Resolve-DnsName -Name '8.8.8.8' -Type PTR

    .Example
        # Get all record types
        Resolve-DnsName -Name 'google.com' -Type ANY

    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/resolve-dnsname
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter()]
        [ValidateSet('A','AAAA','CNAME','MX','NS','PTR','SOA','SRV','TXT','ANY')]
        [string] $Type = 'A',

        [Parameter()]
        [string] $Server,

        [Parameter()]
        [switch] $DnsOnly,

        [Parameter()]
        [switch] $NoHostsFile
    )

    process {
        if ($DnsOnly)     { Write-Warning 'Resolve-DnsName: -DnsOnly is not supported on Linux. Ignoring.' }
        if ($NoHostsFile) { Write-Warning 'Resolve-DnsName: -NoHostsFile is not supported on Linux. Ignoring.' }

        if (-not (Get-Command dig -ErrorAction SilentlyContinue)) {
            $ex  = [System.InvalidOperationException]::new(
                'dig not found. Install bind-utils/dnsutils: sudo apt install dnsutils (Debian/Ubuntu) or sudo dnf install bind-utils (RHEL/Fedora).'
            )
            $err = [System.Management.Automation.ErrorRecord]::new(
                $ex, 'Resolve-DnsName.DigNotFound',
                [System.Management.Automation.ErrorCategory]::NotInstalled, 'dig'
            )
            $PSCmdlet.ThrowTerminatingError($err)
        }

        # Build dig arguments
        # +nocmd +nocomments suppresses decorative output; keep section comments for parsing
        $digArgs = @($Name, $Type, '+noall', '+answer', '+authority', '+additional', '+ttlid')
        if ($Server) { $digArgs = @("@$Server") + $digArgs }

        $lines = & dig @digArgs 2>/dev/null

        # Parse dig output lines of the form:
        # <name>  <ttl>  IN  <type>  <rdata...>
        # Section is inferred from position — dig outputs ANSWER then AUTHORITY then ADDITIONAL
        # We need the section headers to determine section
        $currentSection = 'Answer'
        $rawLines = & dig @($digArgs[0..($digArgs.Count-1)]) 2>/dev/null

        # Run dig with section comments to detect section boundaries
        $digArgsFull = @($Name, $Type, '+noall', '+answer', '+authority', '+additional', '+ttlid', '+comments')
        if ($Server) { $digArgsFull = @("@$Server") + $digArgsFull }
        $rawLines = & dig @digArgsFull 2>/dev/null

        $currentSection = 'Answer'
        foreach ($line in $rawLines) {
            # Section header comments
            if ($line -match ';;.*(ANSWER|AUTHORITY|ADDITIONAL)\s+SECTION') {
                $currentSection = switch ($Matches[1]) {
                    'ANSWER'     { 'Answer' }
                    'AUTHORITY'  { 'Authority' }
                    'ADDITIONAL' { 'Additional' }
                }
                continue
            }
            # Skip comments and blank lines
            if ($line -match '^\s*$' -or $line -match '^;') { continue }

            # Parse record line: <name> <ttl> IN <type> <rdata>
            if ($line -match '^(\S+)\s+(\d+)\s+IN\s+(\S+)\s+(.+)$') {
                $recName  = $Matches[1].TrimEnd('.')
                $recTtl   = [int]$Matches[2]
                $recType  = $Matches[3]
                $recRdata = $Matches[4].Trim()

                $obj = [ordered]@{
                    PSTypeName = 'DnsClient.Linux.DnsRecord'
                    Name       = $recName
                    Type       = $recType
                    TTL        = $recTtl
                    Section    = $currentSection
                }

                switch ($recType) {
                    'A'     { $obj['IPAddress']  = $recRdata }
                    'AAAA'  { $obj['IPAddress']  = $recRdata }
                    'PTR'   { $obj['NameHost']   = $recRdata.TrimEnd('.') }
                    'CNAME' { $obj['NameHost']   = $recRdata.TrimEnd('.') }
                    'NS'    { $obj['NameHost']   = $recRdata.TrimEnd('.') }
                    'MX'    {
                        if ($recRdata -match '^(\d+)\s+(\S+)$') {
                            $obj['Preference'] = [int]$Matches[1]
                            $obj['NameExchange'] = $Matches[2].TrimEnd('.')
                        } else {
                            $obj['NameExchange'] = $recRdata.TrimEnd('.')
                        }
                    }
                    'TXT'   { $obj['Strings']    = $recRdata -replace '"', '' }
                    'SOA'   {
                        # <mname> <rname> <serial> <refresh> <retry> <expire> <minimum>
                        if ($recRdata -match '^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$') {
                            $obj['PrimaryServer']   = $Matches[1].TrimEnd('.')
                            $obj['NameAdministrator'] = $Matches[2].TrimEnd('.')
                            $obj['SerialNumber']    = [int]$Matches[3]
                            $obj['TimeToZoneRefresh'] = [int]$Matches[4]
                            $obj['TimeToZoneFailureRetry'] = [int]$Matches[5]
                            $obj['TimeToExpiration'] = [int]$Matches[6]
                            $obj['DefaultTTL']      = [int]$Matches[7]
                        }
                    }
                    'SRV'   {
                        # <priority> <weight> <port> <target>
                        if ($recRdata -match '^(\d+)\s+(\d+)\s+(\d+)\s+(\S+)$') {
                            $obj['Priority'] = [int]$Matches[1]
                            $obj['Weight']   = [int]$Matches[2]
                            $obj['Port']     = [int]$Matches[3]
                            $obj['NameTarget'] = $Matches[4].TrimEnd('.')
                        }
                    }
                    default { $obj['RecordData'] = $recRdata }
                }

                [PSCustomObject]$obj
            }
        }
    }
}
