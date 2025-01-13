class_name Lobby
extends RefCounted

var host_id: int
var players: Dictionary = {}

func _init(id: int) -> void:
	host_id = id

func add_player(id: int, player_data: Dictionary = {}) -> Dictionary:
	players[id] = {
		"id": id,
		"player_data": player_data,
		"index": players.size() + 1
	}
	
	return players[id]
