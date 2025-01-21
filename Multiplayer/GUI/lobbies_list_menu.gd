extends VBoxContainer

@onready var lobby_show_container: VBoxContainer = $ScrollContainer/LobbyShowContainer
const LOBBY_SHOW_ITEM = preload("res://Multiplayer/GUI/lobby_show_item.tscn")
var available_lobbies: Dictionary = {}

signal lobby_join_pressed(lobby_id: String)

func update_lobby_items() -> void:
	for c in lobby_show_container.get_children():
		c.queue_free()
	
	for al in available_lobbies:
		var lobby = available_lobbies[al]
		var instance = LOBBY_SHOW_ITEM.instantiate()
		instance.lobby_id = lobby.id
		var lobby_players: Dictionary = JSON.parse_string(lobby.players)
		instance.lobby_host_name = lobby_players[str(lobby.host_id)].player_data.name
		instance.lobby_player_count = lobby.player_count
		instance.get_node("Control/JoinLobbyButton").connect("pressed", _on_lobby_selected.bind(lobby.id))
		lobby_show_container.add_child(instance)

func _on_lobby_selected(lobby_id: String) -> void:
	lobby_join_pressed.emit(lobby_id)
