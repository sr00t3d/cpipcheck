# cPanel IP License Check

Readme: [BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/cpipcheck) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" src="cpipcheck-cover-webp" />

A modern Bash utility to check cPanel/WHM license information, updated for the current verify.cpanel.net API structure.

## About

This project is an **updated version** of the original license checker by **Percio Andrade**. The original script used an older API endpoint (`http://verify.cpanel.net/index.cgi`) that has been deprecated.

### Why an Update?

- **New API endpoint** - Updated from `index.cgi` to `app/verify`
- **HTTPS support** - Secure connections (original used HTTP)
- **New HTML structure** - Parse modern verify.cpanel.net layout
- **Better error handling** - Validates responses and handles edge cases
- **No grep lookbehind** - Compatible with standard Unix tools

## Features

| Feature | Description | Original | This Version |
|---------|-------------|----------|--------------|
| License verification | Query cPanel license server | ✅ | ✅ |
| HTTPS support | Secure API calls | ❌ | ✅ |
| Modern API | Current verify.cpanel.net structure | ❌ | ✅ |
| Hostname resolution | Reverse DNS lookup | ✅ | ✅ |
| Color output | Terminal colors for readability | ❌ | ✅ |
| IP validation | Validate input format | ❌ | ✅ |
| Error handling | Graceful failure handling | ❌ | ✅ |
| Exit codes | Return 0 for active, 1 for inactive | ❌ | ✅ |

## Requirements

- **Bash** 4.0+
- **curl** - for HTTPS requests
- **host** - for DNS resolution (bind-utils package)
- Standard Unix tools: `grep`, `sed`, `awk`, `tr`

## Installation

```bash
# Clone or download
curl -O https://raw.githubusercontent.com/sr00t3d/cpipcheck/refs/heads/main/cpipcheck.sh

# Make executable
chmod +x cpipcheck.sh

# Optional: move to PATH
sudo mv cpipcheck.sh /usr/local/bin/cpcheck
```

## Usage

```bash
cpipcheck.sh <IP_ADDRESS>
```

### Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `IP_ADDRESS` | Server IP to check | Yes |

## Examples

### 1. Check Active License

```bash
./cpipcheck.sh 127.0.0.1
```

**Output:**
```bash
═══════════════════════════════════════════════════════════════
              cPanel License Verification
═══════════════════════════════════════════════════════════════

  IP Address:        127.0.0.1
  Hostname:          server.tld

───────────────────────────────────────────────────────────────
  License Details:
───────────────────────────────────────────────────────────────
  Package:           cPanel Autoscale Cloud (Internal)
  Product:           cPanel/WHM
  Partner NOC:       Company, LTDA.
  Status:            ✓ active
  Activity:          active on 2025-07-01 12:02:09
  Updates Expire:    N/A
───────────────────────────────────────────────────────────────
```

### 2. Check Without Arguments

```bash
./cpipcheck.sh
```

**Output:**
```bash
Usage: ./cpipcheck.sh <IP_ADDRESS>
Example: ./cpipcheck.sh 127.0.0.1
```

### 3. Invalid IP Format

```bash
./cpipcheck.sh invalid-ip
```

**Output:**
```bash
Error: Invalid IP address format
```

### 4. No License Found

```bash
./cpipcheck.sh 192.168.1.1
```

**Output:**
```bash
No license found for IP 192.168.1.1
```

## Output Format

### Color Coding

| Color | Meaning |
|-------|---------|
| 🟢 Green | Active status |
| 🔴 Red | Inactive/expired status |
| 🟡 Yellow | Labels and headers |
| 🔵 Blue | Borders and separators |
| Cyan | IP and hostname values |

### Status Indicators

| Symbol | Status |
|--------|--------|
| `✓` | Active license |
| `✗` | Inactive/expired license |

### Fields Explained

| Field | Description | Example |
|-------|-------------|---------|
| **IP Address** | The IP checked | `127.0.0.1` |
| **Hostname** | Reverse DNS lookup | `server.tld` |
| **Package** | License type | `cPanel Autoscale Cloud (Internal)` |
| **Product** | cPanel product | `cPanel/WHM` |
| **Partner NOC** | License provider | `Company, LTDA.` |
| **Status** | Current status | `active` or `expired` |
| **Activity** | Activation date | `active on 2025-07-01 12:02:09` |
| **Updates Expire** | Update expiration | `N/A` or date |

## Exit Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| `0` | License is **active** | Success in scripts |
| `1` | License **inactive/expired** or **error** | Alert in monitoring |

### Use in Scripts

```bash
# Check license and alert if not active
if ! ./cpipcheck.sh 127.0.0.1 > /dev/null 2>&1; then
    echo "ALERT: cPanel license not active!" | mail -s "License Alert" admin@example.com
fi
```

```bash
# One-liner status check
./cpipcheck.sh 127.0.0.1 > /dev/null && echo "License OK" || echo "License PROBLEM"
```

## Comparison with Original

| Aspect | Original (v1.0) | This Version (v2.3) |
|--------|-----------------|---------------------|
| API Endpoint | `http://verify.cpanel.net/index.cgi` | `https://verify.cpanel.net/app/verify` |
| Protocol | HTTP (insecure) | HTTPS (secure) |
| HTML Parser | Simple grep/cut | Awk + array mapping |
| IP validation | None | Regex validation |
| Error handling | Basic | Comprehensive |
| Color output | None | Full color support |
| Exit codes | None | 0=active, 1=inactive |
| Hostname lookup | Yes | Yes |
| Modern structure | No | Yes |

## Troubleshooting

### "command not found: host"
```bash
# Install bind-utils
yum install bind-utils      # CentOS/RHEL
apt-get install dnsutils    # Ubuntu/Debian
```

### "No license found for IP"
- The IP has no cPanel license associated
- Verify the IP address is correct
- Check if license is registered at [verify.cpanel.net](https://verify.cpanel.net)

### "Error: No response from cPanel license server"
- Network connectivity issue
- verify.cpanel.net may be down
- Check firewall/proxy settings

### Empty fields in output
The HTML structure may have changed. Debug with:
```bash
curl -s "https://verify.cpanel.net/app/verify?ip=YOUR_IP" > /tmp/debug.html
grep -A 20 'class="history table"' /tmp/debug.html
```

## API Information

### Current Endpoint
```
https://verify.cpanel.net/app/verify?ip=<IP_ADDRESS>
```

### Response Format
HTML table with license history:
```html
<table class="history table">
    <tr class="status1">
        <td align="center">1</td>
        <td align="center">IP_ADDRESS</td>
        <td align="center">PACKAGE</td>
        <td align="left">PARTNER_NOC</td>
        <td align="center">ACTIVITY</td>
        <td align="center">PRODUCT</td>
        <td><b>STATUS</b></td>
        <td>UPDATES_EXPIRATION</td>
    </tr>
</table>
```

## Credits

- **Original Author**: Percio Andrade
- **Original Version**: 1.0
- **Updated Version**: 2.3 (2026)
- **Purpose**: cPanel license verification tool


## Legal Notice

> [!WARNING]
> This software is provided "as is." Always ensure you have explicit permission before executing it. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Change IP Account on cPanel**](https://perciocastelo.com.br/blog/check-license-cpanel-in-cli.html)

## License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.

---

**Note**: This script is for administrative purposes only. Respect cPanel's terms of service and rate limits when using their verification API.
```