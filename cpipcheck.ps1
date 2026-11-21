<#
.SYNOPSIS
    cpipcheck.ps1 — cPanel/WHM IP License Checker CLI (PowerShell)

.DESCRIPTION
    Verifies cPanel/WHM, LiteSpeed, CloudLinux, and partner licenses by IPv4 via
    https://verify.cpanel.net/app/verify with batch mode, reverse DNS (PTR),
    license history, and table/json/csv outputs.

    Author  : Percio Castelo <percio@perciocastelo.com.br>
    Website : https://perciocastelo.com.br
    Project : https://perciocastelo.com.br/projetos/en/cpanel-ip-license-check.html
    Repo    : https://github.com/sr00t3d/cpipcheck
    License : Apache-2.0
    Version : 2.1.0

.EXAMPLE
    .\cpipcheck.ps1 208.74.121.53
    .\cpipcheck.ps1 208.74.121.53 -History
    .\cpipcheck.ps1 -Self -Output json
    .\cpipcheck.ps1 -File ips.txt -Output csv
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Ips,

    [switch]$Self,

    [Alias('f')]
    [string]$File,

    [Alias('H')]
    [switch]$History,

    [Alias('o')]
    [ValidateSet('table', 'json', 'csv')]
    [string]$Output = 'table',

    [Alias('t')]
    [int]$Timeout = 10,

    [Alias('q')]
    [switch]$Quiet,

    [switch]$NoColor,

    [Alias('V')]
    [switch]$Version,

    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptName = 'cpipcheck.ps1'
$ScriptVersion = '2.1.0'
$VerifyBaseUrl = 'https://verify.cpanel.net/app/verify'
$TimestampUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

function Show-Help {
@"
$ScriptName v$ScriptVersion — cPanel/WHM IP License Checker CLI (PowerShell)

Usage:
  .\cpipcheck.ps1 <ipv4> [ipv4 ...] [options]
  .\cpipcheck.ps1 -Self [options]
  .\cpipcheck.ps1 -File <ips.txt> [options]

Options:
  -Self                      Auto-detect and check current host's public IPv4
  -File, -f <path>           Read IPv4 addresses from a file (one per line)
  -History, -H               Include historical/expired license entries
  -Output, -o <fmt>          Output format: table (default), json, csv
  -Timeout, -t <sec>         HTTP timeout in seconds (default: 10)
  -Quiet, -q                 Suppress banner header
  -NoColor                   Disable colored output
  -Version, -V               Show version and exit
  -Help                      Show this help and exit
"@ | Write-Output
}

function Write-ColorLine {
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    if ($NoColor -or $env:NO_COLOR -or $Output -ne 'table') { Write-Output $Text }
    else { Write-Host $Text -ForegroundColor $Color }
}

function Test-IPv4 {
    param([string]$Value)
    $parsed = $null
    if ([System.Net.IPAddress]::TryParse($Value, [ref]$parsed)) {
        return ($parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork)
    }
    return $false
}

function Get-PublicIPv4 {
    foreach ($ep in @('https://api.ipify.org', 'https://ifconfig.me/ip', 'https://icanhazip.com')) {
        try {
            $r = (Invoke-RestMethod -Uri $ep -TimeoutSec 5 -ErrorAction Stop).ToString().Trim()
            if (Test-IPv4 $r) { return $r }
        } catch { }
    }
    throw 'Could not auto-detect public IPv4.'
}

function Get-Ptr {
    param([string]$Ip)
    try {
        $e = [System.Net.Dns]::GetHostEntry($Ip)
        if ($e.HostName -and $e.HostName -ne $Ip) { return $e.HostName.TrimEnd('.') }
    } catch { }
    return ''
}

function Strip-Html {
    param([string]$Raw)
    $noTags = [regex]::Replace($Raw, '<[^>]+>', ' ')
    $decoded = [System.Net.WebUtility]::HtmlDecode($noTags)
    return ([regex]::Replace($decoded, '\s+', ' ')).Trim()
}

if ($Help) { Show-Help; exit 0 }
if ($Version) { Write-Output "$ScriptName $ScriptVersion"; exit 0 }

$Targets = New-Object System.Collections.Generic.List[string]
if ($Ips) { foreach ($i in $Ips) { if ($i.Trim()) { $Targets.Add($i.Trim()) } } }
if ($File) {
    if (-not (Test-Path -LiteralPath $File)) { Write-Error "[ERR] File not found: $File"; exit 1 }
    foreach ($raw in (Get-Content -LiteralPath $File -Encoding UTF8)) {
        $line = ($raw -replace '#.*$', '').Trim()
        if ($line) { $Targets.Add($line) }
    }
}
if ($Self) { $Targets.Add((Get-PublicIPv4)) }
if ($Targets.Count -eq 0) { Show-Help; exit 1 }

foreach ($ip in $Targets) {
    if (-not (Test-IPv4 $ip)) { Write-Error "[ERR] Invalid IPv4 address: $ip"; exit 1 }
}

$Headers = @{ 'User-Agent' = "cpipcheck/$ScriptVersion (+https://github.com/sr00t3d/cpipcheck)" }
$Results = New-Object System.Collections.Generic.List[object]

foreach ($ip in $Targets) {
    $ptr = Get-Ptr $ip
    $url = "${VerifyBaseUrl}?ip=$([System.Uri]::EscapeDataString($ip))"
    $activeList = @()
    $historyList = @()
    $errorMsg = ''

    try {
        $resp = Invoke-WebRequest -Uri $url -Headers $Headers -TimeoutSec $Timeout -UseBasicParsing -ErrorAction Stop
        $html = $resp.Content
        $tableMatch = [regex]::Match($html, '(?is)<table[^>]*class="[^"]*history[^"]*"[^>]*>(.*?)</table>')
        if ($tableMatch.Success) {
            $tbody = $tableMatch.Groups[1].Value
            $rowMatches = [regex]::Matches($tbody, '(?is)<tr[^>]*>(.*?)</tr>')
            foreach ($rm in $rowMatches) {
                $cells = [regex]::Matches($rm.Groups[1].Value, '(?is)<td[^>]*>(.*?)</td>')
                if ($cells.Count -lt 4) { continue }
                $pkg = Strip-Html $cells[0].Groups[1].Value
                $status = Strip-Html $cells[1].Groups[1].Value
                $actDate = if ($cells.Count -gt 2) { Strip-Html $cells[2].Groups[1].Value } else { '' }
                $expDate = if ($cells.Count -gt 3) { Strip-Html $cells[3].Groups[1].Value } else { '' }
                $entry = [PSCustomObject]@{
                    package    = $pkg
                    status     = $status
                    activated  = $actDate
                    updated    = $expDate
                }
                if ($status -match '(?i)^active') { $activeList += $entry }
                else { $historyList += $entry }
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
    }

    $licensed = ($activeList.Count -gt 0)
    $Results.Add([PSCustomObject]@{
        ip              = $ip
        ptr             = $ptr
        licensed        = $licensed
        active_count    = $activeList.Count
        history_count   = $historyList.Count
        active_licenses = $activeList
        history         = if ($History) { $historyList } else { @() }
        error           = $errorMsg
    })
}

switch ($Output) {
    'json' {
        [PSCustomObject]@{
            tool      = $ScriptName
            version   = $ScriptVersion
            timestamp = $TimestampUtc
            total     = $Results.Count
            results   = $Results
        } | ConvertTo-Json -Depth 6 | Write-Output
    }
    'csv' {
        Write-Output 'ip,ptr,licensed,active_count,packages,error'
        foreach ($r in $Results) {
            $pkgs = (@($r.active_licenses | ForEach-Object { $_.package }) -join '; ')
            $vals = @($r.ip, $r.ptr, $r.licensed, $r.active_count, $pkgs, $r.error) |
                ForEach-Object { '"' + ([string]$_ -replace '"', '""') + '"' }
            Write-Output ($vals -join ',')
        }
    }
    default {
        if (-not $Quiet) {
            Write-ColorLine ('=' * 78) ([ConsoleColor]::Cyan)
            Write-Output (" {0} v{1} | cPanel/WHM IP License Verification | {2}" -f $ScriptName, $ScriptVersion, $TimestampUtc)
            Write-ColorLine ('=' * 78) ([ConsoleColor]::Cyan)
            Write-Output ''
        }
        foreach ($r in $Results) {
            if ($r.error) {
                Write-ColorLine ("[ERR] {0,-15} : {1}" -f $r.ip, $r.error) ([ConsoleColor]::Red)
            } elseif ($r.licensed) {
                $pkgs = (@($r.active_licenses | ForEach-Object { $_.package }) -join ', ')
                Write-ColorLine ("[OK]  {0,-15} : LICENSED ({1}) {2}" -f $r.ip, $pkgs, $(if ($r.ptr) { "[$($r.ptr)]" } else { '' })) ([ConsoleColor]::Green)
            } else {
                Write-ColorLine ("[!]   {0,-15} : NOT LICENSED {1}" -f $r.ip, $(if ($r.ptr) { "[$($r.ptr)]" } else { '' })) ([ConsoleColor]::Yellow)
            }
            if ($History -and $r.history.Count -gt 0) {
                foreach ($h in $r.history) {
                    Write-Output ("      history -> {0} | {1} | {2}" -f $h.package, $h.status, $h.activated)
                }
            }
        }
    }
}
exit 0
