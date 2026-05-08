function Clear-DnsClientCache {
    <#
    .Synopsis
        Clears the contents of the DNS client cache.
    .Description
        Flushes the local DNS resolver cache using `resolvectl flush-caches`
        (systemd-resolved) on Linux.

        If systemd-resolved is not running, falls back to restarting `nscd`
        (Name Service Cache Daemon) if it is installed and running.

        Requires systemd-resolved to be active, or nscd to be installed.
        On most modern Ubuntu/Debian/RHEL systems, systemd-resolved handles DNS caching.

        Unsupported Windows parameters: -CimSession, -ThrottleLimit, -AsJob.
    .Example
        # Flush the local DNS cache
        Clear-DnsClientCache

    .Example
        # Flush with confirmation of what was done
        Clear-DnsClientCache -Verbose

    .Link
        https://learn.microsoft.com/powershell/module/dnsclient/clear-dnsclientcache
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param()

    if ($PSCmdlet.ShouldProcess('DNS client cache', 'Flush')) {
        # Try systemd-resolved first (most modern Linux distros)
        if (Get-Command resolvectl -ErrorAction SilentlyContinue) {
            $output = & resolvectl flush-caches 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose 'DNS cache flushed via resolvectl flush-caches.'
                return
            }
            Write-Verbose "resolvectl flush-caches exited $LASTEXITCODE`: $output"
        }

        # Fallback: nscd
        if (Get-Command nscd -ErrorAction SilentlyContinue) {
            $status = & systemctl is-active nscd 2>/dev/null
            if ($status -eq 'active') {
                $output = & nscd --invalidate=hosts 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Verbose 'DNS cache flushed via nscd --invalidate=hosts.'
                    return
                }
            }
        }

        $ex  = [System.InvalidOperationException]::new(
            'Cannot flush DNS cache: neither systemd-resolved (resolvectl) nor nscd is available or active. ' +
            'Ensure systemd-resolved is running: sudo systemctl start systemd-resolved'
        )
        $err = [System.Management.Automation.ErrorRecord]::new(
            $ex, 'Clear-DnsClientCache.NoResolverFound',
            [System.Management.Automation.ErrorCategory]::ResourceUnavailable, 'DNS cache'
        )
        $PSCmdlet.ThrowTerminatingError($err)
    }
}
