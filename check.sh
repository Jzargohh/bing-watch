#!/bin/bash
URL="https://rewards.bing.com/redeem/sku/000885000034"
mkdir -p state

resp=$(curl -sL -A "Mozilla/5.0" -H "Accept-Language: en-IN,en;q=0.9" -H "Cookie: $BING_COOKIE" -w $'\n%{http_code}' "$URL")
code=${resp##*$'\n'}
html=${resp%$'\n'*}
size=${#html}

if ! grep -q "Flipkart Gift Card" <<<"$html"; then
  state=unknown
elif grep -qi "restocking" <<<"$html"; then
  state=restocking
else
  state=available
fi

prev=$(cat state/hash 2>/dev/null)
msg="state=$state prev=${prev:-none} http=$code size=$size cookie_len=${#BING_COOKIE}"
echo "$msg"

# TEST MODE: notify on every run. Remove this block after testing.
if [ -z "$NTFY_TOPIC" ]; then
  echo "ERROR: NTFY_TOPIC is empty"
else
  pri=default
  [ "$state" = available ] && pri=urgent
  [ "$state" = unknown ] && pri=high
  out=$(curl -sS -w ' [ntfy http=%{http_code}]' -H "Priority: $pri" -H "Title: bing-watch $state" -d "$msg" "https://ntfy.sh/$NTFY_TOPIC" 2>&1)
  echo "ntfy: $out"
fi

echo "$state" > state/hash
