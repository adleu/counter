class_name DataHandler
extends RefCounted

const DATA_PATH := "res://files/datas.csv"

static func save_to_csv(entries : Array[DataEntry]) -> void :
    sort_entries(entries)
    _create_default_csv()
    var file = FileAccess.open(DATA_PATH, FileAccess.WRITE)
    file.store_csv_line(["category", "name", "value"])

    for entry in entries :
        file.store_csv_line(entry.to_csv_line())
    file.close()

static func load_csv() -> Array[DataEntry] :
    var entries : Array[DataEntry]
    var file = FileAccess.open(DATA_PATH, FileAccess.READ)
    
    if file == null :
        _create_default_csv() 
        file = FileAccess.open(DATA_PATH, FileAccess.READ)
    
    var _discard = file.get_csv_line()
    while not file.eof_reached():
        var line = file.get_csv_line()

        if line.size() != 3:
            continue

        entries.append(DataEntry.from_csv_line(line))
    
    file.close()
    return entries

static func _create_default_csv() -> void :
    var file = FileAccess.open(DATA_PATH, FileAccess.WRITE)
    file.store_csv_line(["category", "name", "value"])
    file.close()

static func add_or_edit_entry(entry : DataEntry) -> void :
    var current_entries = load_csv()

    for v in current_entries:
        if v.equals(entry):
            v.value = entry.value
            save_to_csv(current_entries)
            return
    
    current_entries.append(entry)
    save_to_csv(current_entries)

static func delete_entry(entry : DataEntry) -> void :
    var current_entries = load_csv()
    print_debug("Entries count before deletion : ", current_entries.size())

    for i in range(current_entries.size()):
        if current_entries[i].equals(entry):
            current_entries.remove_at(i)
            print_debug("Entries count efter deletion : ", current_entries.size())
            save_to_csv(current_entries)
            return

    print_debug("Delete request failed, entry not found : ", entry.category, " / ", entry.name)
    
    
static func sort_entries(entries: Array[DataEntry]) -> void:
    entries.sort_custom(func(a: DataEntry, b: DataEntry) -> bool:
        if a.category != b.category:
            return a.category < b.category
        if a.name != b.name:
            return a.name < b.name
        return a.value > b.value
)

static func entry_exists(entry : DataEntry) -> bool:
    if entry == null:
        return false

    for data in load_csv():
        if data.equals(entry):
            return true

    return false

static func get_entry_real_value(entry : DataEntry) -> int :
    for data in load_csv():
        if data.equals(entry):
            return data.value
    return 0