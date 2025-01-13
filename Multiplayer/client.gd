extends MultiplayerObject

var id: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var data_string = packet.get_string_from_utf8()
			var data = JSON.parse_string(data_string)
			
			if data.message == Message.id:
				id = data.data.id

func connect_to_server(ip: String) -> void:
	peer.create_client("ws://127.0.0.1:8915")
	print("client started and connected")

func _on_send_packet_pressed() -> void:
	var data = {
		"message": Message.join,
		"data": "test"
	}
	send_packet(data)


func _on_start_client_pressed() -> void:
	connect_to_server("")
