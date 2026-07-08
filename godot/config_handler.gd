extends Node

const config_path   : String = "res://files/conf.cfg"
var config          : ConfigFile

signal link_entry_changed(entry :DataEntry)

func _init() -> void:
	config = ConfigFile.new()

	if config.load(config_path) != OK :
		config.save(config_path)

func set_last_value(_value : int) -> void :
	config.set_value("value", "last_value", _value)
	config.save("res://files/conf.cfg")

func get_last_value() -> int :
	return config.get_value("value", "last_value", 0)

func set_window_pos(_value : Vector2i) -> void :
	config.set_value("settings","window_pos", _value)
	config.save("res://files/conf.cfg")

func try_get_window_pos() -> Variant: ## null or vector2i
	if not config.has_section_key("settings", "window_pos"):
			return null
	return config.get_value("settings", "window_pos")

func set_last_visited_category(_category : String) -> void :
	config.set_value("value","last_visited_category", _category)
	config.save("res://files/conf.cfg")

func get_last_visited_category() -> String :
	return config.get_value("value", "last_visited_category", "")

func set_link_entry(entry: DataEntry) -> void:
	if entry == null:
		config.set_value("value", "last_link_entry", "")
		config.save("res://files/conf.cfg")
		link_entry_changed.emit(null)
		return
	
	var previous = get_link_entry()
	config.set_value("value", "last_link_entry", "%s,%s" % [entry.category, entry.name])
	config.save("res://files/conf.cfg")
	
	if previous == null or not entry.equals(previous):
		link_entry_changed.emit(entry)


func get_link_entry() -> DataEntry:
	if not config.has_section_key("value", "last_link_entry"):
		return null
	
	var raw_value = config.get_value("value", "last_link_entry")
	
	if typeof(raw_value) != TYPE_STRING or raw_value.is_empty():
		return null
	
	var entry_args: PackedStringArray = raw_value.split(",", false, 2)
	if entry_args.size() != 2:
		return null
	
	var entry = DataEntry.new(entry_args[0], entry_args[1])
	if not DataHandler.entry_exists(entry):
		return null
	
	return entry
