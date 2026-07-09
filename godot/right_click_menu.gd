extends CanvasLayer

@export var wh 			    : window_handler
@export var reset_button 	: Button
@export var edit_widow: Window

var temp_pos 	    : Vector2i

func _ready() -> void:
    wh.window_interactable_change.connect(on_window_interactable_change)
    reset_button.focus_exited.connect(_reset_button_default)

func on_window_interactable_change(_active : bool) -> void:
    if not visible:
        return
    close()

    
func _on_button_back_pressed() -> void:
    close()

func _on_button_quit_pressed() -> void:
    Config.set_window_pos(temp_pos)
    wh.quit()

func _on_manage_pressed() -> void:
    if  edit_widow.visible:
        edit_widow.close_requested.emit()
    else:
        edit_widow.show()
    
func close():
    visible = false
    wh.label.visible = true

func _on_visibility_changed() -> void:
    if visible:
        temp_pos = get_window().position
        wh.clamp_window_to_screen()
    else:
        get_window().position = temp_pos


## reset button
var pressed     := false
var reset_timer : Timer

func _on_button_reset_pressed() -> void:
    if not pressed :
        pressed = true 
        reset_button.add_theme_color_override("font_color", Color.RED)
        reset_button.add_theme_color_override("font_hover_color", Color.RED)
        reset_button.text = "reset ?"
        _start_reset_timer()
    else :
        _reset_button_default()
        reset_timer.stop()
        wh.set_i(0)
        close()

func _reset_button_default() :
    reset_button.remove_theme_color_override("font_color")
    reset_button.remove_theme_color_override("font_hover_color")
    reset_button.text = "reset"
    pressed = false 

func _start_reset_timer() :
    if reset_timer == null:
        reset_timer = Timer.new()
        reset_button.add_child(reset_timer)
        reset_timer.one_shot = true
        reset_timer.wait_time = 1
        reset_timer.timeout.connect(_reset_button_default)
    reset_timer.start()
