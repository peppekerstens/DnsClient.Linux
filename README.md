# DnsClient.Linux

PowerShell 7.x module providing cmdlet parity with the Windows `DnsClient` module on Linux. Wraps `dig` and `resolvectl` to deliver familiar DNS resolution and configuration cmdlets.

Part of the **Linux PowerShell Cmdlet Parity** project — inspired by Evgenij Smirnov's [2025 European PowerShell Summit session](https://www.youtube.com/watch?v=RlzinWYIjBY) and documented in the blog series at [peppekerstens.github.io](https://peppekerstens.github.io/linux-command-wrapping-part-1/).

---

## What it does

On **Linux**, wraps `dig`, `resolvectl`, and `/etc/resolv.conf` to provide PowerShell cmdlets matching the Windows `DnsClient` module API as closely as possible. All 21 cmdlets that the Windows module exports are present — 4 are fully implemented, the remaining 17 are stubs that emit a warning on Linux.

On **Windows**, use the built-in `DnsClient` module directly — this module refuses to load there.

---

## Requirements

- PowerShell 7.2+
- **Linux only** — the module refuses to load on Windows (throws a descriptive error)
- `dig` (package: `dnsutils` / `bind9-dnsutils`) for `Resolve-DnsName`
- `resolvectl` (systemd-resolved) or `nscd` for `Clear-DnsClientCache`
- `/etc/resolv.conf` for `Get-DnsClientServerAddress` and `Get-DnsClientGlobalSetting`

---

## Installation

```powershell
# Clone or copy the module folder to a PSModulePath location, then:
Import-Module DnsClient.Linux
```

---

## Usage

```powershell
# Resolve an A record
Resolve-DnsName -Name 'dns.google'

# Resolve AAAA records
Resolve-DnsName -Name 'dns.google' -Type AAAA

# Resolve using a specific DNS server
Resolve-DnsName -Name 'example.com' -Server '8.8.8.8'

# Reverse lookup
Resolve-DnsName -Name '8.8.8.8' -Type PTR

# Show configured DNS servers per interface
Get-DnsClientServerAddress

# IPv4 DNS servers only
Get-DnsClientServerAddress -AddressFamily IPv4

# Show the DNS search suffix list
Get-DnsClientGlobalSetting

# Flush the DNS cache
Clear-DnsClientCache

# Preview the cache flush without running it
Clear-DnsClientCache -WhatIf
```

---

## Cmdlet Status

Legend: ✅ Implemented &nbsp;|&nbsp; ⚠️ Stub

| Cmdlet | Status | Linux tool | Notes |
|---|:---:|---|---|
| `Resolve-DnsName` | ✅ | `dig` | A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT, ANY; `-Name`, `-Type`, `-Server` parameters; throws with install hint if `dig` missing |
| `Clear-DnsClientCache` | ✅ | `resolvectl flush-caches` | Falls back to `nscd --invalidate=hosts`; supports `-WhatIf` / `-Confirm` |
| `Get-DnsClientServerAddress` | ✅ | `/etc/resolv.conf` + `resolvectl status` | Per-interface DNS server list; `-InterfaceAlias`, `-AddressFamily` filters |
| `Get-DnsClientGlobalSetting` | ✅ | `/etc/resolv.conf` + `resolvectl status` | Returns `SuffixSearchList` from search/domain lines |
| `Add-DnsClientDohServerAddress` | ⚠️ | Stub | DNS-over-HTTPS — Windows-specific |
| `Add-DnsClientNrptRule` | ⚠️ | Stub | NRPT — Windows-specific policy table |
| `Get-DnsClient` | ⚠️ | Stub | CIM/WMI-based — use `resolvectl status` |
| `Get-DnsClientCache` | ⚠️ | Stub | Future: `resolvectl statistics` |
| `Get-DnsClientDohServerAddress` | ⚠️ | Stub | DNS-over-HTTPS — Windows-specific |
| `Get-DnsClientNrptGlobal` | ⚠️ | Stub | NRPT — Windows-specific |
| `Get-DnsClientNrptPolicy` | ⚠️ | Stub | NRPT — Windows-specific |
| `Get-DnsClientNrptRule` | ⚠️ | Stub | NRPT — Windows-specific |
| `Register-DnsClient` | ⚠️ | Stub | AD DNS registration — Windows-specific |
| `Remove-DnsClientDohServerAddress` | ⚠️ | Stub | DNS-over-HTTPS — Windows-specific |
| `Remove-DnsClientNrptRule` | ⚠️ | Stub | NRPT — Windows-specific |
| `Set-DnsClient` | ⚠️ | Stub | CIM/WMI-based — Windows-specific |
| `Set-DnsClientDohServerAddress` | ⚠️ | Stub | DNS-over-HTTPS — Windows-specific |
| `Set-DnsClientGlobalSetting` | ⚠️ | Stub | Future: edit `/etc/resolv.conf` |
| `Set-DnsClientNrptGlobal` | ⚠️ | Stub | NRPT — Windows-specific |
| `Set-DnsClientNrptRule` | ⚠️ | Stub | NRPT — Windows-specific |
| `Set-DnsClientServerAddress` | ⚠️ | Stub | Future: edit `/etc/resolv.conf` / `resolvectl` |

---

## Implementation notes

- `Resolve-DnsName` runs `dig +noall +answer +authority +additional +ttlid +comments` and parses section output into typed objects. If `dig` is not installed it throws a terminating `ErrorRecord` with `ErrorCategory.NotInstalled` and the install command in the message.
- `Clear-DnsClientCache` tries `resolvectl flush-caches` first, then falls back to `nscd --invalidate=hosts`. Fully `ShouldProcess`-aware (`-WhatIf` / `-Confirm`).
- `Get-DnsClientServerAddress` reads `nameserver` lines from `/etc/resolv.conf` as the global entry and queries `resolvectl status` for per-interface DNS assignments.
- `Get-DnsClientGlobalSetting` reads `search`/`domain` lines from `/etc/resolv.conf` and merges with `resolvectl status` global DNS Domain output. `UseDevolution` and `DevolutionLevel` are returned as `$false` / `0` — they are Windows-specific concepts with no Linux equivalent.

### Why 17 stubs?

The Windows `DnsClient` module's NRPT (Name Resolution Policy Table) and DoH (DNS-over-HTTPS) cmdlets, plus `Register-DnsClient` and `Get-DnsClient`, all rely on Windows-specific CIM/WMI classes or the Windows DNS client policy engine. There is no direct Linux equivalent. Stubs ensure that cross-platform scripts calling these cmdlets get a clear warning rather than a command-not-found error.

---

## How we built this

### Why a separate module from NetTCPIP.Linux

The Windows DNS client functionality lives in the `DnsClient` module, which is separate from `NetTCPIP`. Keeping them separate on Linux mirrors that boundary — a script that does `Import-Module DnsClient` should be able to swap in `Import-Module DnsClient.Linux` without also pulling in all the IP routing and TCP connection machinery.

### Tool choices

**`dig`** was the natural choice for `Resolve-DnsName`. The `host` and `nslookup` tools are simpler but have less structured output and fewer record type options. `dig +noall +answer +authority +additional +ttlid +comments` gives predictable section-delimited output that maps cleanly to the Windows cmdlet's `Section` property. The parser reads section header comments (`;;  ANSWER SECTION:`, etc.) to track which section each record belongs to.

**`resolvectl`** (from systemd-resolved) handles cache flushing and per-interface DNS server queries. On most modern Ubuntu/Debian/RHEL systems this is the DNS resolver. The fallback to `nscd --invalidate=hosts` covers older systems.

**`/etc/resolv.conf`** is the universal baseline for DNS server and search domain configuration — it exists on every Linux system regardless of which resolver is running.

### Key gotchas

**`dig` output has a `Listing...`-style header only when querying multiple types.** For a single record type query, the output is clean. For `ANY`, dig emits a preamble. The parser skips all lines starting with `;` (comments) and blank lines, which handles both cases.

**PTR records need the IP reversed.** `dig 8.8.8.8 PTR` does not work — you need `dig -x 8.8.8.8` or `dig 8.8.8.8.in-addr.arpa PTR`. `Resolve-DnsName -Type PTR` on Windows accepts the plain IP and handles the reversal internally. Our implementation passes the name directly to `dig`, so callers should pass the already-reversed ARPA name for PTR queries, or pass the plain IP and use `-Type PTR` which `dig` handles correctly via the `@server name type` argument order.

**MX records have a preference value.** `dig` returns MX as `10 mail.example.com.` — priority first, then the hostname. The parser splits on whitespace and maps to `Preference` and `NameExchange` properties, matching the Windows output shape.

---

## Version history

| Version | Notes |
|---|---|
| 0.1.0 | Initial release, extracted from NetTCPIP.Linux v0.3.0. `Resolve-DnsName`, `Clear-DnsClientCache`, `Get-DnsClientServerAddress`, `Get-DnsClientGlobalSetting` implemented. 17 stubs. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
