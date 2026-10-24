#!/bin/bash
URL="https://rewards.bing.com/redeem/sku/000885000034"
mkdir -p state
html=$(curl -sL -A "Mozilla/5.0" -H "Accept-Language: en-IN,en;q=0.9" -H "Cookie: $BING_COOKIE" "$URL")

if ! grep -q "Flipkart Gift Card" <<<"$html"; then
  state=unknown
elif grep -qi "restocking" <<<"$html"; then
  state=restocking
else
  state=available
fi
echo "state=$state"

prev=$(cat state/hash 2>/dev/null)

if [ "$state" = available ] && [ "$prev" != available ]; then
  curl -s -H "Priority: urgent" -d "Flipkart 1000 card is BACK" "https://ntfy.sh/$NTFY_TOPIC" || true
elif [ "$state" = unknown ] && [ "$prev" != unknown ]; then
  curl -s -d "Check failed: cookie expired or page changed" "https://ntfy.sh/$NTFY_TOPIC" || true
fi

echo "$state" > state/hash
