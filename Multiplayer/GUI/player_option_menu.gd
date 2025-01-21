extends VBoxContainer

@onready var player_name_text_edit: TextEdit = $HBoxContainer/PlayerNameTextEdit
signal _change_player_data(player_data: PlayerData)
var player_data: PlayerData

func _ready() -> void:
	player_data = PlayerData.new()

func update_menu() -> void:
	player_name_text_edit.text = player_data.name

func _on_save_button_pressed() -> void:
	player_data.name = player_name_text_edit.text
	_change_player_data.emit(player_data)
