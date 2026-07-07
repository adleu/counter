extends Window

@export var tree                : Tree
@export var app                 : window_handler
@export var delete_button       : Button
@export var add_value_button    : Button
@export var category_dropdown   : OptionButton 
@export var new_categorie_field : LineEdit

const ADD_CATEGORY_ID = -1

var is_open : bool :
    get:
        return visible

var all_entries  : Array[DataEntry]
var pending_category : String = ""

func _ready():
    #window
    hide()
    visibility_changed.connect(_on_visibility_changed)
    close_requested.connect(_on_close_requested)

    # tree
    tree.set_column_title(0, "Name")
    tree.set_column_title(1, "Value")
    tree.item_edited.connect(_on_item_edited)
    tree.item_selected.connect(_on_tree_selection_changed)
    tree.nothing_selected.connect(_on_tree_selection_changed)

    #dropdown
    new_categorie_field.hide()
    new_categorie_field.text_submitted.connect(_on_new_category_submitted)
    new_categorie_field.focus_exited.connect(_on_new_category_cancelled)
    category_dropdown.item_selected.connect(_on_category_selected)

    # butttons
    delete_button.pressed.connect(_on_delete_pressed)
    add_value_button.pressed.connect(_on_add_value_pressed)


## window
func _on_visibility_changed():
    if visible:
        grab_focus()
        popup_centered()
        refresh_datas()
        _update_delete_button_state()
    
func _on_close_requested():
    hide()
    all_entries = []
    category_dropdown.clear()
    tree.clear()

## datas
    
func refresh_datas(select_category_name: String = "") -> void :
    all_entries = DataHandler.load_csv()
    populate_category_dropdown(select_category_name)
    _on_category_selected(category_dropdown.selected)


func _on_tree_selection_changed() -> void:
    _update_delete_button_state()
    # var selected = tree.get_selected()
    # print("Selected : ", category_dropdown.get_item_text(category_dropdown.selected) ,selected.get_text(0), ",", selected.get_text(1), ",")

func _update_delete_button_state() -> void :
    delete_button.disabled = tree.get_selected() == null

func _on_delete_pressed() -> void:
    var selected = tree.get_selected()
    
    if selected == null:
        return

    print("Delete request : ", category_dropdown.get_item_text(category_dropdown.selected), ",", selected.get_text(0))

    if(selected.get_next() != null):
        tree.set_selected(selected.get_next(), 0)

    DataHandler.delete_entry(DataEntry.new(category_dropdown.get_item_text(category_dropdown.selected), selected.get_text(0)))
    selected.free()

    if get_tree_item_count() == 0:
        refresh_datas()

## dropdown category

func populate_category_dropdown(select_name: String = "") -> void :
    category_dropdown.clear()

    var categories : Array[String] = []
    for entry in all_entries:
        if not categories.has(entry.category):
            categories.append(entry.category)
    
    if not pending_category.is_empty():
         categories.append(pending_category)
         pending_category = ""
    
    categories.sort()


    for category in categories:
        category_dropdown.add_item(category)

    category_dropdown.add_item("+ Add...")
    category_dropdown.set_item_id(category_dropdown.item_count - 1, ADD_CATEGORY_ID)

    if not select_name.is_empty():
        _select_category_in_dropdown(select_name)
    elif category_dropdown.item_count > 0:
        category_dropdown.select(0)

func _select_category_in_dropdown(_name: String) -> void:
    for i in category_dropdown.item_count:
        if category_dropdown.get_item_text(i) == _name:
            category_dropdown.select(i)
            _on_category_selected(i)
            return

func _on_category_selected(index : int) -> void :
    if index + 1 > category_dropdown.item_count  or index < 0:
        return

    add_value_button.disabled  = category_dropdown.get_item_id(index)  ==  ADD_CATEGORY_ID

    if category_dropdown.get_item_id(index) ==  ADD_CATEGORY_ID: # add
        _start_add_category()
        return 

    var selected_category = category_dropdown.get_item_text(index)
    var filtered = all_entries.filter(func(e): return e.category == selected_category)
    _populate_tree(filtered)

func _start_add_category() -> void :
    new_categorie_field.text = ""
    category_dropdown.hide()
    new_categorie_field.show()
    new_categorie_field.grab_focus()

func _on_new_category_submitted(text: String) :
    var _name = text.strip_edges()
    _end_add_category_input()

    if _name.is_empty() and all_entries.size() == 0:
        return

    if _name.is_empty():
        populate_category_dropdown() 
        return
    
    pending_category = _name
    populate_category_dropdown(_name)
    _on_category_selected(category_dropdown.selected)
    _end_add_category_input()
    

func _on_new_category_cancelled() -> void:
    if new_categorie_field.visible:
        if new_categorie_field.text.is_empty() and all_entries.size() == 0:
            return
        _end_add_category_input()
        populate_category_dropdown()
        

func _end_add_category_input() -> void:
    new_categorie_field.hide()
    category_dropdown.show()

### tree

func _populate_tree(entries : Array[DataEntry]) -> void:
    tree.clear()
    var root = tree.create_item()

    for entry in entries:
        var item = tree.create_item(root)
        item.set_text(0, entry.name)
        # item.set_text(1, str(entry.value))
        
        item.set_editable(0, true)
        item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
        item.set_range_config(1, 0, 999999, 1)
        item.set_range(1, entry.value)
        item.set_editable(1, true)

        item.set_metadata(0, entry)

        item.set_selectable(1, true)
        item.set_selectable(0, true)

func _on_item_edited() -> void:
    
    var item = tree.get_edited()
    var column = tree.get_edited_column()
    var old_entry = item.get_metadata(0)

    if old_entry == null: # this is a new line edited for the first time 
        var _name = item.get_text(0).strip_edges()

        if _name.is_empty():
            return  
        
        var current_category = category_dropdown.get_item_text(category_dropdown.selected)
        var new_entry = DataEntry.new(current_category, _name, int(item.get_range(1)))

        item.set_metadata(0, new_entry)
        DataHandler.add_or_edit_entry(new_entry)
        refresh_datas(current_category)
        return

    if column == 0 : # name
        var new_name = item.get_text(0).strip_edges()
        var new_entry = DataEntry.new(old_entry.category, new_name, old_entry.value)
        DataHandler.delete_entry(old_entry)
        DataHandler.add_or_edit_entry(new_entry)
        item.set_metadata(0, new_entry)
    else : #value
        old_entry.value = int(item.get_range(1))
        DataHandler.add_or_edit_entry(old_entry)

func _on_add_value_pressed() :
    var root = tree.get_root()
    if root == null:
        root = tree.create_item()  
    
    var item = tree.create_item(root)
    item.set_text(0, "")
    item.set_editable(0, true)
    
    item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
    item.set_range_config(1, 0, 999999, 1)
    item.set_range(1, 0)
    item.set_editable(1, true)
    
    item.set_metadata(0, null)
    
    tree.set_selected(item, 0)
    tree.edit_selected.call_deferred() 

## utils

func get_tree_item_count() -> int:
    var root = tree.get_root()
    if root == null:
        return 0
    
    var count = 0
    var child = root.get_first_child()
    while child != null:
        count += 1
        child = child.get_next()
    
    return count