extends CanvasLayer
@onready var money_label: Label = %MoneyLabel

func _ready() -> void:
	Global.cookies_updated.connect(update_money_label)


func update_money_label() -> void:
	money_label.text = "$" + str(Global.cookies)
