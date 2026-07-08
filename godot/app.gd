extends Node

class_name window_handler

@export var label 			: Label
@export var right_click 	: CanvasLayer
@export var input_handler 	: InputHandler

signal window_interactable_change(active : bool)
signal window_focus
signal window_focus_out
signal decrement # call only by change_i
signal increment # call only by change_i
signal i_updated # call by increment, decrement and set_i

const move_speed 	= 10
var i				= 0

## window drag
var mouse_pressed 	: bool = false
var offset			: Vector2i

## window active interactions
var window_interaction_active : bool = true

func _ready() -> void:
	get_window().size = Vector2i(32,32)
	label.text = str(i)

	Input.set_use_accumulated_input(true) 

	get_window().unfocusable 	= false  
	get_window().always_on_top 	= true
	get_window().transparent 	= true
	get_window().borderless		= true
	
	var screen_size = DisplayServer.screen_get_size()
	var window_pos 	= Config.try_get_window_pos()

	get_window().position = window_pos if window_pos != null else Vector2i(screen_size.x / 2,  screen_size.y / 2)

	set_to_last_value()

	i_updated.connect(_update_link_entry)
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		right_click.visible = true
		label.visible 		= false
		mouse_pressed 		= false

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

		clamp_window_to_screen(get_window().size.x - 64)
	
	if right_click.visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: 
		if event.pressed:
			mouse_pressed 	= true
			offset			= get_window().position - DisplayServer.mouse_get_position()
		else :
			mouse_pressed = false
	
	if mouse_pressed and event is InputEventMouseMotion :
		get_window().position += Vector2i(event.relative)
		clamp_window_to_screen(get_window().size.x - 64)


func change_i(add : bool):
	i += 1 if add else -1
	update_text()
	Config.set_last_value(i)

	[decrement, increment][int(add)].emit()
	i_updated.emit()

func set_i(value : int):
	i = value
	i_updated.emit()
	update_text()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()  
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		on_window_focus()
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		on_window_focus_out()

func on_window_focus() :
	window_focus.emit()

func on_window_focus_out() :
	window_focus_out.emit()

func quit():
	input_handler.quit_input_handler()
	
	if not right_click.visible:
		Config.set_window_pos(get_window().position)

	get_tree().quit()

func set_to_last_value() :
	var linked_entry = Config.get_link_entry()
	if linked_entry == null:
		i = Config.get_last_value()
	else :
		i = DataHandler.get_entry_real_value(linked_entry)
	update_text()

func update_text() -> void :
	label.text = str(i)

func _update_link_entry():
	var linked_entry = Config.get_link_entry()
	
	if linked_entry == null :
		return
	linked_entry.value = i

	DataHandler.add_or_edit_entry(linked_entry)

func clamp_window_to_screen(_offset : float = 0):
	var window 			= get_window()
	var screen_size 	= DisplayServer.screen_get_size()
	var screen_index 	= DisplayServer.window_get_current_screen()
	var screen_pos 		= DisplayServer.screen_get_position(screen_index)
	
	var window_pos 	= window.position
	var window_size = window.size
	
	var new_x = clamp(window_pos.x, screen_pos.x - _offset, screen_pos.x + screen_size.x - window_size.x + _offset)
	var new_y = clamp(window_pos.y, screen_pos.y - _offset, screen_pos.y + screen_size.y - window_size.y + _offset)
	
	if new_x != window_pos.x || new_y != window_pos.y:
		window.position = Vector2i(new_x, new_y)

func toggle_window_passthrough() -> void:
	window_interaction_active = not window_interaction_active
	print_debug("toggle window interactable to '%s'" %window_interaction_active)
	window_interactable_change.emit(window_interaction_active)

	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, not window_interaction_active)

	## we need this to work on window
	AllowClickThrough.SetClickThrough(not window_interaction_active)
