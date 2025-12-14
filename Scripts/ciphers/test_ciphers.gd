extends Node


# Global variables
# some plan texts to use
# "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 1234567890 !@#$%^&*()_+-=~,./;:'\"[]{}<>"
var plain_text = "Karim is 3azim!"

var key_int = 3
var key_string_alpha_perm = "BACDEFGHIJKLMNOPQRSTUVWXYZ"


func _ready():
	print("[TESTING CIPHERS]\n")
	
	# ADD NEW CIPHERS HERE
	var ciphers = [
		Caesar,
		Monoalphabetic,
		OneTimePad,
		Polyalphabetic
	]
	
	for cipher in ciphers:
		test(cipher)


func test(cipher: Script) -> void:
	var key
	var methods = cipher.get_script_method_list()
	
	# Different cipher need different key types
	# The code below adapts to the required cipher type
	if methods[0].args[0].type == 2:	# TYPE_INT == 2
		key = key_int
	elif cipher == OneTimePad:
		# SPECIAL CASE: OTP needs a key as long as the text
		key = OneTimePad.generate_random_key(plain_text.length())
	else:								# TYPE_STRING == 4 or VARIANT == 0
		key = key_string_alpha_perm
	
	# For debugging
	print(cipher.get_global_name() + " cipher")
	print("Key: ", key)
	print("Plain Text: ", plain_text)
	
	# Encrypt
	var cipher_text = cipher.encrypt(key, plain_text)
	print("Encrypted:  ", cipher_text)
	
	# Decypt
	var decrypted_text = cipher.decrypt(key, cipher_text)
	print("Decrypted:  ", decrypted_text)
	
	if (plain_text == decrypted_text):
		print("[SUCCESS] %s cipher is working properly." % cipher.get_global_name())
	else:
		printerr("[FAIL] %s cipher is not working properly." % cipher.get_global_name())
	print()
