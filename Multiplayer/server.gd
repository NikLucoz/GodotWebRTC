extends MultiplayerObject

var users: Dictionary = {}
var lobbies: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	peer.connect("peer_connected", _on_peer_connected)
	peer.connect("peer_disconnected", _on_peer_disconnected)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)

func start_server() -> void:
	peer.create_server(8915)
	print("Server started")

func join_lobby(user_id, lobby_id) -> void:
	if lobby_id == "":
		lobby_id = generate_random_id()
		lobbies[lobby_id] = Lobby.new(user_id)
	
	var player = lobbies[lobby_id].add_player(user_id)
	
	var data = {
		"message": Message.userConnected,
		"id": user_id,
		"host": lobbies[lobby_id].host_id,
		"player": lobbies[lobby_id].players[user_id]
	}
	
	send_packet_to_peer(user_id, data)

func _on_peer_connected(id) -> void:
	print("Peer connected to server: " + str(id))
	users[id] = {
		"id": id
	}
	
	var data = {
		"message": Message.id,
		"data": users[id]
	}
	
	send_packet_to_peer(id, data)
	

func _on_peer_disconnected(id) -> void:
	print("Peer disconnected from server: " + str(id))

func _on_start_server_pressed() -> void:
	start_server()
