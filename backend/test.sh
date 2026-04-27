#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE:-http://localhost:8080}"
SUFFIX="$(date +%s)"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }; }
need curl
need jq

echo "BASE=$BASE"
echo "SUFFIX=$SUFFIX"

post_json() {
  local url="$1"
  local body="$2"
  curl -f -sS -X POST "$url" -H "Content-Type: application/json" -d "$body"
}

# 1) Users: Alice, Bob, Charlie
ALICE_JSON=$(post_json "$BASE/api/v1/auth/register" "{\"username\":\"alice_$SUFFIX\",\"password\":\"StrongPass123\"}")
BOB_JSON=$(post_json "$BASE/api/v1/auth/register" "{\"username\":\"bob_$SUFFIX\",\"password\":\"StrongPass123\"}")
CHARLIE_JSON=$(post_json "$BASE/api/v1/auth/register" "{\"username\":\"charlie_$SUFFIX\",\"password\":\"StrongPass123\"}")

ALICE_ID=$(echo "$ALICE_JSON" | jq -r '.userId')
BOB_ID=$(echo "$BOB_JSON" | jq -r '.userId')
CHARLIE_ID=$(echo "$CHARLIE_JSON" | jq -r '.userId')

ALICE_NAME=$(echo "$ALICE_JSON" | jq -r '.username')
BOB_NAME=$(echo "$BOB_JSON" | jq -r '.username')

echo "Alice:   $ALICE_ID ($ALICE_NAME)"
echo "Bob:     $BOB_ID ($BOB_NAME)"
echo "Charlie: $CHARLIE_ID"

# 2) Room + Bob joins
ROOM_JSON=$(post_json "$BASE/api/v1/rooms" "{\"userId\":$ALICE_ID,\"name\":\"Test room $SUFFIX\"}")
ROOM_ID=$(echo "$ROOM_JSON" | jq -r '.id')
INVITE_CODE=$(echo "$ROOM_JSON" | jq -r '.inviteCode')

echo "Room: $ROOM_ID invite=$INVITE_CODE"

post_json "$BASE/api/v1/rooms/join" "{\"userId\":$BOB_ID,\"inviteCode\":\"$INVITE_CODE\"}" >/dev/null
echo "Bob joined room"

# 3) Alice/Bob send 2 messages
MSG1="Hello from Alice $SUFFIX"
MSG2="Hello from Bob $SUFFIX"

post_json "$BASE/api/v1/messages" "{\"roomId\":$ROOM_ID,\"userId\":$ALICE_ID,\"username\":\"$ALICE_NAME\",\"content\":\"$MSG1\"}" >/dev/null
post_json "$BASE/api/v1/messages" "{\"roomId\":$ROOM_ID,\"userId\":$BOB_ID,\"username\":\"$BOB_NAME\",\"content\":\"$MSG2\"}" >/dev/null
echo "Sent 2 messages"

# 4) Wait until history has at least 2 messages
MESSAGES_JSON="[]"
COUNT=0
for _ in {1..25}; do
  MESSAGES_JSON=$(curl -f -sS "$BASE/api/v1/rooms/$ROOM_ID/messages")
  COUNT=$(echo "$MESSAGES_JSON" | jq 'length')
  [[ "$COUNT" -ge 2 ]] && break
  sleep 1
done

echo "Room history before Charlie:"
echo "$MESSAGES_JSON" | jq

if [[ "$COUNT" -lt 2 ]]; then
  echo "FAIL: expected at least 2 messages before Charlie, got $COUNT"
  exit 1
fi

# 5) Charlie joins AFTER 2 messages
post_json "$BASE/api/v1/rooms/join" "{\"userId\":$CHARLIE_ID,\"inviteCode\":\"$INVITE_CODE\"}" >/dev/null
echo "Charlie joined room"

# 6) Charlie requests history
CHARLIE_HISTORY=$(curl -f -sS "$BASE/api/v1/rooms/$ROOM_ID/messages")
CHARLIE_COUNT=$(echo "$CHARLIE_HISTORY" | jq 'length')

echo "Charlie history:"
echo "$CHARLIE_HISTORY" | jq

if [[ "$CHARLIE_COUNT" -lt 2 ]]; then
  echo "FAIL: Charlie expected at least 2 messages, got $CHARLIE_COUNT"
  exit 1
fi

HAS_MSG1=$(echo "$CHARLIE_HISTORY" | jq --arg m "$MSG1" '[.[] | select(.content == $m)] | length')
HAS_MSG2=$(echo "$CHARLIE_HISTORY" | jq --arg m "$MSG2" '[.[] | select(.content == $m)] | length')

if [[ "$HAS_MSG1" -lt 1 || "$HAS_MSG2" -lt 1 ]]; then
  echo "FAIL: Charlie history does not contain both original messages"
  exit 1
fi

echo "OK: Charlie joined later and still sees room history."
