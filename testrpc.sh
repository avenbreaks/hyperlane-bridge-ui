#!/usr/bin/env bash

RPCS=(
  "https://rpc.davinci.bz"
  "https://rpc-bridge.davinci.bz"
  "https://rpc-explorer.davinci.bz"
)

test_method() {
  local RPC="$1"
  local METHOD="$2"
  curl -s -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"method\":\"$METHOD\",\"params\":[],\"id\":1}" \
    "$RPC" | jq -r ".result // .error"
}

echo
echo "🔍 Testing RPC Health, CORS, Latency & PoS Engine"
echo

for RPC in "${RPCS[@]}"; do
  echo "=============================================================="
  echo "RPC: $RPC"
  
  # CORS check
  cors=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$RPC" \
      -H "Origin: https://example.com" \
      -H "Access-Control-Request-Method: POST")

  if [[ "$cors" == "204" || "$cors" == "200" ]]; then
    echo "CORS: ✅ Allowed ($cors)"
  else
    echo "CORS: ❌ Not Allowed ($cors)"
  fi

  # Latency
  t=$(curl -s -o /dev/null -w "%{time_total}" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    "$RPC")
  printf "Latency: %.2f ms\n" "$(awk "BEGIN {print $t*1000}")"

  echo
  echo "→ JSON-RPC STATUS:"
  echo "eth_blockNumber        → $(test_method "$RPC" "eth_blockNumber")"
  echo "net_version            → $(test_method "$RPC" "net_version")"
  echo "eth_chainId            → $(test_method "$RPC" "eth_chainId")"
  echo "eth_syncing            → $(test_method "$RPC" "eth_syncing")"
  echo "web3_clientVersion     → $(test_method "$RPC" "web3_clientVersion")"

  echo
done

echo "Done ✅"
