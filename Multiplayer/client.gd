extends MultiplayerObject

var id: int = 0
var rtc_peer = WebRTCMultiplayerPeer.new()
var host_id: int
var lobby_id: String = ""
var available_lobbies: Dictionary = {}
var player_data: PlayerData = null

@export var game_scene: PackedScene
@onready var start_action_menu: VBoxContainer = $"../Menu/StartActionMenu"
@onready var lobbies_list_menu: VBoxContainer = $"../Menu/LobbiesListMenu"
@onready var lobby_menu: Panel = $"../Menu/LobbyMenu"
@onready var player_option_menu: VBoxContainer = $"../Menu/PlayerOptionMenu"

func _ready() -> void:
	player_data = PlayerData.new()
	setup_signals()
	setup_client() if not ("--server" in OS.get_cmdline_args()) else setup_server_ui()

func setup_signals() -> void:
	multiplayer.connected_to_server.connect(_on_rtc_server_connected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	player_option_menu._change_player_data.connect(_on_player_data_changed)
	lobbies_list_menu.lobby_join_pressed.connect(_on_join_lobby_pressed)

func setup_server_ui() -> void:
	start_action_menu.visible = false
	lobbies_list_menu.visible = false

func setup_client(server_ip: String = "") -> void:
	connect_to_server(server_ip)
	start_action_menu.visible = true
	lobbies_list_menu.visible = false
	lobby_menu.visible = false
	lobbies_list_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet:
			handle_packet(JSON.parse_string(packet.get_string_from_utf8()))

func handle_packet(data: Dictionary) -> void:
	if data.message == Message.id:
		id = data.data.id
		player_data.name = "player" + str(id)
		player_option_menu.update_menu()
		connected(id)
		send_packet({"message": Message.lobbiesData, "id": id})
	elif data.message == Message.userConnected:
		create_peer(data.id)
	elif data.message == Message.lobbiesData:
		update_lobbies_list(data.available_lobbies)
	elif data.message == Message.lobby:
		GameManager.players = JSON.parse_string(data.lobby_players)
		sync_lobby_data(data)
	elif data.message == Message.candidate:
		if rtc_peer.has_peer(data.org_peer):
			print("Got Candidate: " + str(data.org_peer) + " my id is " + str(id))
			rtc_peer.get_peer(data.org_peer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
	elif data.message == Message.offer:
		if rtc_peer.has_peer(data.org_peer):
			rtc_peer.get_peer(data.org_peer).connection.set_remote_description("offer", data.data)
	elif data.message == Message.answer:
		if rtc_peer.has_peer(data.org_peer):
			rtc_peer.get_peer(data.org_peer).connection.set_remote_description("answer", data.data)

func update_lobbies_list(lobbies_json: String) -> void:
	available_lobbies = JSON.parse_string(lobbies_json)
	lobbies_list_menu.available_lobbies = available_lobbies
	lobbies_list_menu.update_lobby_items()

func sync_lobby_data(data: Dictionary) -> void:
	lobby_id = data.lobby_id
	host_id = data.host
	lobby_menu.lobby_id = lobby_id
	lobby_menu.host_id = host_id
	lobby_menu.players = JSON.parse_string(data.lobby_players)
	lobby_menu.update_lobby_ui(id)
	lobby_menu.visible = true
	start_action_menu.visible = false
	lobbies_list_menu.visible = false

func connect_to_server(ip: String) -> void:
	var config = ConfigFile.new()
	if config.load("res://global.ini") != OK:
		push_error("Global config file not found")
		return

	ip = "ws://127.0.0.1:8915" if "--testing" in OS.get_cmdline_args() else config.get_value("SERVER", "SERVER_IP")

	peer.create_client(ip)
	print("Client started and connected")

func _on_rtc_server_connected():
	print("RTC Server connected")

func _on_peer_connected(peer_id: int):
	print("RTC Peer connected", peer_id)

func _on_peer_disconnected(peer_id: int):
	print("RTC Peer disconnected", peer_id)

func connected(peer_id: int) -> void:
	rtc_peer.create_mesh(peer_id)
	multiplayer.multiplayer_peer = rtc_peer

@rpc("any_peer")
func ping():
	print("Ping from " + str(multiplayer.get_remote_sender_id()) + " to " + str(id))

func create_peer(user_id: int) -> void:
	if user_id == id:
		return
	var peer = WebRTCPeerConnection.new()
	peer.initialize({"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]})
	peer.session_description_created.connect(_on_offer_created.bind(user_id))
	peer.ice_candidate_created.connect(_ice_candidate_created.bind(user_id))
	rtc_peer.add_peer(peer, user_id)
	if host_id != id:
		peer.create_offer()

func _on_offer_created(type: String, data: String, user_id: int) -> void:
	if not rtc_peer.has_peer(user_id):
		return
	rtc_peer.get_peer(user_id).connection.set_local_description(type, data)
	if type == "offer":
		send_offer(user_id, data)
	else:
		send_answer(user_id, data)

func send_offer(user_id: int, data: String) -> void:
	send_packet({"id": user_id, "org_peer": id, "message": Message.offer, "data": data, "lobby": lobby_id})

func send_answer(user_id: int, data: String) -> void:
	send_packet({"id": user_id, "org_peer": id, "message": Message.answer, "data": data, "lobby": lobby_id})

func _ice_candidate_created(mid: String, index: int, sdp: String, user_id: int) -> void:
	send_packet({"id": user_id, "org_peer": id, "message": Message.candidate, "mid": mid, "index": index, "sdp": sdp, "lobby": lobby_id})

# UI FUNCTIONS
func _on_join_lobby_pressed(lobby_id: String = "") -> void:
	send_packet({"id": id, "message": Message.lobby, "player_data": player_data.get_as_dictionary(), "lobby_id": lobby_id})

func _on_host_game_pressed() -> void:
	send_packet({"id": id, "message": Message.lobby, "player_data": player_data.get_as_dictionary(), "lobby_id": ""})

func _on_open_lobbies_menu_pressed() -> void:
	start_action_menu.visible = false
	start_action_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lobbies_list_menu.visible = true
	lobbies_list_menu.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_player_data_changed(data: PlayerData) -> void:
	player_data = data
	player_option_menu.visible = false
	start_action_menu.visible = true

func _on_open_player_option_menu_pressed() -> void:
	player_option_menu.visible = true
	start_action_menu.visible = false

func _on_start_game_button_pressed() -> void:
	print("Host started game")
	start_game.rpc()
	
@rpc("any_peer", "call_local", "reliable")
func start_game():
	send_packet({
		"message": Message.removeLobby,
		"lobby_id": lobby_id
	})
	
	get_parent().visible = false
	await SceneManager.change_scene(game_scene, {
		"pattern_enter": "scribbles",
		"pattern_leave": "scribbles",
	})
