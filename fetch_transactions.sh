#!/bin/bash

# Set up variables
address="32ixEdVJWo3kmvJGMTZq5jAQVZZeuwnqzo"
transactions_file="transactions.json"
> $transactions_file  # Clears the file

# Calculate epoch times
current_epoch=$(date +%s)
thirty_days_ago=$((current_epoch - 30*24*60*60))
seven_days_ago=$((current_epoch - 7*24*60*60))

# Initialize the last_seen_txid
last_seen_txid=""

# Fetch transactions and store them in transactions.json
while true; do
  if [ -z "$last_seen_txid" ]; then
    url="https://mempool.space/api/address/$address/txs/chain"
  else
    
url="https://mempool.space/api/address/$address/txs/chain/$last_seen_txid"
  fi

  echo "Fetching transactions from URL: $url"
  response=$(curl -sSL "$url")

  num_txs=$(echo "$response" | jq '. | length')
  if [ "$num_txs" -eq 0 ]; then
    echo "No more transactions to fetch."
    break
  fi

  # Append transactions to the file
  echo "$response" | jq -c '.[]' >> $transactions_file

  # Get the txid and block_time of the last transaction
  last_tx=$(echo "$response" | jq '.[-1]')
  last_seen_txid=$(echo "$last_tx" | jq -r '.txid')
  last_block_time=$(echo "$last_tx" | jq '.status.block_time')

  echo "Last seen txid: $last_seen_txid"
  echo "Last block time: $last_block_time"

  if [ "$last_block_time" -lt "$thirty_days_ago" ]; then
    echo "Reached transactions older than 30 days."
    break
  fi


  sleep 1
done

echo "Transactions have been saved to $transactions_file"
