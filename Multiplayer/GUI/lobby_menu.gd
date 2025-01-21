extends Panel

var lobby_id: String
var host_id: int
var players: Dictionary
@onready var lobby_id_label: Label = $MarginContainer/container/lobbyIdLabel
@onready var lobby_host_id_label: Label = $MarginContainer/container/lobbyHostIdLabel
@onready var lobby_players_label: Label = $MarginContainer/container/lobbyPlayersLabel
@onready var start_game_button: Button = $MarginContainer/container/Control/StartGameButton

func update_lobby_ui(peer_id: int):
	if peer_id != host_id:
		start_game_button.disabled = true
		
	lobby_id_label.text = "Lobby id: " + lobby_id
	lobby_host_id_label.text = "Host id: " + str(host_id)
	lobby_players_label.text = ""
	
	for p in players:
		var player = players[p]
		if player.id == host_id:
			lobby_players_label.text += "Host: " + str(player.player_data.name) + "\n"
		else:
			lobby_players_label.text += "Player: " + str(player.player_data.name) + "\n"
