extends HBoxContainer
@onready var lobby_id_label: Label = $LobbyIdLabel
@onready var lobby_n_of_players_label: Label = $LobbyNOfPlayersLabel
@onready var join_lobby_button: Button = $Control/JoinLobbyButton

var lobby_id: String = ""
var lobby_player_count: int = 0

func _ready() -> void:
	lobby_id_label.text = lobby_id
	lobby_n_of_players_label.text = str(lobby_player_count) + "/2"
	
	if lobby_player_count >= 2:
		join_lobby_button.disabled = true

signal _on_lobby_selected(lobby_id: String)

func _on_join_lobby_button_pressed() -> void:
	_on_lobby_selected.emit(lobby_id_label.text)
