extends Camera3D

# Camera constraints
@export var min_y_position: float = 0.0
@export var smooth_transition: bool = true
@export var transition_speed: float = 5.0
@export var follow_player: bool = true
@export var follow_offset: Vector3 = Vector3(0, 2.5, 4.5)
@export var follow_smoothing: float = 5.0

# New variables for advanced follow
@export var follow_distance: float = 4.0
@export var bird_follow_distance: float = 6.0  # Closer distance for bird (was 8.0)
@export var height_offset: float = 2.0
@export var smoothing: float = 5.0
@export var lateral_smoothing: float = 2.0  # Slower lateral (X) tracking
@export var vertical_smoothing: float = 3.0  # Slower vertical (Y) tracking
@export var look_ahead: float = 2.0

# Original camera settings
var original_local_position: Vector3
var target: Node3D = null
var game_manager = null
var fixed_rotation = Quaternion.IDENTITY

func _ready():
	# Store original position relative to parent
	original_local_position = position
	
	# Find the game manager
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Set initial target
	update_target()
	
	# Store the initial camera rotation (looking at -Z)
	fixed_rotation = Quaternion(global_transform.basis)
	
	# Connect transformation signals
	if game_manager:
		if game_manager.has_signal("transformation_completed"):
			game_manager.connect("transformation_completed", Callable(self, "_on_transformation_completed"))

	# Connect to player's reset signal via Game Manager
	if game_manager:
		game_manager.connect("reset_player_requested", Callable(self, "_on_player_reset"))

func _process(delta):
	# Update target if needed
	if !target and game_manager:
		update_target()
	
	if target:
		# Calculate desired position
		var target_pos = target.global_position
		var offset = Vector3(0, height_offset, follow_distance)
		
		# Use different follow distance for bird
		if target.name == "BirdController":
			offset.z = bird_follow_distance
		
		# Create a target position with the desired offset
		var desired_position = target_pos + offset
		
		# Smoothly track each axis with separate smoothing values
		var current_pos = global_position
		var new_pos = Vector3(
			lerp(current_pos.x, desired_position.x, delta * lateral_smoothing),  # X - slow lateral movement
			lerp(current_pos.y, desired_position.y, delta * vertical_smoothing), # Y - smooth vertical movement
			lerp(current_pos.z, desired_position.z, delta * smoothing)           # Z - standard smoothing
		)
		
		# Apply the calculated position
		global_position = new_pos
		
		# Always look in the -Z direction (forward)
		global_basis = Basis(fixed_rotation)

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

func update_target():
	if game_manager and game_manager.has_method("get_current_character"):
		target = game_manager.get_current_character()

# Reset camera when player is reset
func _on_player_reset(_player_position):
	# Reset to original position relative to player
	position = original_local_position

func _on_transformation_completed(_new_type):
	# Update camera target after transformation
	update_target()
