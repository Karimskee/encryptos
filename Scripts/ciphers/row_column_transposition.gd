class_name RowColumnTransposition
extends Node

# 🔒 ENCRYPTION
# Strategy: Write text into rows, read out columns based on key order.
static func encrypt(key: String, text: String) -> String:
	if key.is_empty(): 
		return text
		
	var num_cols = key.length()
	var length = text.length()
	
	# 1. Get the read order (e.g. "ZEBRA" -> [4, 2, 1, 3, 0])
	var order = get_column_order(key)
	
	# 2. Build the Grid
	# We don't actually need a 2D array variable. We can calculate the index mathematically.
	# But a grid is easier to visualize and debug.
	var num_rows = ceil(float(length) / num_cols)
	var grid = []
	
	# Fill grid with empty strings
	for r in range(num_rows):
		grid.append([])
		for c in range(num_cols):
			grid[r].append("")
			
	# Write text Row by Row
	for i in range(length):
		var row = i / num_cols
		var col = i % num_cols
		grid[row][col] = text[i]
		
	# 3. Read Columns based on Key Order
	var result = ""
	for col_idx in order:
		for r in range(num_rows):
			# Careful: The last row might be empty for some columns
			if grid[r][col_idx] != "":
				result += grid[r][col_idx]
				
	return result

# 🔓 DECRYPTION
# Strategy: Calculate column heights, fill grid by column (sorted), read rows.
static func decrypt(key: String, text: String) -> String:
	if key.is_empty():
		return text
		
	var num_cols = key.length()
	var length = text.length()
	var num_rows = int(ceil(float(length) / num_cols))
	
	# 1. Get the order
	var order = get_column_order(key)
	
	# 2. Calculate column heights
	# The last row is often incomplete. Some columns are "Long" (full height), some are "Short".
	# Example: 12 chars, 5 cols. Rows = 3.
	# Last row has 12 % 5 = 2 items.
	# So cols 0 and 1 have 3 items. Cols 2, 3, 4 have 2 items.
	
	var remainder = length % num_cols
	var col_lengths = []
	col_lengths.resize(num_cols)
	
	for c in range(num_cols):
		if remainder == 0 or c < remainder:
			col_lengths[c] = num_rows # Full column
		else:
			col_lengths[c] = num_rows - 1 # Short column
			
	# 3. Reconstruct the Grid
	# We need a placeholder grid
	var grid = []
	for r in range(num_rows):
		var empty_row = []
		empty_row.resize(num_cols)
		grid.append(empty_row)
	
	# 4. Fill the Grid Column by Column (following the SORTED key order)
	var current_char_idx = 0
	
	for k_idx in range(num_cols):
		# Which column are we filling right now?
		# If key is ZEBRA, first we fill the column for 'A' (index 4)
		var target_col = order[k_idx]
		
		# How many chars go in this specific column?
		var height = col_lengths[target_col]
		
		# Fill it
		for r in range(height):
			if current_char_idx < length:
				grid[r][target_col] = text[current_char_idx]
				current_char_idx += 1
				
	# 5. Read the Grid Row by Row
	var result = ""
	for r in range(num_rows):
		for c in range(num_cols):
			# Skip nulls if any logic slipped (safety check)
			if grid[r][c] != null:
				result += grid[r][c]
				
	return result

# 🔢 HELPER: Get Column Order from Key
# Input: "ZEBRA" -> Output: [4, 2, 1, 3, 0]
static func get_column_order(key: String) -> Array:
	var key_chars = []
	for i in range(key.length()):
		# Store [Character, OriginalIndex]
		key_chars.append({"char": key[i], "id": i})
		
	# Sort based on the character code
	key_chars.sort_custom(func(a, b): return a["char"] < b["char"])
	
	# Extract just the original indices
	var result = []
	for item in key_chars:
		result.append(item["id"])
		
	return result


static func generate_random_key(length: int = 0) -> String:
	if length == 0: length = randi_range(5, 8)
	
	var result = ""
	for i in range(length):
		result += String.chr(randi_range(65, 90))
	return result
