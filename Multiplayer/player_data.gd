class_name PlayerData
extends Resource

var name: String

func get_as_dictionary() -> Dictionary:
	return {
		"name": name
	}
