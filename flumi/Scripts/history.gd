extends MarginContainer

@onready var history_entry_container: VBoxContainer = $Main/PanelContainer2/ScrollContainer/HistoryEntryContainer
@onready var delete_menu: PanelContainer = $Main/DeleteMenu
@onready var line_edit: LineEdit = $Main/LineEdit
@onready var entries_label: RichTextLabel = $Main/DeleteMenu/HBoxContainer/RichTextLabel
@onready var cancel_button: Button = $Main/DeleteMenu/HBoxContainer/CancelButton

var toggled_entries = []

func _ready():
	for entry in history_entry_container.get_children():
		entry.connect("checkbox_toggle", history_toggle.bind(entry))

func history_toggle(toggled: bool, entry) -> void:
	print('toggling ', entry, ' to :', toggled)
	if toggled:
		toggled_entries.append(entry)
	else:
		toggled_entries.remove_at(toggled_entries.find(entry))
	
	entries_label.text = str(toggled_entries.size()) + " selected"
	
	if toggled_entries.size() != 0:
		delete_menu.show()
		line_edit.hide()
	else:
		delete_menu.hide()
		line_edit.show()

func _on_cancel_button_pressed() -> void:
	var entries_to_reset = toggled_entries.duplicate()
	toggled_entries.clear()
	
	for entry in entries_to_reset:
		entry.reset()
	
	delete_menu.hide()
	line_edit.show()
