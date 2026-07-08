extends Node
class_name AppView

@export var lock            : TextureRect
@export var lock_open       : TextureRect
@export var label_input     : Label
@export var app             : window_handler

@export var link_icon       : TextureRect

var show_link_icon := false

var _window_focus   := true
var _lock_change_id := 0

func _ready() -> void:
    lock.visible            = false
    lock_open.visible       = true
    label_input.visible     = true
    app.window_focus.connect(_on_window_focus)
    app.window_focus_out.connect(_on_window_unfocus)
    app.window_interactable_change.connect(_on_lock_change)
    Config.link_entry_changed.connect(_on_link_entry_changed)
    _on_link_entry_changed(Config.get_link_entry())

func _on_link_entry_changed(entry : DataEntry) -> void :
    show_link_icon = entry != null

func _on_lock_change(active: bool) -> void:
    _lock_change_id += 1
    var id = _lock_change_id

    lock.visible        = not active
    lock_open.visible   = active
    label_input.visible = true

    await get_tree().create_timer(2).timeout

    if id != _lock_change_id:
        return

    if not app.window_interaction_active or not _window_focus:
        label_input.visible     = false
        lock.visible            = false
        lock_open.visible       = false
        link_icon.visible       = false

func _on_window_focus():
    if not app.window_interaction_active :
        return

    _window_focus       = true
    label_input.visible = true
    lock_open.visible   = true
    lock.visible        = false
    link_icon.visible   = show_link_icon          

func _on_window_unfocus():
    _window_focus = false
    if app.window_interaction_active :
        label_input.visible = false
        lock_open.visible   = false
        link_icon.visible   = false
        