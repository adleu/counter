class_name DataEntry
extends RefCounted

var category    : String
var name        : String
var value       : int

func _init(_category : String, _name : String, _value : int = 0):
    category    = _category
    name        = _name
    value       = _value

func to_csv_line() -> PackedStringArray:
    return PackedStringArray([category, name, str(value)]) 

static func from_csv_line(line: PackedStringArray) -> DataEntry:
    return DataEntry.new(line[0], line[1], int(line[2]))

func equals(entry : DataEntry)-> bool :
    if entry == null:
        return false
    return entry.category == category and entry.name == name