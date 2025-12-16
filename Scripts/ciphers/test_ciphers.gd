extends Node


# Global variables

## some plain texts to use
## "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 1234567890 !@#$%^&*()_+-=~,./;:'\"[]{}<>"
var plain_text = "Karim is 3azim!"
var key_int = 3
var key_string_alpha_perm = "BACDEFGHIJKLMNOPQRSTUVWXYZ"


func _ready():
	"""
	Launch a full testing process for existing ciphers
	
	approach:
	- Compare original text with decrypted text
	- Some ciphers decrypt text to a different format from the original text,
	  yet a valid one
	"""
	print(">>> [TESTING CIPHERS] <<<\n")
	
	# Cipher classes
	var ciphers = [
		Caesar,
		Monoalphabetic,
		OneTimePad,
		Polyalphabetic,
		RailFence,
		RowColumnTransposition,
		Playfair,
		Hill,
	]
	
	# For each cipher
	for cipher in ciphers:
		test(cipher)


func test(cipher: Script) -> void:
	"""For testing individual ciphers"""
	var key # Might be an int, an x chars string
	var methods = cipher.get_script_method_list()
	
	# Different cipher need different key types
	# The code below adapts to the required cipher type
	
	## TYPE_INT == 2
	if methods[0].args[0].type == 2:
		key = key_int
		
	## SPECIAL CASE: OTP needs a key as long as the text
	elif cipher == OneTimePad:
		key = OneTimePad.generate_random_key(plain_text.length())

	## SPECIAL CASE: Hill needs a 4 chars string that follows a mathematical
	## formula
	elif cipher == Hill:
		key = Hill.generate_valid_key()
		
	## TYPE_STRING == 4 or VARIANT == 0
	else:
		key = key_string_alpha_perm
	
	# For debugging
	print("[" + cipher.get_global_name() + " Cipher]")
	print("Key:        ", key)
	print("Plain Text: ", plain_text)
	
	# Encrypt
	var cipher_text = cipher.encrypt(key, plain_text)
	print("Encrypted:  ", cipher_text)
	
	# Some ciphers decrypt text to a different format from the original text,
	# yet a valid one
	var expected_text = plain_text
	
	if cipher == Playfair:
		expected_text = Playfair.get_expected_playfair_output(plain_text)
	
	if cipher == Hill:
		expected_text = Hill.get_expected_hill_output(plain_text)
	
	print("expected:   " + expected_text)
	
	# Decypt
	var decrypted_text = cipher.decrypt(key, cipher_text)
	print("Decrypted:  ", decrypted_text)
	
	# Validate cipher output
	if (expected_text == decrypted_text):
		print_rich("[color=green][SUCCESS] %s cipher is working properly." % cipher.get_global_name() + "[/color]")
	else:
		printerr("[color=green][FAIL] %s cipher is not working properly." % cipher.get_global_name() + "[/color]")
	print()
