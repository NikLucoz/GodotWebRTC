extends Control

func _ready() -> void:
	if not "--server" in OS.get_cmdline_args():
		MultiplayerController.visible = false
	else:
		self.visible = false

func _on_play_button_pressed() -> void:
	self.visible = false
	MultiplayerController.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()
