extends MultiplayerObject

var id: int = 0
var rtc_peer: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var host_id: int
var lobby_id = ""
var available_lobbies: Dictionary = {}

@onready var start_action_menu: HBoxContainer = $"../Menu/StartActionMenu"
@onready var lobbies_list_menu: VBoxContainer = $"../Menu/LobbiesListMenu"

@onready var lobby_id_edit: LineEdit = $"../LobbyIdEdit"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_rtc_server_connected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if not ("--server" in OS.get_cmdline_args()):
		if "--testing" in OS.get_cmdline_args():
			setup_client("ws://127.0.0.1:8915")
		else:
			setup_client()
	else:
		start_action_menu.visible = false
		lobbies_list_menu.visible = false

func setup_client(server_ip: String = ""):
	connect_to_server(server_ip)
	
	start_action_menu.visible = true
	lobbies_list_menu.visible = false
	lobbies_list_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobbies_list_menu.lobby_join_pressed.connect(_on_join_lobby_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)
			
			if data.message == Message.id:
				id = data.data.id
				connected(id)
				#Ask the server all the lobbies open
				send_packet({
					"message": Message.lobbiesData,
					"id": id
				})
			
			if data.message == Message.userConnected:
				create_peer(data.id)
			
			if data.message == Message.lobbiesData:
				available_lobbies = JSON.parse_string(data.available_lobbies)
				lobbies_list_menu.available_lobbies = available_lobbies
				lobbies_list_menu.update_lobby_items()
			
			# lobby data sync
			if data.message == Message.lobby:
				#Pass the data to the GameManager to syncronize all the player_data across the peers
				lobby_id = data.lobby_id
				print(lobby_id)
				host_id = data.host
				
			if data.message == Message.candidate:
				if rtc_peer.has_peer(data.org_peer):
					print("Got Candidate: " + str(data.org_peer) + " my id is " + str(id))
					rtc_peer.get_peer(data.org_peer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Message.offer:
				if rtc_peer.has_peer(data.org_peer):
					rtc_peer.get_peer(data.org_peer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.answer:
				if rtc_peer.has_peer(data.org_peer):
					rtc_peer.get_peer(data.org_peer).connection.set_remote_description("answer", data.data)

func connect_to_server(ip: String = "ws://172.31.192.73:8915") -> void:
	peer.create_client(ip)
	print("client started and connected")

func _on_rtc_server_connected():
	print("RTC Server connected")

func _on_peer_connected(id):
	print("RTC Peer connected " + str(id))

func _on_peer_disconnected(id):
	print("RTC Peer disconnected " + str(id))

func connected(id) -> void:
	rtc_peer.create_mesh(id)
	multiplayer.multiplayer_peer = rtc_peer

@rpc("any_peer")
func ping():
	print("Ping from " + str(multiplayer.get_remote_sender_id()))

# web rtc connection
func create_peer(user_id) -> void:
	if user_id != id:
		var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [
				{ 
					"urls" : [ "stun:stun.l.google.com:19302" ]
				}
			]
		})
		
		print("Binding id " + str(user_id) + " my id is " + str(id))
		peer.session_description_created.connect(self._on_offer_created.bind(user_id))
		peer.ice_candidate_created.connect(self._ice_candidate_created.bind(user_id))
		rtc_peer.add_peer(peer, int(user_id))
		
		if !host_id == self.id:
			peer.create_offer()

func _on_offer_created(type, data, id) -> void:
	if not rtc_peer.has_peer(id):
		return
	
	rtc_peer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		send_offer(id, data)
	else:
		send_answer(id, data)

func send_offer(id, data) -> void:
	var message = {
		"id": id,
		"org_peer": self.id,
		"message" : Message.offer,
		"data": data,
		"lobby": lobby_id
	}
	
	send_packet(message)

func send_answer(id, data) -> void:
	var message = {
		"id": id,
		"org_peer": self.id,
		"message" : Message.answer,
		"data": data,
		"lobby": lobby_id
	}
	
	send_packet(message)

func _ice_candidate_created(mid_name, index_name, sdp_name, id) -> void:
	var message = {
		"id": id,
		"org_peer": self.id,
		"message" : Message.candidate,
		"mid": mid_name,
		"index": index_name,
		"sdp": sdp_name,
		"lobby": lobby_id
	}
	
	send_packet(message)

# UI FUNCTIONS

func _on_send_packet_pressed() -> void:
	ping.rpc()

func _on_join_lobby_pressed(lobby_id: String = "") -> void:
	var message = {
		"id": id,
		"message": Message.lobby,
		"lobby_id": lobby_id
	}
	
	send_packet(message)

func _on_host_game_pressed() -> void:
	var message = {
		"id": id,
		"message": Message.lobby,
		"lobby_id": ""
	}
	
	send_packet(message)

func _on_open_lobbies_menu_pressed() -> void:
	start_action_menu.visible = false
	start_action_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobbies_list_menu.visible = true
	lobbies_list_menu.mouse_filter = Control.MOUSE_FILTER_PASS
