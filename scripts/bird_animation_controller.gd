extends Node

# References
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var bird_controller = $"../.."

# Animation settings
@export var fly_animation: String = "fly"
@export var flap_animation: String = "flap"
@export var dive_animation: String = "dive"
@export var drift_animation: String = "drift"

# State tracking
var is_diving: bool = false
var is_flapping: bool = false

func _ready():
	# Connect signals from the bird controller
	if bird_controller:
		bird_controller.bird_flapped.connect(_on_bird_flapped)
		bird_controller.bird_dived.connect(_on_bird_dived)
	
	# Start with the drift animation by default
	if animation_player:
		animation_player.play(drift_animation)
		animation_player.set_active(true)

func _on_bird_flapped():
	# If not already flapping, play the flap animation once
	if animation_player and !is_flapping:
		is_flapping = true
		
		# Stop current animation and play the flap animation
		animation_player.stop()
		animation_player.play(flap_animation)
		
		# After flap animation finishes, go back to drift
		await animation_player.animation_finished
		
		# Resume the drift animation and reset state
		animation_player.play(drift_animation)
		is_flapping = false

func _on_bird_dived():
	if animation_player and !is_flapping:
		animation_player.play(dive_animation)
		is_diving = true
		
		# Return to drift animation after dive completes
		await animation_player.animation_finished
		animation_player.play(drift_animation)
		is_diving = false
