extends Node

signal cookies_updated
signal item_changed(scene: PackedScene)

var cookies: int = 0:
	set(value):
		cookies = value
		cookies_updated.emit()
