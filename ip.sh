#!/bin/sh

# ------------------------
# IP Tracker Terminal GUI
# ------------------------

DB_FILE="$HOME/.ip_history.log"

# Force Central Time (CST/CDT)
export TZ=America/Chicago
NOW_DATE=$(date "+%m/%d/%Y")
NOW_TIME=$(date "+%I:%M %p %Z")  # Adds CST/CDT label automatically

# Ensure DB exists
touch "$DB_FILE"

# Fetch JSON (no cache)
JSON=$(curl -s -H "Cache-Control: no-cache, no-store, must-revalidate" \
                -H "Pragma: no-cache" \
                -H "Expires: 0" \
                https://ipinfo.io/json)

# Parse JSON
IP=$(echo "$JSON" | sed -n 's/.*"ip"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
CITY=$(echo "$JSON" | sed -n 's/.*"city"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
REGION=$(echo "$JSON" | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

LAST_ENTRY=$(tail -n 1 "$DB_FILE" 2>/dev/null)
LAST_IP=$(echo "$LAST_ENTRY" | awk '{print $1}')

if grep -q "^$IP " "$DB_FILE"; then
  SEEN_BEFORE="yes"
else
  SEEN_BEFORE="no"
fi

# ------------------------
# Header
# ------------------------
clear
printf "==============================\n"
printf "       IP Tracker GUI         \n"
printf "==============================\n\n"

# ------------------------
# Current IP Info
# ------------------------
printf "Current Time : %s\n" "$NOW_DATE $NOW_TIME"
printf "IP Address   : %s\n" "$IP"
printf "Location     : %s, %s\n" "$CITY" "$REGION"
printf "------------------------------\n"

# ------------------------
# Status Message
# ------------------------
if [ "$SEEN_BEFORE" = "no" ]; then
  STATUS="IP not found in database, it’s clean!"
  echo "$IP $NOW_DATE $NOW_TIME" >> "$DB_FILE"
elif [ "$IP" = "$LAST_IP" ]; then
  STATUS="IP unchanged, nothing new to report."
else
  LAST_SEEN=$(grep "^$IP " "$DB_FILE" | tail -n 1 | cut -d' ' -f2-)
  STATUS="This IP was previously seen last on $LAST_SEEN"
  echo "$IP $NOW_DATE $NOW_TIME" >> "$DB_FILE"
fi

printf "Status       : %s\n" "$STATUS"
printf "==============================\n\n"

# ------------------------
# Address History
# ------------------------
printf "Address History:\n"
nl -w2 -s'. ' "$DB_FILE"
printf "\n"
printf "==============================\n"
