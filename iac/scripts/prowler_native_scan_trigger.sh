#!/usr/bin/env bash
# prowler_native_scan_trigger.sh
#
# Triggers a native scan on a self-hosted Prowler upstream instance via its REST API.
# The scan runs asynchronously inside the Prowler Docker stack (Celery worker).
#
# Required env vars:
#   PROWLER_NATIVE_API_URL    Base URL, e.g. https://audio-have-spokesman-pens.trycloudflare.com
#   PROWLER_NATIVE_EMAIL      Admin account email
#   PROWLER_NATIVE_PASSWORD   Admin account password
#
# Optional env vars:
#   PROWLER_NATIVE_PROVIDER_NAME  Provider name to scan (default: prowler-auto)
#   PROWLER_SCAN_WAIT             Set to "true" to poll until the scan finishes (default: false)
#   PROWLER_SCAN_WAIT_TIMEOUT     Max seconds to wait (default: 1800 = 30 min)

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
API_URL="${PROWLER_NATIVE_API_URL:-}"
EMAIL="${PROWLER_NATIVE_EMAIL:-}"
PASSWORD="${PROWLER_NATIVE_PASSWORD:-}"
PROVIDER_NAME="${PROWLER_NATIVE_PROVIDER_NAME:-prowler-auto}"
WAIT_FOR_SCAN="${PROWLER_SCAN_WAIT:-false}"
WAIT_TIMEOUT="${PROWLER_SCAN_WAIT_TIMEOUT:-1800}"

# ── Validation ───────────────────────────────────────────────────────────────
if [[ -z "$API_URL" || -z "$EMAIL" || -z "$PASSWORD" ]]; then
  echo "[prowler-trigger] ERROR: PROWLER_NATIVE_API_URL, PROWLER_NATIVE_EMAIL, and PROWLER_NATIVE_PASSWORD must be set."
  exit 1
fi

# Skip masked/placeholder values to avoid misleading failures.
if [[ "$API_URL" == "***" || "$API_URL" == *"***"* ]]; then
  echo "[prowler-trigger] skip: PROWLER_NATIVE_API_URL is masked or invalid."
  exit 0
fi

# Ensure the API host resolves (avoid curl exit 6).
if ! python3 - <<'PY'
import os, socket, sys
from urllib.parse import urlparse
raw = os.environ.get("PROWLER_NATIVE_API_URL","").strip()
try:
    if not raw:
        sys.exit(1)
    if "://" not in raw:
        raw = "http://" + raw.lstrip("/")
    host = urlparse(raw).hostname
    if not host:
        sys.exit(1)
    socket.gethostbyname(host)
    sys.exit(0)
except Exception:
    sys.exit(1)
PY
then
  echo "[prowler-trigger] skip: PROWLER_NATIVE_API_URL host not resolvable from runner."
  exit 0
fi

# Strip trailing slash
API_URL="${API_URL%/}"

echo "[prowler-trigger] Target API: $API_URL"
echo "[prowler-trigger] Provider:   $PROVIDER_NAME"

# ── Step 1: Authenticate ─────────────────────────────────────────────────────
echo "[prowler-trigger] Authenticating..."
AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/v1/tokens" \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  -d "{
    \"data\": {
      \"type\": \"tokens\",
      \"attributes\": {
        \"email\": \"${EMAIL}\",
        \"password\": \"${PASSWORD}\"
      }
    }
  }")

HTTP_CODE=$(tail -n1 <<< "$AUTH_RESPONSE")
BODY=$(head -n -1 <<< "$AUTH_RESPONSE")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "[prowler-trigger] ERROR: Authentication failed (HTTP $HTTP_CODE)"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

ACCESS_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['attributes']['access'])")
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "[prowler-trigger] ERROR: Could not extract access token from auth response."
  exit 1
fi
echo "[prowler-trigger] Authenticated successfully."

AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"

# ── Step 2: Find provider by name ────────────────────────────────────────────
echo "[prowler-trigger] Looking up provider '$PROVIDER_NAME'..."
PROVIDERS_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}/api/v1/providers" \
  -H "Accept: application/vnd.api+json" \
  -H "$AUTH_HEADER")

HTTP_CODE=$(tail -n1 <<< "$PROVIDERS_RESPONSE")
BODY=$(head -n -1 <<< "$PROVIDERS_RESPONSE")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "[prowler-trigger] ERROR: Failed to list providers (HTTP $HTTP_CODE)"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

PROVIDER_ID=$(echo "$BODY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
providers = data.get('data', [])
target = '${PROVIDER_NAME}'
for p in providers:
    attrs = p.get('attributes', {})
    if attrs.get('alias') == target or attrs.get('uid') == target or p.get('id') == target:
        print(p['id'])
        break
")

if [[ -z "$PROVIDER_ID" ]]; then
  echo "[prowler-trigger] ERROR: Provider '$PROVIDER_NAME' not found."
  echo "Available providers:"
  echo "$BODY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('data', []):
    a = p.get('attributes', {})
    print(f\"  id={p['id']}  alias={a.get('alias','')}  uid={a.get('uid','')}  connected={a.get('connection',{}).get('connected')}\")
"
  exit 1
fi

echo "[prowler-trigger] Found provider: $PROVIDER_ID"

# ── Step 3: Verify provider is connected ─────────────────────────────────────
CONNECTED=$(echo "$BODY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('data', []):
    if p['id'] == '${PROVIDER_ID}':
        print(p.get('attributes',{}).get('connection',{}).get('connected','false'))
        break
")

if [[ "$CONNECTED" != "True" && "$CONNECTED" != "true" ]]; then
  echo "[prowler-trigger] WARNING: Provider '$PROVIDER_NAME' connected=$CONNECTED — scan may fail."
fi

# ── Step 4: Trigger a scan ───────────────────────────────────────────────────
echo "[prowler-trigger] Triggering scan on provider $PROVIDER_ID..."
SCAN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/v1/scans" \
  -H "Content-Type: application/vnd.api+json" \
  -H "Accept: application/vnd.api+json" \
  -H "$AUTH_HEADER" \
  -d "{
    \"data\": {
      \"type\": \"scans\",
      \"attributes\": {
        \"trigger\": \"manual\"
      },
      \"relationships\": {
        \"provider\": {
          \"data\": {
            \"type\": \"providers\",
            \"id\": \"${PROVIDER_ID}\"
          }
        }
      }
    }
  }")

HTTP_CODE=$(tail -n1 <<< "$SCAN_RESPONSE")
BODY=$(head -n -1 <<< "$SCAN_RESPONSE")

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "[prowler-trigger] ERROR: Scan creation failed (HTTP $HTTP_CODE)"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

SCAN_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")
SCAN_STATE=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['attributes'].get('state','unknown'))")
echo "[prowler-trigger] Scan created: id=$SCAN_ID  initial_state=$SCAN_STATE"

if [[ "$SCAN_STATE" == "failed" ]]; then
  echo "[prowler-trigger] ERROR: Scan immediately transitioned to 'failed'."
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  exit 1
fi

# Export scan ID for downstream steps
echo "PROWLER_NATIVE_SCAN_ID=${SCAN_ID}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true

# ── Step 5 (optional): Poll until done ───────────────────────────────────────
if [[ "$WAIT_FOR_SCAN" != "true" ]]; then
  echo "[prowler-trigger] Scan submitted. Not waiting for completion (PROWLER_SCAN_WAIT=false)."
  exit 0
fi

echo "[prowler-trigger] Polling scan $SCAN_ID (timeout: ${WAIT_TIMEOUT}s)..."
ELAPSED=0
POLL_INTERVAL=30

while [[ $ELAPSED -lt $WAIT_TIMEOUT ]]; do
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  STATUS_RESP=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}/api/v1/scans/${SCAN_ID}" \
    -H "Accept: application/vnd.api+json" \
    -H "$AUTH_HEADER")
  SC=$(tail -n1 <<< "$STATUS_RESP")
  SB=$(head -n -1 <<< "$STATUS_RESP")

  if [[ "$SC" != "200" ]]; then
    echo "[prowler-trigger] WARNING: Poll returned HTTP $SC — retrying..."
    continue
  fi

  STATE=$(echo "$SB" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['attributes'].get('state','unknown'))")
  PROGRESS=$(echo "$SB" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['attributes'].get('progress',0))" 2>/dev/null || echo "?")
  echo "[prowler-trigger] [${ELAPSED}s] state=$STATE  progress=${PROGRESS}%"

  if [[ "$STATE" == "completed" ]]; then
    echo "[prowler-trigger] Scan completed successfully."
    exit 0
  elif [[ "$STATE" == "failed" ]]; then
    echo "[prowler-trigger] ERROR: Scan failed."
    exit 1
  fi
done

echo "[prowler-trigger] TIMEOUT: Scan did not finish within ${WAIT_TIMEOUT}s."
exit 1
