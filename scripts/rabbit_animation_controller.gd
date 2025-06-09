extends Node

# References
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var player_controller = $"../.."

# Animation settings
@export var hop_animation: String = "hop"
@export var jump_pause_frame: float = 0.4  # Point in animation to pause at (0-1)
@export var double_jump_speed_factor: float = 2.0  # Animation speed multiplier for double jumps
@export var animation_speed_factor: float = 1.0  # General animation speed factor

# State tracking
var is_jumping: bool = false

func _ready():
	# Connect signals from the player controller
	if player_controller:
		player_controller.player_jumped.connect(_on_player_jumped)
		player_controller.player_landed.connect(_on_player_landed)
	
	# Start with the hop animation looping
	if animation_player:
		animation_player.play(hop_animation)
		animation_player.speed_scale = animation_speed_factor
		animation_player.set_active(true)

func _on_player_jumped(is_double_jump = false):
	is_jumping = true
	
	if animation_player:
		if is_double_jump:
			# For double jump: play from pause point to end, then from start to pause point, at double speed
			animation_player.play(hop_animation)
			
			var anim_length = animation_player.current_animation_length
			var start_position = anim_length * jump_pause_frame
			
			# Set playback speed to the configurable factor (with general factor applied)
			animation_player.speed_scale = double_jump_speed_factor * animation_speed_factor
			
			# Start from the pause point (0.4)
			animation_player.seek(start_position)
			
			# Calculate time to complete the animation from 0.4 to end, then from 0 to 0.4
			# Time adjusted based on the speed factor
			var time_to_end = (1.0 - jump_pause_frame) * anim_length / double_jump_speed_factor
			var time_to_next_pause = jump_pause_frame * anim_length / double_jump_speed_factor
			var total_time = time_to_end + time_to_next_pause
			
			# Create a custom timer to handle the animation sequence
			var timer = get_tree().create_timer(time_to_end)
			timer.timeout.connect(_on_double_jump_animation_restart)
			
			# Create a timer for the final pause
			var pause_timer = get_tree().create_timer(total_time)
			pause_timer.timeout.connect(_pause_jump_animation)
		else:
			# Normal jump: play from beginning at normal speed
			animation_player.play(hop_animation)
			animation_player.seek(0.0)
			animation_player.speed_scale = animation_speed_factor
			
			# Calculate the time to pause at
			var anim_length = animation_player.current_animation_length
			var pause_position = anim_length * jump_pause_frame
			
			# Create a one-shot timer to pause the animation at the right moment
			var timer = get_tree().create_timer(pause_position)
			timer.timeout.connect(_pause_jump_animation)

# New function to handle the animation restart for double jump
func _on_double_jump_animation_restart():
	if is_jumping and animation_player:
		# Reset to beginning but keep double speed
		animation_player.seek(0.0)

func _pause_jump_animation():
	if is_jumping and animation_player:
		# Pause the animation
		animation_player.pause()

func _on_player_landed():
	is_jumping = false
	
	if animation_player:
		# Resume playing the animation from its current position
		# and reset speed to normal (with factor applied)
		animation_player.speed_scale = animation_speed_factor
		animation_player.play()
