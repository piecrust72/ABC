#!/bin/sh

DB_FILE="$HOME/.ip_history.log"

# Force Central Time (CST/CDT)
TZ=America/Chicago
NOW_DATE=$(TZ=$TZ date "+%m/%d/%Y")
NOW_TIME=$(TZ=$TZ date "+%I:%M %p")

# Ensure DB exists FIRST
touch "$DB_FILE"

# Fetch JSON (no cache)
JSON=$(curl -s \
  -H "Cache-Control: no-cache, no-store, must-revalidate" \
  -H "Pragma: no-cache" \
  -H "Expires: 0" \
  https://ipinfo.io/json)

# Parse JSON safely (BusyBox compatible)
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

echo
echo "IP Address : $IP"
echo "Location   : $CITY, $REGION"
echo

if [ "$SEEN_BEFORE" = "no" ]; then
  STATUS="IP not found in database, it’s clean!"
  echo "$IP $NOW_DATE $NOW_TIME" >> "$DB_FILE"

elif [ "$IP" = "$LAST_IP" ]; then
  STATUS="IP unchanged, nothing new to report or add to database."

else
  LAST_SEEN=$(grep "^$IP " "$DB_FILE" | tail -n 1 | cut -d' ' -f2-)
  STATUS="This IP was previously seen last on $LAST_SEEN"
  echo "$IP $NOW_DATE $NOW_TIME" >> "$DB_FILE"
fi

echo "$STATUS"
echo
echo "Address History:"
nl -w2 -s'. ' "$DB_FILE"
