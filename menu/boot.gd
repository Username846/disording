extends Node
## Main scene: loads the menu audio and hands over to the title screen.


func _ready() -> void:
	var request := Bundles.request("menu")
	request.done.connect(func(bundle: AudioBundle) -> void: Audio.ui_bundle = bundle)
	Router.current = self
	Router.goto_title()
