extends Node

# Character controllers
@export var rabbit_controller_path: NodePath
@export var bird_controller_path: NodePath

# Camera reference
@export var main_camera_path: NodePath = NodePath("../MainCamera")

# Current active character
var current_character: CharacterBody3D
var rabbit_controller: CharacterBody3D
var bird_controller: CharacterBody3D
var main_camera: Camera3D

# Track if transformation is in progress
var transforming: bool = false

# Signal for transformation events
signal transformation_started(from_type, to_type)
signal transformation_completed(new_type)
signal reset_player_requested(reset_position)

func _ready():
	# Get references to controllers
	rabbit_controller = get_node_or_null(rabbit_controller_path)
	bird_controller = get_node_or_null(bird_controller_path)
	
	# Get reference to main camera
	main_camera = get_node_or_null(main_camera_path)
	
	print("Game Manager ready - Rabbit: ", rabbit_controller, " Bird: ", bird_controller)
	
	# Set initial character (default to rabbit if available)
	if rabbit_controller:
		current_character = rabbit_controller
		if bird_controller:
			# Hide and disable bird initially
			bird_controller.set_physics_process(false)
			bird_controller.visible = false
	elif bird_controller:
		# If no rabbit, start with bird
		current_character = bird_controller
	
	print("Current character set to: ", current_character)

func _input(event):
	# Detect up arrow press for transformation
	if event is InputEventKey and event.pressed and event.keycode == KEY_UP:
		print("UP arrow pressed - Transforming")
		transform_character()

func _process(delta):
	# Update camera position to follow current character if we have a global camera
	if main_camera and current_character:
		var target_position = current_character.global_position
		target_position.y += 3.0  # Camera height offset
		target_position.z += 3.0  # Camera distance behind player
		
		# Smooth camera movement
		main_camera.global_position = main_camera.global_position.lerp(target_position, delta * 5.0)
		
		# Make camera look at player
		main_camera.look_at(current_character.global_position)

func transform_character():
	# Don't transform if already transforming or if either controller is missing
	if transforming or !rabbit_controller or !bird_controller:
		print("Can't transform - Already transforming: ", transforming, 
			" Rabbit exists: ", rabbit_controller != null, 
			" Bird exists: ", bird_controller != null)
		return
		
	transforming = true
	
	# Determine which form to switch to
	var target_character: CharacterBody3D
	var from_type: String
	var to_type: String
	
	if current_character == rabbit_controller:
		target_character = bird_controller
		from_type = "rabbit"
		to_type = "bird"
	else:
		target_character = rabbit_controller
		from_type = "bird"
		to_type = "rabbit"
	
	print("Transforming from ", from_type, " to ", to_type)
	
	# Store current state for transfer
	var current_position = current_character.global_position
	var current_velocity = current_character.velocity
	
	# Emit transformation started signal
	emit_signal("transformation_started", from_type, to_type)
	
	# Disable current character and any associated camera
	if current_character.has_node("Camera3D"):
		current_character.get_node("Camera3D").current = false
	current_character.set_physics_process(false)
	current_character.visible = false
	
	# Enable target character and its camera
	target_character.global_position = current_position
	target_character.velocity = current_velocity
	if target_character.has_node("Camera3D"):
		target_character.get_node("Camera3D").current = true
	target_character.set_physics_process(true)
	target_character.visible = true
	
	# Update current character
	current_character = target_character
	
	# Transformation complete
	transforming = false
	emit_signal("transformation_completed", to_type)
	
	print("Transformation complete - new character: ", to_type)

# Handle player death
func _on_character_body_3d_player_died():
	# Reset player to a safe position
	var reset_position = Vector3(0, 5, 0)  # Adjust as needed
	emit_signal("reset_player_requested", reset_position)

# Get the currently active character
func get_current_character() -> CharacterBody3D:
	return current_character
