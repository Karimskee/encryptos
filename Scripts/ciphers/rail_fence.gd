class_name RailFence
extends Node

# 🔒 ENCRYPTION
# Standard: Includes spaces/symbols in the scramble.
static func encrypt( rails: int, text: String) -> String:
	# Validation: 1 rail means no change
	if rails < 2 or text.length() == 0:
		return text
		
	# 1. Prepare empty strings for each rail
	var rail_rows: Array = []
	for i in range(rails):
		rail_rows.append("")
		
	# 2. Variables to track the "Zigzag" movement
	var current_row = 0
	var going_down = false
	
	# 3. Simulate the zigzag
	for i in range(text.length()):
		# Add character to the current rail
		rail_rows[current_row] += text[i]
		
		# Check if we hit the top or bottom rail to reverse direction
		if current_row == 0 or current_row == rails - 1:
			going_down = not going_down
			
		# Move the index
		current_row += 1 if going_down else -1
		
	# 4. Join all rows together to form the ciphertext
	var result = ""
	for row in rail_rows:
		result += row
		
	return result

# 🔓 DECRYPTION
# Strategy: Rebuild the empty grid, mark the spots, fill them, then read.
static func decrypt(rails: int, text: String) -> String:
	if rails < 2 or text.length() == 0:
		return text
		
	var length = text.length()
	
	# 1. Create a Matrix (2D Array) filled with empty markers
	# Using PackedByteArray for the grid is efficient (0 = empty, 1 = marker)
	var matrix = []
	for r in range(rails):
		var row = PackedByteArray()
		row.resize(length) # Fill with 0s
		matrix.append(row)
		
	# 2. MARK THE SPOTS (Simulate Zigzag)
	# We put a '1' where a character SHOULD exist in the zigzag pattern
	var row = 0
	var going_down = false
	
	for col in range(length):
		matrix[row][col] = 1 # Mark spot
		
		if row == 0 or row == rails - 1:
			going_down = not going_down
		row += 1 if going_down else -1
		
	# 3. FILL THE SPOTS (Read Ciphertext)
	# Now we iterate through the matrix row-by-row and fill the '1's with actual text
	var text_idx = 0
	# We need a separate structure to hold the characters because PackedByteArray is numbers only
	# We will just reconstruct the result by reading the zigzag again, 
	# so we actually need to store the characters in the matrix.
	# Let's use a Dictionary or Array of Arrays for the filled grid.
	
	var filled_grid = [] # 2D Array of Strings
	for r in range(rails):
		filled_grid.append([])
		for c in range(length):
			filled_grid[r].append("") # Empty placeholder
			
	# Fill logic
	for r in range(rails):
		for c in range(length):
			if matrix[r][c] == 1 and text_idx < length:
				filled_grid[r][c] = text[text_idx]
				text_idx += 1
				
	# 4. READ THE ZIGZAG (Reconstruct Plaintext)
	var result = ""
	row = 0
	going_down = false
	
	for c in range(length):
		# Pick the character from the specific zigzag spot
		result += filled_grid[row][c]
		
		if row == 0 or row == rails - 1:
			going_down = not going_down
		row += 1 if going_down else -1
		
	return result
