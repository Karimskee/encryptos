extends CanvasLayer

@onready var rect := $ColorRect
@export var fade_time := 1

var is_transitioning := false

func _ready():
	if not rect:
		push_error("ColorRect not found in Transition scene!")
		return
	
	# ابدأ من شاشة سودا
	rect.modulate.a = 1.0
	rect.visible = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP  # امنع التفاعل أثناء الـ transition
	
	# استنى الـ Scene يحمّل
	await get_tree().process_frame
	fade_in()


func fade_in():
	if not rect or is_transitioning:
		return
	
	rect.visible = true
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func(): 
		if rect:
			rect.visible = false
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func fade_out(callback := Callable()):
	if not rect or is_transitioning:
		print("Warning: Transition already in progress or rect not found!")
		return
	
	is_transitioning = true
	rect.visible = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, fade_time)
	
	if callback.is_valid():
		tween.tween_callback(callback)
	
	# بعد تغيير السين، اعمل fade in
	tween.tween_callback(func():
		is_transitioning = false
		# استنى فريم واحد عشان الـ Scene الجديد يحمّل
		await get_tree().process_frame
		fade_in()
	)


func change_scene(scene_path: String):
	
	fade_out(func():
		var error = get_tree().change_scene_to_file(scene_path)
		if error != OK:
			push_error("Failed to load scene: " + scene_path)
			is_transitioning = false
			fade_in()
	)
