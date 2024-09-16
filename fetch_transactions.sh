#!/bin/bash

# Variables
address="32ixEdVJWo3kmvJGMTZq5jAQVZZeuwnqzo"
transactions_file="transactions.json"
> $transactions_file  # Clear the file before starting

# Calculate epoch times
current_epoch=$(date +%s)
thirty_days_ago=$((current_epoch - 30*24*60*60))
seven_days_ago=$((current_epoch - 7*24*60*60))

# Initialize the last_seen_txid for pagination
last_seen_txid=""

# Function to check if the response is valid JSON
is_valid_json() {
  echo "$1" | jq . >/dev/null 2>&1
}

# Fetch transactions and store them in transactions.json
while true; do
  # Construct the URL for fetching transactions
  if [ -z "$last_seen_txid" ]; then
    url="https://mempool.space/api/address/$address/txs/chain"
  else
    
url="https://mempool.space/api/address/$address/txs/chain/$last_seen_txid"
  fi

  echo "Fetching transactions from URL: $url"
  
  # Fetch the transaction data
  response=$(curl -sSL "$url")

  # Check if the response is valid JSON
  if ! is_valid_json "$response"; then
    echo "Error: Invalid JSON response. Skipping this batch."
    break
  fi

  # Append transactions to the transactions file
  echo "$response" | jq -c '.[] | select(.status)' >> $transactions_file

  # Get the txid and block_time of the last transaction
  last_tx=$(echo "$response" | jq '.[-1]')
  last_seen_txid=$(echo "$last_tx" | jq -r '.txid')
  last_block_time=$(echo "$last_tx" | jq '.status.block_time')

  echo "Last seen txid: $last_seen_txid"
  echo "Last block time: $last_block_time"

  # Break the loop if we've reached transactions older than 30 days
  if [ "$last_block_time" -lt "$thirty_days_ago" ]; then
    echo "Reached transactions older than 30 days."
    break
  fi

  # Sleep for 1 second to avoid API rate limits
  sleep 1
done

echo "Transactions have been saved to $transactions_file"

# End of script

