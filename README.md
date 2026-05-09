# DnsClient.Linux

PowerShell 7.x module providing cmdlet parity with the Windows `DnsClient` module on Linux. Wraps `resolvectl` (systemd-resolved) to deliver familiar DNS resolution and configuration cmdlets.

Part of the **Linux PowerShell Cmdlet Parity** project — inspired by Evgenij Smirnov's [2025 European PowerShell Summit session](https://www.youtube.com/watch?v=RlzinWYIjBY) and documented in the blog series at [peppekerstens.github.io](https://peppekerstens.github.io/linux-command-wrapping-part-1/).

---

## What it does

On **Linux**, wraps `resolvectl` (systemd-resolved) and `/etc/resolv.conf` to provide PowerShell cmdlets matching the Windows `DnsClient` module API as closely as possible. All 21 cmdlets that the Windows module exports are present — 4 are fully implemented, the remaining 17 are stubs that emit a warning on Linux.

On **Windows**, use the built-in `DnsClient` module directly — this module refuses to load there.

---

## Requirements

- PowerShell 7.2+
- **Linux only** — the module refuses to load on Windows (throws a descriptive error)
- `resolvectl` (systemd-resolved) — required for `Resolve-DnsName`, `Clear-DnsClientCache`, and `Get-DnsClientServerAddress`. Available by default on Ubuntu 20.04+, Debian 11+, Fedora 36+, openSUSE Leap 15.4+. Falls back to `nscd --invalidate=hosts` for cache flush on older systems.
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
| `Resolve-DnsName` | ✅ | `resolvectl query --json=short` | A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT; `-Name`, `-Type` parameters; `-Server` emits a warning (resolvectl uses the system resolver); throws with descriptive error if `resolvectl` missing; PTR accepts plain IP — arpa conversion handled automatically |
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

- `Resolve-DnsName` runs `resolvectl query --type=<TYPE> --json=short <name>`. Each result is a separate JSON object on its own line. Record types A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, and TXT are mapped to the Windows property shapes. IPv4 addresses come back as `[octet, octet, octet, octet]` and are joined with `.`; IPv6 as a 16-byte array and converted via `[System.Net.IPAddress]`. PTR queries accept a bare IPv4 or IPv6 address — the function converts to the appropriate `.in-addr.arpa` or `.ip6.arpa` form before querying. If `resolvectl` is not installed, a terminating `ErrorRecord` is thrown with `ErrorCategory.NotInstalled`. The `-Server` parameter is not supported (resolvectl always uses the system resolver) — a warning is emitted and the query proceeds.
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

**`resolvectl query --json=short`** is the backend for `Resolve-DnsName`. It ships with systemd-resolved, which is the default DNS resolver on modern Ubuntu, Debian, Fedora, openSUSE, and most cloud images. Crucially, it supports `--json=short` and `--type=<TYPE>` — each record comes back as a separate JSON object on its own line, with a typed `key.type` field and record-specific fields (`address`, `exchange`, `priority`, `name`, `items`, etc.). No text parsing required.

The earlier implementation used `dig`, which was the natural first choice given its structured section-delimited output. Two problems emerged: `dig` has no JSON mode (so it was the one text-parser among otherwise JSON-parsed backends), and `dig` is not installed by default on many modern distros — including the Ubuntu WSL2 environment used for testing. `resolvectl` is always present when systemd-resolved is running, which it is on every target distro.

The one trade-off: `resolvectl query` always uses the system resolver. The `-Server` parameter — which `dig` supported via `@server` — is not honoured. A warning is emitted if `-Server` is passed. To use a different resolver, configure it via `resolvectl dns`.

**`resolvectl`** (from systemd-resolved) also handles cache flushing and per-interface DNS server queries. The fallback to `nscd --invalidate=hosts` covers systems where systemd-resolved manages the cache through a different mechanism.

**`/etc/resolv.conf`** is the universal baseline for DNS server and search domain configuration — it exists on every Linux system regardless of which resolver is running.

### Key gotchas

**PTR lookup arpa conversion is automatic.** Pass the plain IP address (`'8.8.8.8'`) — the function converts it to `8.8.8.8.in-addr.arpa` for IPv4 or the appropriate nibble-reversed `.ip6.arpa` form for IPv6, matching the Windows behaviour.

**`resolvectl` does not support ad-hoc server selection.** The `-Server` parameter emits a warning and is ignored. To query a specific server, use the system-level `resolvectl dns <interface> <server>` to configure it, then call `Resolve-DnsName`.

**MX records have a preference value.** `resolvectl` returns MX records with `priority` and `exchange` fields in the JSON. These map to `Preference` and `NameExchange` properties, matching the Windows output shape.

**`ANY` queries are not supported.** `resolvectl query --type=ANY` is not a standard query type in all resolver implementations and returns inconsistent results. The `ValidateSet` has been updated to exclude it; use multiple explicit type queries instead.

---

## Version history

| Version | Notes |
|---|---|
| 0.2.0 | `Resolve-DnsName` rewritten to use `resolvectl query --json=short` instead of `dig`. PTR arpa conversion automatic. `-Server` emits warning instead of being passed to backend. `ANY` type removed (not reliably supported by resolvectl). Tests updated to use `resolvectl` availability guard. |
| 0.1.0 | Initial release, extracted from NetTCPIP.Linux v0.3.0. `Resolve-DnsName`, `Clear-DnsClientCache`, `Get-DnsClientServerAddress`, `Get-DnsClientGlobalSetting` implemented. 17 stubs. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
