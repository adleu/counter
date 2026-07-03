extends Node2D

class_name window_handler

@export var label 			: Label
@export var right_click 	: CanvasLayer
@export var input_handler 	: InputHandler

const move_speed 	= 10
var i				= 0

func _ready() -> void:
	label.text = str(i)

	Input.set_use_accumulated_input(true) 

	get_window().unfocusable 	= false  
	get_window().always_on_top 	= true
	get_window().transparent 	= true
	get_window().borderless		= true
	
	var screen_size = DisplayServer.screen_get_size()
	var window_size = Vector2i(120, 120)

	var window_pos = Config.try_get_window_pos()
	get_window().position = window_pos if window_pos != null else Vector2i(screen_size.x - window_size.x - 10,  screen_size.y - window_size.y - 10)

	set_to_last_value()
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		right_click.visible = true
		label.visible 		= false

	if event is InputEventKey and event.pressed:	
		match event.keycode:
			KEY_UP:
				get_window().position.y -= move_speed
			KEY_DOWN:
				get_window().position.y += move_speed
			KEY_LEFT:
				get_window().position.x -= move_speed
			KEY_RIGHT:
				get_window().position.x += move_speed

func change_i(add : bool):
	i += 1 if add else -1
	update_text()
	Config.set_last_value(i)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()  

func quit():
	input_handler.quit_input_handler()
	Config.set_window_pos(get_window().position)
	get_tree().quit()

func set_to_last_value() :
	i = Config.get_last_value()
	update_text()

func update_text() -> void :
	label.text = str(i)
