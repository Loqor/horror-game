extends Node3D

var paused = false;
@onready var flashlight = $flashlight

# Called when the node enters the scene tree for the first time.
func _process(delta):
	if Input.is_action_just_pressed("flashlight"):
		toggleFlashlight()

func toggleFlashlight():
	if paused:
		flashlight.hide()
	else:
		flashlight.show()
	paused = !paused
