extends CanvasLayer

@onready var panel = $Panel

@onready var speaker_name = $Panel/MarginContainer/HBoxContainer/VBoxContainer/Label

@onready var text_label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/RichTextLabel

@onready var portrait = $Panel/MarginContainer/HBoxContainer/TextureRect

@onready var continue_label = $Panel/MarginContainer/ContinueLabel


@export var text_speed := 0.03  # سرعة ظهور الحروف
@export var auto_hide_continue := true

var dialogue_queue: Array = []
var current_text := ""
var is_typing := false
var can_continue := false
var player_reference = null

signal dialogue_started
signal dialogue_finished
signal line_finished

func _ready():
	hide()
	print("TEXT LABEL =", text_label)
	
	# إعدادات الـ Panel
	if panel:
		panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		panel.custom_minimum_size = Vector2(0, 150)
	
	if continue_label:
		continue_label.text = "▼ Press Space"
		continue_label.visible = false


func _input(event):
	if not visible:
		return
	
	# لو ضغط Space/Enter
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			# لو النص لسه بيكتب، أظهره كله
			_finish_typing()
		elif can_continue:
			# لو النص خلص، كمّل للسطر اللي بعده
			_show_next_line()


func show_dialogue(dialogue_data: Array, player = null):
	"""
	dialogue_data = [
		{"speaker": "Guide", "text": "Welcome to the game!", "portrait": null},
		{"speaker": "Guide", "text": "Use WASD to move.", "portrait": null}
	]
	"""
	if dialogue_data.is_empty():
		return
	
	player_reference = player
	
	# إيقاف حركة اللاعب
	if player_reference:
		if player_reference.has_method("set_control_enabled"):
			player_reference.set_control_enabled(false)
		else:
			player_reference.control_enabled = false
			player_reference.velocity = Vector2.ZERO
	
	dialogue_queue = dialogue_data.duplicate()
	show()
	dialogue_started.emit()
	_show_next_line()


func _show_next_line():
	if dialogue_queue.is_empty():
		_end_dialogue()
		return

	can_continue = false
	if continue_label:
		continue_label.visible = false

	var line = dialogue_queue.pop_front()
	print("CURRENT LINE =", line)

	# اسم المتكلم
	if speaker_name:
		speaker_name.text = line.get("speaker", "")

	# ✅ الصورة (التعديل المهم)
	if portrait:
		if line.has("portrait") and line["portrait"] != null:
			portrait.texture = line["portrait"]
			portrait.visible = true
		else:
			portrait.visible = false

	# النص
	current_text = line.get("text", "")
	print("TEXT =", current_text)

	_type_text()




func _type_text():
	if not text_label:
		return
	
	is_typing = true
	text_label.text = ""
	
	for i in range(current_text.length()):
		if not is_typing:
			break
		
		text_label.text += current_text[i]
		await get_tree().create_timer(text_speed).timeout
	
	_finish_typing()


func _finish_typing():
	is_typing = false
	
	if text_label:
		text_label.text = current_text
	
	can_continue = true
	
	if continue_label and not auto_hide_continue:
		continue_label.visible = true
	
	line_finished.emit()


func _end_dialogue():
	hide()
	
	# رجع حركة اللاعب
	if player_reference:
		if player_reference.has_method("set_control_enabled"):
			player_reference.set_control_enabled(true)
		else:
			player_reference.control_enabled = true
	
	dialogue_finished.emit()


func skip_all():
	"""تخطي كل الحوار"""
	dialogue_queue.clear()
	_finish_typing()
	_end_dialogue()
