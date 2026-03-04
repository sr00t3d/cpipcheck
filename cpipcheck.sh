#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   CheckServer v1.0.0                                                      ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Author:   Percio Castelo                                                ║
# ║   Contact:  percio@evolya.com.br | contato@perciocastelo.com.br           ║
# ║   Web:      https://perciocastelo.com.br                                  ║
# ║                                                                           ║
# ║   Function: Check cPanel License                                          ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

IP=$1

# Validate IP
if [[ -z "$IP" ]]; then
    echo "Usage: $0 <IP_ADDRESS>"
    echo "Example: $0 51.79.52.232"
    exit 1
fi

if [[ ! "$IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Error: Invalid IP address format"
    exit 1
fi

# Make the request
CHECK=$(curl -s "https://verify.cpanel.net/app/verify?ip=$IP" -H "User-Agent: Mozilla/5.0")

# Check if anything was returned
if [[ -z "$CHECK" ]]; then
    echo "Error: No response from cPanel license server"
    exit 1
fi

# Check if license exists
if [[ ! "$CHECK" =~ "history table" ]]; then
    echo "No license found for IP $IP"
    exit 1
fi

# Extract the table row using awk
TABLE_ROW=$(echo "$CHECK" | awk '/<tr class="status[0-9]+"/,/<\/tr>/' | tr '\n' ' ')

# Extract all <td> from the table row into an array
FIELDS=$(echo "$TABLE_ROW" | sed 's/<\/td>/\n/g' | sed 's/<[^>]*>//g')

# Convert to array
IFS=$'\n' read -r -d '' -a FIELD_ARRAY <<< "$FIELDS"

# Map table fields
IP_FOUND=$(echo "${FIELD_ARRAY[1]}" | tr -d '[:space:]')
PACKAGE=$(echo "${FIELD_ARRAY[2]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

# Partner NOC - get last non-empty line
PARTNER_RAW="${FIELD_ARRAY[3]}"
PARTNER=$(echo "$PARTNER_RAW" | grep -v '^[[:space:]]*$' | tail -1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

# Activity
ACTIVITY_LINE="${FIELD_ARRAY[4]}"
ACTIVITY_FULL=$(echo "$ACTIVITY_LINE" | tr '\n' ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

PRODUCT=$(echo "${FIELD_ARRAY[5]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

# Status
STATUS_RAW="${FIELD_ARRAY[6]}"
STATUS=$(echo "$STATUS_RAW" | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

UPDATES=$(echo "${FIELD_ARRAY[7]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

# Fallbacks
[[ -z "$PACKAGE" ]] && PACKAGE=$(echo "$TABLE_ROW" | grep -o 'cPanel[^<]*' | grep -v 'cPanel/WHM' | head -1)
[[ -z "$PRODUCT" ]] && PRODUCT="cPanel/WHM"
[[ -z "$STATUS" ]] && STATUS=$(echo "$TABLE_ROW" | grep -o 'active' | head -1)
[[ -z "$UPDATES" ]] && UPDATES="N/A"

# Get reverse hostname
HOSTNAME=$(host "$IP" 2>/dev/null | awk -F "pointer" '{print $2}' | sed 's/[[:space:]]//g; s/\.$//')
[[ -z "$HOSTNAME" ]] && HOSTNAME="N/A"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Define color based on status
if [[ "$STATUS" == *"active"* ]]; then
    COLOR="$GREEN"
    STATUS_EMOJI="✓"
else
    COLOR="$RED"
    STATUS_EMOJI="✗"
fi

# Output
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}              cPanel License Verification${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${YELLOW}IP Address:${NC}        ${CYAN}$IP${NC}"
echo -e "  ${YELLOW}Hostname:${NC}          ${CYAN}$HOSTNAME${NC}"
echo ""
echo -e "${BLUE}───────────────────────────────────────────────────────────────${