#!/usr/bin/env bash
# rpc-dapps-ratecheck.sh
# Tes rate-limit untuk RPC endpoints (dApps-focused set of JSON-RPC methods).
#
# Usage:
#   ./rpc-dapps-ratecheck.sh endpoints.txt 20 30
#   OR set env vars:
#     ADDRESS=0xYourAddressSignedOrPublic ./rpc-dapps-ratecheck.sh endpoints.txt 20 30
#
# Requirements: bash (4+), curl, jq
# - Sends REQ_PER_SEC requests per endpoint for DURATION seconds.
# - Rotates through a set of safe/read-only JSON-RPC methods commonly used by dApps:
#   eth_blockNumber, net_version, eth_chainId, web3_clientVersion,
#   eth_getBalance, eth_getTransactionCount, eth_getCode, eth_call,
#   eth_getLogs, eth_estimateGas
# - Logs CSV per endpoint and saves raw responses for debugging.
# - Does NOT send transactions by default. eth_sendRawTransaction is disabled unless you provide file of signed raw txs (see below).
#
set -euo pipefail

ENDPOINTS_FILE="${1:-endpoints.txt}"
REQ_PER_SEC="${2:-20}"           # requests per second per endpoint
DURATION="${3:-30}"              # seconds per endpoint
ADDRESS="${ADDRESS:-0x0000000000000000000000000000000000000000}" # override via env
SIGNED_TXS_FILE="${SIGNED_TXS_FILE:-}" # optional: newline-separated signed raw tx hex (if provided, will test sends carefully)

if ! command -v curl >/dev/null 2>&1; then
  echo "curl diperlukan. install dulu."; exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq diperlukan. install dulu."; exit 1
fi
if ((BASH_VERSINFO[0] < 4)); then
  echo "Bash >= 4 diperlukan."; exit 1
fi

OUTDIR="rpc_dapps_ratecheck_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

echo "Mulai dApp-focused RPC rate-check"
echo "  endpoints file: $ENDPOINTS_FILE"
echo "  rate: $REQ_PER_SEC req/s"
echo "  dur: $DURATION s per endpoint"
echo "  test address: $ADDRESS"
[ -n "$SIGNED_TXS_FILE" ] && echo "  signed txs file (will test send): $SIGNED_TXS_FILE"
echo "  output dir: $OUTDIR"
echo

# Define methods and sample payloads (safe/read-only)
# We'll rotate through lists; payloads use jq -n to keep quotes sane.
methods=(
  "eth_blockNumber"
  "net_version"
  "eth_chainId"
  "web3_clientVersion"
  "eth_getBalance"
  "eth_getTransactionCount"
  "eth_getCode"
  "eth_call"
  "eth_getLogs"
  "eth_estimateGas"
)

# Function to build JSON payload for method index (returns single-line JSON)
build_payload() {
  local idx="$1"
  local id="$2"
  local method="${methods[$idx]}"
  case "$method" in
    "eth_blockNumber")
      jq -n --arg m "$method" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[], id:$id}'
      ;;
    "net_version"|"eth_chainId"|"web3_clientVersion")
      jq -n --arg m "$method" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[], id:$id}'
      ;;
    "eth_getBalance")
      # use provided ADDRESS, block "latest"
      jq -n --arg m "$method" --arg a "$ADDRESS" --arg b "latest" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[$a,$b], id:$id}'
      ;;
    "eth_getTransactionCount")
      jq -n --arg m "$method" --arg a "$ADDRESS" --arg b "latest" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[$a,$b], id:$id}'
      ;;
    "eth_getCode")
      jq -n --arg m "$method" --arg a "$ADDRESS" --arg b "latest" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[$a,$b], id:$id}'
      ;;
    "eth_call")
      # harmless call: to ADDRESS (default zero), data "0x" (no-op), latest
      jq -n --arg m "$method" --arg a "$ADDRESS" --arg d "0x" --arg b "latest" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[{to:$a,data:$d}, $b], id:$id}'
      ;;
    "eth_getLogs")
      # Query recent logs: from latest-10 to latest, no address filter (may be heavy on some nodes)
      # We'll set small range to reduce server load.
      # params: [ filterObject ]
      jq -n --arg m "$method" --arg from "latest-10" --arg to "latest" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[{fromBlock:$from, toBlock:$to}], id:$id}'
      ;;
    "eth_estimateGas")
      # estimate simple tx gas: from ADDRESS -> to zero, value 0
      jq -n --arg m "$method" --arg from "$ADDRESS" --arg to "0x0000000000000000000000000000000000000000" --arg v "0x0" --arg d "0x" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[{from:$from,to:$to,value:$v,data:$d}], id:$id}'
      ;;
    *)
      jq -n --arg m "$method" --argjson id "$id" '{jsonrpc:"2.0", method:$m, params:[], id:$id}'
      ;;
  esac
}

# If SIGNED_TXS_FILE provided, read into array (but we won't run sends unless explicitly enabled below)
signed_txs=()
if [ -n "$SIGNED_TXS_FILE" ] && [ -f "$SIGNED_TXS_FILE" ]; then
  mapfile -t signed_txs < <(sed '/^\s*$/d' "$SIGNED_TXS_FILE")
fi

send_request() {
  local endpoint="$1"
  local payload="$2"
  local method="$3"
  local id="$4"
  local logfile="$5"

  # Send request and capture http status, headers, body (single POST)
  # Use --include to get headers + body together, but we also fetch http code separately for reliability
  # timeout to avoid stuck processes
  resp_headers_body=$(curl -s -S -D - --max-time 8 -H "Content-Type: application/json" -X POST --data "$payload" "$endpoint" 2>&1) || curl_ret=$? || true
  http_status=$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -X POST --data "$payload" "$endpoint" 2>/dev/null || echo "000")

  # Extract headers (lines before first empty line)
  headers=$(printf "%s\n" "$resp_headers_body" | awk 'BEGIN{h=1} { if (h==1 && NF==0){h=0; next} if (h==1) print }')
  # Extract body (lines after first empty line)
  body=$(printf "%s\n" "$resp_headers_body" | awk 'BEGIN{h=1} { if (h==1 && NF==0){h=0; next} if (h==0) print }')

  # Extract JSON-RPC error message if any
  rpc_err=$(printf "%s" "$body" | jq -r '.error.message // .error // empty' 2>/dev/null || true)

  # Collect rate-limit-like headers
  rate_headers=$(printf "%s\n" "$headers" | tr -d '\r' | awk '/Rate|rate|Retry-After|x-ratelimit|X-RateLimit/ {print}' | tr '\n' ' ')

  ts=$(date --iso-8601=seconds)

  # CSV: timestamp,req_id,method,http_status,rpc_error,rate_headers
  printf "%s,%s,%s,%s,%s,%s\n" "$ts" "$id" "$method" "$http_status" "$(echo "$rpc_err" | tr ',' ';' | tr -d '\n')" "$(echo "$rate_headers" | sed 's/,/;/g')" >>"$logfile"

  # save raw body for debug
  safefile="${logfile%.csv}__resp_${method}_${id}.json"
  printf "%s\n" "$body" >"$safefile"
}

# Main loop: per-endpoint
while IFS= read -r endpoint || [ -n "$endpoint" ]; do
  endpoint="$(echo "$endpoint" | sed 's/[[:space:]]*$//')"
  [ -z "$endpoint" ] && continue
  echo "== Testing endpoint: $endpoint =="
  safe_name=$(echo "$endpoint" | sed 's~https\?://~~; s/[:/]/_/g')
  logfile="$OUTDIR/${safe_name}.csv"
  echo "timestamp,req_id,method,http_status,rpc_error,rate_headers" >"$logfile"

  total_requests=$((REQ_PER_SEC * DURATION))
  interval=$(awk "BEGIN {print 1.0 / $REQ_PER_SEC}")
  id_counter=100000

  method_count=${#methods[@]}
  echo "  sending approx $total_requests requests (rotating $method_count methods) for $DURATION seconds..."

  # Launch requests in loop, round-robin methods
  for i in $(seq 1 "$total_requests"); do
    method_idx=$(( (i-1) % method_count ))
    method_name="${methods[$method_idx]}"
    payload=$(build_payload "$method_idx" "$id_counter")

    # Fire async to maintain rate; careful with many background jobs on very high rates
    send_request "$endpoint" "$payload" "$method_name" "$id_counter" "$logfile" &

    id_counter=$((id_counter + 1))
    sleep "$interval"
  done

  # wait for all background jobs for this endpoint
  wait

  # Summarize
  total=$(wc -l <"$logfile")
  total=$((total - 1))
  ok_count=$(awk -F, 'NR>1 && ($4 ~ /^2/ || $4 ~ /^1/) {c++} END{print c+0}' "$logfile")
  count_429=$(awk -F, 'NR>1 && $4==429 {c++} END{print c+0}' "$logfile")
  count_rpc_err=$(awk -F, 'NR>1 && $5!="" {c++} END{print c+0}' "$logfile")
  has_rate_headers=$(awk -F, 'NR>1 && $6!="" {c++} END{print c+0}' "$logfile")

  echo "  total requests recorded: $total"
  echo "  HTTP 2xx/1xx responses: $ok_count"
  echo "  HTTP 429 responses: $count_429"
  echo "  JSON-RPC errors reported: $count_rpc_err"
  echo "  Responses including rate-limit headers: $has_rate_headers"
  echo "  raw logs: $logfile"
  echo
done < "$ENDPOINTS_FILE"

echo "Selesai. Periksa folder $OUTDIR untuk laporan & raw responses."
echo "Notes:"
echo " - Script tidak mengirim transaksi (eth_sendRawTransaction) kecuali kamu aktifkan manual pengujian sends."
echo " - eth_getLogs over wide ranges can be heavy; script uses latest-10 to reduce load."
echo " - Jangan jalankan tanpa izin pada RPC yang bukan milikmu (could be considered abusive)."
