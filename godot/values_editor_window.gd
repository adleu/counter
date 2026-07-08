extends Window

@export var tree                : Tree
@export var app                 : window_handler
@export var delete_button       : Button
@export var add_value_button    : Button
@export var category_dropdown   : OptionButton 
@export var new_categorie_field : LineEdit

@export_category("Value")
@export var value_label         : Label
@export var link_button         : Button
@export var push_button         : Button
@export var button_link_data    : Button
@export var link_entry_color    : Color

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

    # value
    app.i_updated.connect(_on_app_value_changed)
    link_button.pressed.connect(_on_link_button_pressed)
    push_button.pressed.connect(_on_push_button_pressed)
    button_link_data.pressed.connect(_on_button_link_data_pressed)

    Config.link_entry_changed.connect(_update_label_link_entry)
    Config.link_entry_changed.connect(_tree_update_visual_link_entry)

    _update_label_link_entry(Config.get_link_entry())
    _update_link_button()
    _update_push_button()
    


## window
func _on_visibility_changed():
    if visible:
        grab_focus()
        popup_centered()
        refresh_datas(Config.get_last_visited_category())
        _update_delete_button_state()
        _on_app_value_changed()
    
func _on_close_requested():
    if not category_dropdown.get_item_id(category_dropdown.selected) == ADD_CATEGORY_ID :
        var selected_category =  category_dropdown.get_item_text(category_dropdown.selected)
        Config.set_last_visited_category(selected_category) 

    hide()
    all_entries = []
    category_dropdown.clear()
    tree.clear()

## value

func _on_app_value_changed()-> void :
    value_label.text = str(app.i)
    if not visible : 
        return
    
    # sync tree 
    var linked_entry = Config.get_link_entry()
    
    if linked_entry == null :
        return
    
    if category_dropdown.get_item_text(category_dropdown.selected) == linked_entry.category:
        var root = tree.get_root()

        if root == null :
            return

        var child = root.get_first_child()
        
        while child:
            if child.get_metadata(0).name == linked_entry.name:
                child.set_range(1, app.i)
                break

            child = child.get_next()

func _on_value_spinbox_changed(value : float) -> void:
    app.set_i(int(value))

func _update_label_link_entry(entry : DataEntry) :
    if entry == null :
        button_link_data.text = "No entry linked"
        button_link_data.disabled = true
        value_label.add_theme_color_override("font_color", Color.WHITE)
    else :
        button_link_data.text = "Linked to : [%s,%s]" % [entry.category, entry.name]
        button_link_data.disabled = false
        value_label.add_theme_color_override("font_color",link_entry_color)

func _update_link_button() -> void:
    var linked_entry = Config.get_link_entry()
    var selected_item = tree.get_selected()
    
    if selected_item == null:
        link_button.text = "Link Entry"
        link_button.disabled = true
        return
    
    var selected_entry: DataEntry = selected_item.get_metadata(0)
    
    if selected_entry == null :
        link_button.text = "Link Entry"
        link_button.disabled = true
        return

    var is_current_linked = linked_entry != null and selected_entry.equals(linked_entry)
    
    link_button.disabled = false
    link_button.text = "Unlink entry" if is_current_linked else "Link Entry"


func _on_link_button_pressed() -> void:
    var selected_item = tree.get_selected()
    if selected_item == null:
        return
    
    var selected_entry: DataEntry = selected_item.get_metadata(0)
    var linked_entry = Config.get_link_entry()
    
    if linked_entry != null and selected_entry.equals(linked_entry):
        Config.set_link_entry(null)
    else:
        Config.set_link_entry(selected_entry)
        app.set_i(DataHandler.get_entry_real_value(selected_entry))
    
    _update_link_button()

func _update_push_button() -> void:
    push_button.disabled = tree.get_selected() == null

func _on_push_button_pressed() -> void:
    var selected_item = tree.get_selected()
    if selected_item == null:
        return
    
    var selected_entry: DataEntry = selected_item.get_metadata(0)
    selected_entry.value = app.i
    
    DataHandler.add_or_edit_entry(selected_entry)
    
    selected_item.set_range(1, selected_entry.value)  

func _on_button_link_data_pressed()-> void :
    var linked_entry = Config.get_link_entry()

    if linked_entry == null :
        return

    if category_dropdown.get_item_text(category_dropdown.selected) != linked_entry.category:
        if not _try_select_category_in_dropdown(linked_entry.category):
            return

    var root = tree.get_root()

    if root == null :
        return

    var child = root.get_first_child()
    
    while child:
        if child.get_metadata(0).name == linked_entry.name:
            child.select(0)
            break

        child = child.get_next()



## datas
    
func refresh_datas(select_category_name: String = "") -> void :
    all_entries = DataHandler.load_csv()
    populate_category_dropdown(select_category_name)
    _on_category_selected(category_dropdown.selected)

func _on_tree_selection_changed() -> void:
    _update_delete_button_state()
    _update_link_button()
    _update_push_button()
    # var selected = tree.get_selected()
    # print("Selected : ", category_dropdown.get_item_text(category_dropdown.selected) ,selected.get_text(0), ",", selected.get_text(1), ",")

func _update_delete_button_state() -> void :
    delete_button.disabled = tree.get_selected() == null

func _on_delete_pressed() -> void:
    var selected = tree.get_selected()
    
    if selected == null:
        return

    if selected.get_next() != null:
        tree.set_selected(selected.get_next(), 0)

    var entry_to_delete = DataEntry.new(category_dropdown.get_item_text(category_dropdown.selected), selected.get_text(0))

    if entry_to_delete.equals(Config.get_link_entry()):
        Config.set_link_entry(null)

    DataHandler.delete_entry(entry_to_delete)


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
        if not _try_select_category_in_dropdown(select_name) :
            category_dropdown.select(0)
    elif category_dropdown.item_count > 0:
        category_dropdown.select(0)

func _try_select_category_in_dropdown(_name: String) -> bool:
    for i in category_dropdown.item_count:
        if category_dropdown.get_item_text(i) == _name:
            category_dropdown.select(i)
            _on_category_selected(i)
            return true
    return false

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
    _update_link_button()
    _update_push_button()

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
    add_value_button.disabled = false

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

    _tree_update_visual_link_entry(Config.get_link_entry())

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
        
        if old_entry.equals( Config.get_link_entry()) :
            Config.set_link_entry(new_entry)
    else : #value
        old_entry.value = int(item.get_range(1))
        DataHandler.add_or_edit_entry(old_entry)
        if Config.get_link_entry().equals(old_entry) :
            app.set_i(int(item.get_range(1)))
    

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

func _tree_update_visual_link_entry(linked_entry : DataEntry) -> void :
    if linked_entry != null:
        if category_dropdown.get_item_text(category_dropdown.selected) != linked_entry.category :
            return

    var root = tree.get_root()
    var child = root.get_first_child()
    while child :
        if linked_entry != null and child.get_text(0) == linked_entry.name :
            child.set_custom_color(0, link_entry_color)
            child.set_custom_color(1, link_entry_color)
        else :
            child.set_custom_color(0, Color.WHITE)
            child.set_custom_color(1, Color.WHITE)
            
        child = child.get_next()
    

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