extends MultiplayerObject

var users: Dictionary = {}
var lobbies: Dictionary = {}
@export var host_port: int = 8915

func _init() -> void:
	if "--server" in OS.get_cmdline_args():
		print("Hosting on " + str(host_port))
		peer.create_server(host_port)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	peer.connect("peer_connected", _on_peer_connected)
	peer.connect("peer_disconnected", _on_peer_disconnected)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)
			
			if data.message == Message.lobby:
				join_lobby(data.id, data.lobby_id, data.player_data)
			
			if data.message == Message.lobbiesData:
				var message = {
					"message": Message.lobbiesData,
					"available_lobbies": JSON.stringify(lobbies)
				}
				send_packet_to_peer(data.id, message)
			
			if data.message == Message.offer || data.message == Message.answer || data.message == Message.candidate:
				print("source id is" + str(data.org_peer))
				send_packet_to_peer(data.id, data)
			
			if data.message == Message.removeLobby:
				if lobbies.has(data.lobby_id):
					print("Game started, lobby removed")
					lobbies.erase(data.lobby_id)

func start_server() -> void:
	peer.create_server(host_port)
	print("Server started")

func join_lobby(user_id, lobby_id, player_data: Dictionary) -> void:
	var config = ConfigFile.new()
	var err = config.load("res://global.ini")
	
	# If the file didn't load, ignore it.
	if err != OK:
		return
	
	if lobby_id == "":
		lobby_id = generate_random_id()
		lobbies[lobby_id] = Lobby.new(user_id)
	
	
	if lobbies[lobby_id].players.size() >= int(config.get_value("LOBBY", "MAX_LOBBY_SIZE")):
		push_warning("Cannot fit player inside this lobby, it's full")
		return

	var player = lobbies[lobby_id].add_player(user_id, player_data)

	# When a new lobby is created the server signal all the peer that a new lobby is present giving them the updated list
	var lobbies_data = {}
	for id in lobbies:
		lobbies_data[id] = {
			"id": id,
			"host_id": lobbies[id].host_id,
			"players": JSON.stringify(lobbies[id].players),
			"player_count": str(lobbies[id].players.size())
		}
	
	send_packet({
		"message": Message.lobbiesData,
		"available_lobbies": JSON.stringify(lobbies_data)
	})

	
	for p in lobbies[lobby_id].players:
		var data = {
			"message": Message.userConnected,
			"id": user_id
		}
		send_packet_to_peer(p, data)
		
		var data2 = {
			"message": Message.userConnected,
			"id": p
		}
		send_packet_to_peer(user_id, data2)
		
		var lobby_info = {
			"message" : Message.lobby,
			"lobby_players": JSON.stringify(lobbies[lobby_id].players),
			"host": lobbies[lobby_id].host_id,
			"lobby_id": lobby_id 
		}
		send_packet_to_peer(p, lobby_info)
	
	var data = {
		"message": Message.userConnected,
		"id": user_id,
		"host": lobbies[lobby_id].host_id,
		"player": player,
		"lobby_id": lobby_id 
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
