extends HBoxContainer
@onready var lobby_id_label: Label = $LobbyIdLabel
@onready var lobby_n_of_players_label: Label = $LobbyNOfPlayersLabel
@onready var join_lobby_button: Button = $Control/JoinLobbyButton

var lobby_id: String = ""
var lobby_host_name: String = ""
var lobby_player_count: int = 0

func _ready() -> void:
	var config = ConfigFile.new()
	var err = config.load("res://global.ini")

	# If the file didn't load, ignore it.
	if err != OK:
		return

	lobby_id_label.text = lobby_host_name + "'s lobby"
	lobby_n_of_players_label.text = str(lobby_player_count) + "/" + str(config.get_value("LOBBY", "MAX_LOBBY_SIZE"))
	
	if lobby_player_count >= int(config.get_value("LOBBY", "MAX_LOBBY_SIZE")):
		join_lobby_button.disabled = true

signal _on_lobby_selected(lobby_id: String)

func _on_join_lobby_button_pressed() -> void:
	_on_lobby_selected.emit(lobby_id_label.text)
