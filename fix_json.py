import json

# Read the malformed JSON file
with open('transactions.json', 'r') as file:
    raw_data = file.read()

# Attempt to wrap the objects in a JSON array
try:
    # Split the raw data by newlines and filter out invalid lines
    lines = raw_data.split('\n')
    transactions = []
    invalid_count = 0  # Counter for invalid transactions

    for line in lines:
        try:
            # Try to load each line as JSON
            transaction = json.loads(line)

            # Check if 'vout' is present and is a list (valid data)
            if 'vout' in transaction and isinstance(transaction['vout'], list):
                transactions.append(transaction)
            else:
                # Log transactions with invalid 'vout' data
                invalid_count += 1
                print(f"Invalid 'vout' detected in transaction: {transaction.get('txid', 'unknown')}")
        except json.JSONDecodeError:
            # Ignore lines that are not valid JSON objects
            continue

    # Save the cleaned-up transactions as a proper JSON array
    with open('formatted_transactions.json', 'w') as output_file:
        json.dump(transactions, output_file, indent=4)

    print(f"Formatted transactions saved to 'formatted_transactions.json'.")
    print(f"Number of invalid transactions skipped: {invalid_count}")

except Exception as e:
    print(f"An error occurred: {e}")

