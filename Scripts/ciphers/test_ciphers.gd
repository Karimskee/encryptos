extends Node


var plain_text = "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 1234567890 !@#$%^&*()_+-=~,./;:'\"[]{}<>"
var key = 3


func _ready():
	var ciphers = [caesar]
	
	for cipher in ciphers:
		test(cipher, plain_text, key)


func test(function: Callable, plain_text: String, key: int):
	var decrypted_text = function.call(plain_text, key)
	
	if (plain_text == decrypted_text):
		print("[SUCCESS] %s cipher is working properly." % function.get_method())
	else:
		print("[FAIL] %s cipher is not working properly." % function.get_method())
	print()


func caesar(plain_text: String, key: int):
	# For debugging
	print("Caesar cipher")
	print("Key: ", key)
	print("Plain Text: ", plain_text)
	
	# Encrypt
	var cipher_text = Caesar.encrypt(plain_text, key)
	print("Encrypted:  ", cipher_text) 
	
	# Decypt
	var decrypted_text = Caesar.decrypt(cipher_text, key)
	print("Decrypted:  ", decrypted_text)
	
	return decrypted_text
