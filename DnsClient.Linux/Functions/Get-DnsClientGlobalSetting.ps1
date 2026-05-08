function Get-DnsClientGlobalSetting {
    <#
    .Synopsis
        Retrieves global DNS client settings — suffix search list and related options.
    .Description
        Reads global DNS client settings from `/etc/resolv.conf` (search/domain lines)
        and `resolvectl status` (global DNS Domain setting). Returns an object with
        SuffixSearchList and UseDevolution properties, matching the Windows output shape.

        Unsupported Windows parameters: -CimSession, -AsJob.
    .Example
        # Get global DNS search suffix settings
        Get-DnsClientGlobalSetting

    .Example
        # Show the search suffix list
        (Get-DnsClientGlobalSetting).SuffixSearchList

    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/get-dnsclientglobalsetting
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $suffixes = [System.Collections.Generic.List[string]]::new()

    # Read /etc/resolv.conf for search and domain directives
    if (Test-Path '/etc/resolv.conf') {
        foreach ($line in (Get-Content '/etc/resolv.conf')) {
            # "search domain1 domain2 ..."
            if ($line -match '^\s*search\s+(.+)$') {
                foreach ($s in ($Matches[1] -split '\s+')) {
                    if ($s -and -not $suffixes.Contains($s)) { $suffixes.Add($s) }
                }
            }
            # "domain domain1" — single default domain
            elseif ($line -match '^\s*domain\s+(\S+)$') {
                $d = $Matches[1]
                if (-not $suffixes.Contains($d)) { $suffixes.Add($d) }
            }
        }
    }

    # Also check resolvectl for global DNS Domain setting
    if (Get-Command resolvectl -ErrorAction SilentlyContinue) {
        $resolvectlOutput = & resolvectl status 2>/dev/null
        $inGlobal = $false
        foreach ($line in $resolvectlOutput) {
            if ($line -match '^\s*Global\s*$' -or $line -match '^\s*\(Defaults\)') {
                $inGlobal = $true
            } elseif ($line -match '^\s*Link\s+\d+') {
                $inGlobal = $false
            }
            if ($inGlobal -and $line -match '^\s*DNS Domain:\s+(.+)$') {
                foreach ($s in ($Matches[1] -split '\s+')) {
                    if ($s -and -not $suffixes.Contains($s)) { $suffixes.Add($s) }
                }
            }
        }
    }

    [PSCustomObject]@{
        PSTypeName       = 'DnsClient.Linux.DnsClientGlobalSetting'
        SuffixSearchList = $suffixes.ToArray()
        UseDevolution    = $false   # Windows-specific concept; not applicable on Linux
        DevolutionLevel  = 0        # Windows-specific concept
    }
}
