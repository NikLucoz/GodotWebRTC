class_name Player
extends RefCounted

var id: int
var name: String

func _init(id: int, name: String) -> void:
	self.id = id
	self.name = name
