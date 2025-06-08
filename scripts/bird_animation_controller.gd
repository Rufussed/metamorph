extends Node

# References
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var bird_controller = $"../.."

# Animation settings
@export var fly_animation: String = "fly"
@export var flap_animation: String = "flap"
@export var dive_animation: String = "dive"

# State tracking
var is_diving: bool = false
var is_flapping: bool = false

func _ready():
	# Connect signals from the bird controller
	if bird_controller:
		bird_controller.bird_flapped.connect(_on_bird_flapped)
		bird_controller.bird_dived.connect(_on_bird_dived)
	
	# Start with the fly animation looping
	if animation_player:
		animation_player.play(fly_animation)
		animation_player.set_active(true)

func _on_bird_flapped():
	if animation_player and !is_diving:
		animation_player.play(flap_animation)
		is_flapping = true
		
		# Return to fly animation after flap completes
		await animation_player.animation_finished
		if !is_diving:
			animation_player.play(fly_animation)
			is_flapping = false

func _on_bird_dived():
	if animation_player and !is_flapping:
		animation_player.play(dive_animation)
		is_diving = true
		
		# Return to fly animation after dive completes
		await animation_player.animation_finished
		animation_player.play(fly_animation)
		is_diving = false
