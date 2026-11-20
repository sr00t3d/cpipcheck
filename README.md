# cPanel IP License Check (`cpipcheck`)

Readme: [PT-BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/cpipcheck) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" alt="cPanel IP License Check" src="cpipcheck-cover.webp" />

A fast, reliable Bash + Python3 (stdlib) CLI utility to verify **cPanel/WHM**, **LiteSpeed**, **CloudLinux**, and partner licenses by IPv4 directly against `https://verify.cpanel.net/app/verify`. Supports single IP, multi-IP lists, batch files (`-f`), automatic public IP detection (`--self`), full historical records (`--history`), reverse DNS (PTR), structured `table`/`json`/`csv` output, and automation-ready exit codes.

## Features (v2.0.0)

* **Resilient HTMLParser Engine:** Parses every license row in `<table class="history table">` (including multiple active add-on licenses like `LiteSpeed`, `CloudLinux`, `Imunify360`) without fragile regex/sed chains.
* **Single, Multi-IP, Batch File & `--self`:** Pass one or more IPs on the command line, load a list with `-f servers.txt`, or auto-detect the current server's public IPv4 with `--self`.
* **License History Mode (`-H, --history`):** Displays expired/historical license records alongside active ones.
* **Reverse DNS (PTR) without Extra Packages:** Resolves PTR hostnames natively via Python `socket.gethostbyaddr` (no `bind-utils`/`dnsutils` required).
* **Structured Output (`-o table|json|csv`):** Ready for NOC terminals, Zabbix, Prometheus, SIEMs, or billing reconciliation scripts.
* **Semantic Exit Codes:** `0` = all checked IPs have an active license, `1` = runtime/network error, `2` = one or more IPs are expired or unlicensed.

## Prerequisites

* `bash` 4.0+
* `python3` (standard library only — zero `pip` packages)
* `curl` (required only when using `--self`)

## Usage & Options

```text
cPanel IP License Check (cpipcheck) v2.0.0
Verifies cPanel/WHM and partner licenses by IPv4 via verify.cpanel.net.

Usage:
  cpipcheck.sh [OPTIONS] <IP> [IP2 ...]
  cpipcheck.sh --self [OPTIONS]
  cpipcheck.sh -f <ips.txt> [OPTIONS]

Options:
      --self                Auto-detect and verify this server's public IPv4
  -f, --file <path>         Read IPv4 addresses (one per line, # comments ignored)
  -H, --history             Include expired/historical license records
  -o, --output <fmt>        Output format: table (default), json, csv
  -t, --timeout <sec>       HTTP timeout in seconds (default: 10)
  -q, --quiet               Suppress progress messages
      --no-color            Disable ANSI colors
```

## Practical Examples

**Check a single IPv4:**
```bash
./cpipcheck.sh 208.74.123.68
```

**Include expired/historical licenses:**
```bash
./cpipcheck.sh --history 208.74.123.68
```

**Verify the current server's public IP and export JSON:**
```bash
./cpipcheck.sh --self -o json
```

**Audit a fleet of IPs from a file and export CSV:**
```bash
./cpipcheck.sh -f servers.txt -o csv > licenses.csv
```

## Real Output Example

```text
================================================================================================================
 CPANEL IP LICENSE CHECK (cpipcheck) v2.0.0 | 2026-11-20 03:04:04 UTC
================================================================================================================
IP ADDRESS       | PRODUCT        | PACKAGE                    | PARTNER NOC        | STATUS             | PTR HOSTNAME
----------------------------------------------------------------------------------------------------------------
208.74.123.68    | LiteSpeed      | LITESPEED-UNLIMITED        | cPanel, L.L.C.     | active             | N/A
208.74.123.68    | cPanel/WHM     | CPANEL-SERVERS-INTERNAL    | cPanel, L.L.C.     | expired on 2026-08 | N/A
================================================================================================================
 Summary: 1 IP(s) checked | Active: 1 | Inactive/Unlicensed: 0
================================================================================================================
```

## Detailed Tutorial

Read the full walkthrough: [**Check cPanel License in CLI**](https://perciocastelo.com.br/blog/check-license-cpanel-in-cli.html)

## License

This project is licensed under the [Apache License 2.0](LICENSE).

---
Author: **Percio Castelo**  
Contact: [contato@perciocastelo.com.br](mailto:contato@perciocastelo.com.br)  
Website: [https://perciocastelo.com.br](https://perciocastelo.com.br)
