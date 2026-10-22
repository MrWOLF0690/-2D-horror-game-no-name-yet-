extends CanvasLayer

@onready var pill_label: Label = $PillLabel

func _ready():
	Inventory.inventory_changed.connect(func(_id, _n): _refresh())
	Inventory.hotkey_changed.connect(func(_id): _refresh())
	_refresh()
	
func _on_inventory_changed(_item_id, _count):
	_refresh()

func _refresh():
	pill_label.text = "Sanity-Pills: %d (%s)" % [Inventory.get_count("sanity_pill"), Inventory.get_hotkey_text("sanity_pill")]
