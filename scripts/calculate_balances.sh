#!/bin/bash

# Set up variables
address="32ixEdVJWo3kmvJGMTZq5jAQVZZeuwnqzo"
transactions_file="transactions.json"
thirty_days_ago=$(( $(date +%s) - 30*24*60*60 ))
seven_days_ago=$(( $(date +%s) - 7*24*60*60 ))

# Filter transactions within the last 30 days
jq -s 'map(select(.status.block_time >= '"$thirty_days_ago"'))' 
$transactions_file > transactions_30d.json

# Filter transactions within the last 7 days
jq -s 'map(select(.status.block_time >= '"$seven_days_ago"'))' 
$transactions_file > transactions_7d.json

# Define functions to calculate received and sent amounts
calculate_received() {
  file=$1
  total_received=$(jq '[.[].vout[] | select(.scriptpubkey_address == 
"'$address'") | .value] | add' $file)
  echo ${total_received:-0}
}

calculate_sent() {
  file=$1
  total_sent=0
  jq -c '.[]' $file | while read -r tx; do
    echo "$tx" | jq -c '.vin[]?' | while read -r vin; do
      prev_txid=$(echo "$vin" | jq -r '.txid')
      vout_index=$(echo "$vin" | jq -r '.vout')
      # Fetch the previous transaction
      prev_tx=$(curl -sSL "https://mempool.space/api/tx/$prev_txid")
      prev_vout=$(echo "$prev_tx" | jq '.vout['$vout_index']')
      scriptpubkey_address=$(echo "$prev_vout" | jq -r 
'.scriptpubkey_address')
      if [ "$scriptpubkey_address" == "$address" ]; then
        value=$(echo "$prev_vout" | jq -r '.value')
        total_sent=$((total_sent + value))
      fi
    done
  done
  echo $total_sent
}

# Calculate balance change over the last 30 days
received_30d=$(calculate_received transactions_30d.json)
sent_30d=$(calculate_sent transactions_30d.json)
balance_change_30d=$((received_30d - sent_30d))
echo "Balance variation over the last 30 days: $balance_change_30d sats"

# Calculate balance change over the last 7 days
received_7d=$(calculate_received transactions_7d.json)
sent_7d=$(calculate_sent transactions_7d.json)
balance_change_7d=$((received_7d - sent_7d))
echo "Balance variation over the last 7 days: $balance_change_7d sats"

