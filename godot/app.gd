extends Node2D

class_name window_handler

@export var label : Label
@export var right_click : CanvasLayer
@export var input_handler : InputHandler

var i = 0
var move_speed = 10
var window 

func _ready() -> void:
	window = get_window()
	label.text = str(i)
	Input.set_use_accumulated_input(true) 
	get_window().unfocusable = false  
	get_window().always_on_top = true
	get_window().transparent = true
	get_window().borderless = true
	
	var screen_size = DisplayServer.screen_get_size()
	var window_size = Vector2i(120, 120)
	get_window().position = Vector2i(
		screen_size.x - window_size.x - 10,  
		screen_size.y - window_size.y - 10   
	)
	var config = ConfigFile.new()
	var err = config.load("res://files/conf.cfg")
	if err == OK && config.get_value("settings","window_pos") != null:
		get_window().position = config.get_value("settings","window_pos")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		right_click.visible = true
		label.visible = false

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:	
		match event.keycode:
			KEY_UP:
				window.position.y -= move_speed
			KEY_DOWN:
				window.position.y += move_speed
			KEY_LEFT:
				window.position.x -= move_speed
			KEY_RIGHT:
				window.position.x += move_speed

func change_i(add : bool):
	if add:
		i+=1
	else:
		i-=1
	label.text = str(i)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()  

func quit():
	input_handler.quit_input_handler()
	var config = ConfigFile.new()
	var err = config.load("res://files/conf.cfg")
	if err == OK :
		config.set_value("value","last_value",i)
		config.save("res://files/conf.cfg")
	get_tree().quit()
