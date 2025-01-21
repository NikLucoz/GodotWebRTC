class_name MultiplayerObject
extends Node

enum Message {
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	lobbiesData,
	candidate,
	offer,
	answer
}

var characters = "abcdefghilmnopqrstuvwxyzABCDEFGHILMNOPQRSTUVWXYZ1234567890"

var peer = WebSocketMultiplayerPeer.new()

func generate_random_id() -> String:
	var res = ""
	for i in range(32):
		var random_index: int = randi() % characters.length()
		res += characters[random_index]
	return res

func send_packet(data: Dictionary) -> void:
	peer.put_packet(JSON.stringify(data).to_utf8_buffer())

func send_packet_to_peer(id: int, data: Dictionary) -> void:
	peer.get_peer(id).put_packet(JSON.stringify(data).to_utf8_buffer())
