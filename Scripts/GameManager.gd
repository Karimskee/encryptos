extends Node

# المتغير اللي بيحفظ إحنا في أي مرحلة حالياً
var current_level: int = 1

# ================================================================
# 1. قاعدة بيانات الألغاز (Level Data)
# ================================================================
# هنا بنحدد لكل ليفل: إيه الكلمة المطلوبة، وإيه طرق التشفير المتاحة
var level_data = {
	1: {
		"text": "Sweet", 
		"ciphers": ["Caesar", "Rail Fence"] 
	},
	2: {
		"text": "Duck", 
		"ciphers": ["Monoalphabetic", "Playfair"] 
	},
	3: {
		"text": "Dance", 
		"ciphers": ["Polyalphabetic", "Row Column Transposition"] 
	},
	4: {
		"text": "Time", 
		"ciphers": ["Hill", "Vigenere"] 
	},
	5: {
		"text": "Sweet Duck Dance Time", 
		# الليفل الأخير (بعد البوس) فيه خيارات كتير عشان يكون أصعب وفيه Reset
		"ciphers": ["One-Time Pad", "Hill", "Polyalphabetic", "Playfair"] 
	}
}

# دالة عشان مشهد الانكربشن يعرف هو المفروض يعرض إيه
func get_current_level_data() -> Dictionary:
	if level_data.has(current_level):
		return level_data[current_level]
	else:
		# لو حصل خطأ والرقم زاد عن 5، نرجع بيانات الليفل الأخير كأمان
		return level_data[5]


# ================================================================
# 2. نظام الانتقال (Scene Navigation)
# ================================================================
# الدالة دي بتزيد العداد وبتعرفنا إيه الخطوة الجاية
func next_level():
	current_level += 1
	print("Level Up! New Level is: ", current_level)

# الدالة دي بتقولنا "نروح فين" بعد ما حلينا اللغز صح
func get_next_scene_path() -> String:
	match current_level:
		# حلينا لغز 1 (Sweet) -> نروح ليفل 2
		2: return "res://Scens/level_2.tscn"
		
		# حلينا لغز 2 (Duck) -> نروح ليفل 3
		3: return "res://Scens/level_3.tscn"
		
		# حلينا لغز 3 (Dance) -> نروح ليفل 4
		4: return "res://Scens/level_4.tscn"
		
		# حلينا لغز 4 (Time) -> نروح للفاينل (البوس)
		5: return "res://Scens/final_level.tscn"
		
		# حلينا لغز 5 (الجملة الكاملة) -> مبروك الفوز
		6: return "res://Scens/win.tscn"
		
		# احتياطي: لو مفيش حاجة طابقت، يرجع للقائمة الرئيسية
		_: return "res://Scens/MainMenu.tscn"
