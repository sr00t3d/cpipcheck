#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   cPanel IP License Check (cpipcheck) v2.0.0                              ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Autor:   Percio Castelo                                                 ║
# ║   Contato: percio@evolya.com.br | contato@perciocastelo.com.br            ║
# ║   Web:     https://perciocastelo.com.br                                   ║
# ║                                                                           ║
# ║   Função:  Verifies cPanel/WHM, LiteSpeed, CloudLinux and partner         ║
# ║            licenses by IPv4 via https://verify.cpanel.net/app/verify      ║
# ║            with batch mode, reverse DNS, history, and table/JSON/CSV out. ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -uo pipefail
export LC_ALL=C

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERIFY_BASE_URL="https://verify.cpanel.net/app/verify"

# =============================================================================
# Defaults
# =============================================================================
IPS=()
BATCH_FILE=""
CHECK_SELF=false
SHOW_HISTORY=false
OUTPUT_FORMAT="table"    # table | json | csv
TIMEOUT=10
NO_COLOR=false
QUIET=false

TMP_DIR=""
cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

# =============================================================================
# Colors
# =============================================================================
C_RESET=""
C_BOLD=""
C_RED=""
C_GREEN=""
C_YELLOW=""
C_CYAN=""
C_DIM=""

init_colors() {
    if [[ "$NO_COLOR" == false && "$OUTPUT_FORMAT" == "table" && -t 1 ]]; then
        C_RESET=$'\033[0m'
        C_BOLD=$'\033[1m'
        C_DIM=$'\033[2m'
        C_RED=$'\033[0;31m'
        C_GREEN=$'\033[0;32m'
        C_YELLOW=$'\033[0;33m'
        C_CYAN=$'\033[0;36m'
    fi
}

log_info() { [[ "$QUIET" == false && "$OUTPUT_FORMAT" == "table" ]] && echo -e "${C_CYAN}[→]${C_RESET} $*" >&2; }
log_err()  { echo -e "${C_RED}[✗] Error:${C_RESET} $*" >&2; }

# =============================================================================
# Help
# =============================================================================
show_help() {
    cat <<EOF
cPanel IP License Check (cpipcheck) v${VERSION}
Verifies cPanel/WHM and partner licenses by IPv4 via verify.cpanel.net.

Usage:
  ${SCRIPT_NAME} [OPTIONS] <IP> [IP2 ...]
  ${SCRIPT_NAME} --self [OPTIONS]
  ${SCRIPT_NAME} -f <ips.txt> [OPTIONS]

Options:
      --self                Auto-detect and verify this server's public IPv4
  -f, --file <path>         Read IPv4 addresses (one per line, # comments ignored)
  -H, --history             Include expired/historical license records
  -o, --output <fmt>        Output format: table (default), json, csv
  -t, --timeout <sec>       HTTP timeout in seconds (default: 10)
  -q, --quiet               Suppress progress messages
      --no-color            Disable ANSI colors
  -V, --version             Show version and exit
  -h, --help                Show this help message and exit

Exit Codes:
  0  All checked IPs have at least one active license
  1  Usage, network, or runtime error
  2  One or more IPs have no active license (expired or unlicensed)

Examples:
  ${SCRIPT_NAME} 208.74.123.68
  ${SCRIPT_NAME} --history 208.74.123.68
  ${SCRIPT_NAME} --self -o json
  ${SCRIPT_NAME} -f servers.txt -o csv > licenses.csv
EOF
}

# =============================================================================
# Validation & Helpers
# =============================================================================
validate_ip() {
    local ip="$1"
    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 1
    fi
    local o
    IFS='.' read -r -a octets <<< "$ip"
    for o in "${octets[@]}"; do
        (( 10#$o <= 255 )) || return 1
    done
    return 0
}

detect_public_ip() {
    local ip=""
    for url in "https://api.ipify.org" "https://ifconfig.me/ip" "https://icanhazip.com"; do
        ip=$(curl -fsS -m 5 "$url" 2>/dev/null | tr -d '[:space:]' || true)
        if validate_ip "$ip"; then
            echo "$ip"
            return 0
        fi
    done
    return 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --self)       CHECK_SELF=true; shift ;;
            -f|--file)    [[ $# -lt 2 ]] && { log_err "$1 requires a file path"; exit 1; }; BATCH_FILE="$2"; shift 2 ;;
            -H|--history) SHOW_HISTORY=true; shift ;;
            -o|--output)  [[ $# -lt 2 ]] && { log_err "$1 requires a format"; exit 1; }; OUTPUT_FORMAT="$2"; shift 2 ;;
            -t|--timeout) [[ $# -lt 2 ]] && { log_err "$1 requires seconds"; exit 1; }; TIMEOUT="$2"; shift 2 ;;
            -q|--quiet)   QUIET=true; shift ;;
            --no-color)   NO_COLOR=true; shift ;;
            -V|--version) echo "cpipcheck v${VERSION}"; exit 0 ;;
            -h|--help)    show_help; exit 0 ;;
            -*)           log_err "Unknown option: $1 (use --help)"; exit 1 ;;
            *)            IPS+=("$1"); shift ;;
        esac
    done

    case "$OUTPUT_FORMAT" in
        table|json|csv) ;;
        *) log_err "--output must be table, json, or csv (got: $OUTPUT_FORMAT)"; exit 1 ;;
    esac

    if [[ -n "$BATCH_FILE" ]]; then
        [[ -r "$BATCH_FILE" ]] || { log_err "Cannot read batch file: ${BATCH_FILE}"; exit 1; }
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | sed 's/#.*//' | tr -d '[:space:]')
            [[ -n "$line" ]] && IPS+=("$line")
        done < "$BATCH_FILE"
    fi

    if [[ "$CHECK_SELF" == true ]]; then
        local pub_ip
        pub_ip=$(detect_public_ip) || { log_err "Could not auto-detect public IPv4."; exit 1; }
        IPS+=("$pub_ip")
    fi

    if [[ ${#IPS[@]} -eq 0 ]]; then
        show_help
        exit 1
    fi

    local ip
    for ip in "${IPS[@]}"; do
        if ! validate_ip "$ip"; then
            log_err "Invalid IPv4 address: '${ip}'"
            exit 1
        fi
    done
}

# =============================================================================
# Core Verifier (Python3 stdlib HTMLParser + reverse DNS + table/JSON/CSV)
# =============================================================================
run_checks() {
    if ! command -v python3 >/dev/null 2>&1; then
        log_err "python3 is required to parse verify.cpanel.net HTML cleanly."
        exit 1
    fi

    python3 - "$VERSION" "$VERIFY_BASE_URL" "$TIMEOUT" "$SHOW_HISTORY" "$OUTPUT_FORMAT" \
        "$C_RESET" "$C_GREEN" "$C_RED" "$C_YELLOW" "$C_CYAN" "$C_DIM" "${IPS[@]}" <<'PYEOF'
import csv
import datetime
import html
from html.parser import HTMLParser
import io
import json
import re
import socket
import sys
import urllib.error
import urllib.parse
import urllib.request

(version, base_url, timeout_s, show_history_s, fmt,
 c_rst, c_grn, c_red, c_yel, c_cyn, c_dim) = sys.argv[1:12]
ips = sys.argv[12:]
timeout = int(timeout_s)
show_history = show_history_s == "true"

class HistoryTableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_history = False
        self.in_tr = False
        self.in_td = False
        self.current_row = []
        self.current_cell = []
        self.row_class = ""
        self.rows = []

    def handle_starttag(self, tag, attrs):
        ad = dict(attrs)
        cls = ad.get("class", "")
        if tag == "table" and "history" in cls:
            self.in_history = True
        elif self.in_history and tag == "tr":
            self.in_tr = True
            self.row_class = cls
            self.current_row = []
        elif self.in_tr and tag == "td":
            self.in_td = True
            self.current_cell = []
        elif self.in_td and tag == "br":
            self.current_cell.append(" ")

    def handle_endtag(self, tag):
        if tag == "table" and self.in_history:
            self.in_history = False
        elif tag == "tr" and self.in_tr:
            self.in_tr = False
            if len(self.current_row) >= 7:
                self.rows.append((self.row_class, self.current_row))
        elif tag == "td" and self.in_td:
            self.in_td = False
            txt = re.sub(r"\s+", " ", html.unescape("".join(self.current_cell))).strip()
            self.current_row.append(txt)

    def handle_data(self, data):
        if self.in_td:
            self.current_cell.append(data)

def reverse_dns(ip: str) -> str:
    try:
        return socket.gethostbyaddr(ip)[0]
    except Exception:
        return "N/A"

def check_ip(ip: str):
    url = f"{base_url}?ip={urllib.parse.quote(ip)}"
    req = urllib.request.Request(url, headers={"User-Agent": f"Mozilla/5.0 cpipcheck/{version}"})
    ptr = reverse_dns(ip)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", errors="replace")
    except Exception as e:
        return {"ip": ip, "hostname": ptr, "has_active": False, "error": str(e), "licenses": []}

    parser = HistoryTableParser()
    parser.feed(body)

    licenses = []
    for rcls, cols in parser.rows:
        # Columns: #, IP, Package, Partner NOC, Activity, Product, Status, Updates Expiration
        pkg = cols[2] if len(cols) > 2 else "N/A"
        partner = cols[3] if len(cols) > 3 else "N/A"
        activity = cols[4] if len(cols) > 4 else "N/A"
        product = cols[5] if len(cols) > 5 else "N/A"
        status_txt = cols[6] if len(cols) > 6 else "unknown"
        updates = cols[7] if len(cols) > 7 else "N/A"
        is_active = (rcls == "status1") or (status_txt.lower().startswith("active"))
        licenses.append({
            "package": pkg or "N/A",
            "partner": partner or "N/A",
            "activity": activity or "N/A",
            "product": product or "N/A",
            "status": status_txt or "unknown",
            "updates_expiration": updates or "N/A",
            "active": is_active,
        })

    has_active = any(l["active"] for l in licenses)
    return {"ip": ip, "hostname": ptr, "has_active": has_active, "error": None, "licenses": licenses}

results = [check_ip(ip) for ip in ips]
all_active = all(r["has_active"] for r in results)
any_error = any(r["error"] is not None for r in results)

if fmt == "json":
    out = {
        "version": version,
        "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "total_ips": len(results),
        "active_ips": sum(1 for r in results if r["has_active"]),
        "results": results if show_history else [
            {
                **r,
                "licenses": [l for l in r["licenses"] if l["active"]] or r["licenses"][:1]
            }
            for r in results
        ],
    }
    print(json.dumps(out, indent=2))
elif fmt == "csv":
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["ip", "hostname", "product", "package", "partner", "status", "activity", "updates_expiration", "active"])
    for r in results:
        lics = r["licenses"] if show_history else ([l for l in r["licenses"] if l["active"]] or r["licenses"][:1])
        if not lics:
            w.writerow([r["ip"], r["hostname"], "-", "-", "-", r["error"] or "no_license", "-", "-", False])
        else:
            for l in lics:
                w.writerow([r["ip"], r["hostname"], l["product"], l["package"], l["partner"], l["status"], l["activity"], l["updates_expiration"], l["active"]])
    sys.stdout.write(buf.getvalue())
else:
    print("=" * 112)
    print(f" CPANEL IP LICENSE CHECK (cpipcheck) v{version} | {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S')} UTC")
    print("=" * 112)
    print(f"{'IP ADDRESS':<16} | {'PRODUCT':<14} | {'PACKAGE':<26} | {'PARTNER NOC':<18} | {'STATUS':<18} | {'PTR HOSTNAME'}")
    print("-" * 112)
    for r in results:
        lics = r["licenses"] if show_history else ([l for l in r["licenses"] if l["active"]] or r["licenses"][:1])
        if not lics:
            st = r["error"] or "NO LICENSE"
            print(f"{r['ip']:<16} | {'-':<14} | {'-':<26} | {'-':<18} | {c_red}{st[:18]:<18}{c_rst} | {r['hostname']}")
        else:
            for l in lics:
                col = c_grn if l["active"] else c_red
                st = l["status"]
                print(f"{r['ip']:<16} | {l['product'][:14]:<14} | {l['package'][:26]:<26} | {l['partner'][:18]:<18} | {col}{st[:18]:<18}{c_rst} | {r['hostname']}")
    print("=" * 112)
    act_cnt = sum(1 for r in results if r["has_active"])
    print(f" Summary: {len(results)} IP(s) checked | Active: {act_cnt} | Inactive/Unlicensed: {len(results) - act_cnt}")
    print("=" * 112)

if any_error:
    sys.exit(1)
sys.exit(0 if all_active else 2)
PYEOF
}

# =============================================================================
# Main
# =============================================================================
main() {
    parse_args "$@"
    init_colors
    run_checks
}

main "$@"
