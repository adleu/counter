extends Node

const config_path   : String = "res://files/conf.cfg"
var config          : ConfigFile

func _init() -> void:
	config = ConfigFile.new()

	if config.load(config_path) != OK :
		push_error("could not load conf file at " + config_path)

func set_last_value(_value : int) -> void :
	config.set_value("value", "last_value", _value)
	config.save("res://files/conf.cfg")

func get_last_value() -> int :
	return config.get_value("value", "last_value", 0)

func set_window_pos(_value : Vector2i) -> void :
	config.set_value("settings","window_pos", _value)
	config.save("res://files/conf.cfg")

func try_get_window_pos() -> Variant: ## null or vector2i
	return config.get_value("settings", "window_pos")
