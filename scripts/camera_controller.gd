extends Camera3D

# Camera constraints
@export var min_y_position: float = 0.0
@export var smooth_transition: bool = true
@export var transition_speed: float = 5.0
@export var follow_player: bool = true
@export var follow_offset: Vector3 = Vector3(0, 2.5, 4.5)
@export var follow_smoothing: float = 5.0

# Original camera settings
var original_local_position: Vector3

func _ready():
	# Store original position relative to parent
	original_local_position = position
	
	# Connect to player's reset signal via Game Manager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.connect("reset_player_requested", Callable(self, "_on_player_reset"))

func _process(delta):
	# Handle minimum Y position constraint
	if global_position.y < min_y_position:
		if smooth_transition:
			# Smoothly move up to minimum Y
			var target_y = min_y_position
			var new_y = lerp(global_position.y, target_y, transition_speed * delta)
			global_position.y = new_y
		else:
			# Immediately set to minimum Y
			global_position.y = min_y_position

# Reset camera when player is reset
func _on_player_reset(player_position):
	# Reset to original position relative to player
	position = original_local_position
