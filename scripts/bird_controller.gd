extends CharacterBody3D

# Flight parameters
@export var flight_speed: float = 15.0
@export var flight_acceleration: float = 5.0
@export var flight_drag: float = 0.95
@export var vertical_flight_force: float = 12.0  # Upward impulse when flapping
@export var bird_gravity_scale: float = 1.2  
@export var gravity_force: float = 9.8  # Base gravity value
@export var turning_speed: float = 3.0
@export var max_turn_angle: float = 30.0  # Maximum turning angle in degrees
@export var max_lateral_speed: float = 8.0  # Maximum sideways speed (like rabbit)

# State variables
var base_rotation_y: float = 0.0  # Starting Y rotation
var current_turn_angle: float = 0.0  # Current turn amount

# Add signals
signal bird_flapped
signal bird_dived
signal player_died

func _ready():
	# Initialize physics
	move_and_slide()
	
	# Store initial Y rotation as the base
	base_rotation_y = rotation.y

func _physics_process(delta):
	# Get input
	var left_input = Input.is_action_pressed("ui_left") || Input.is_key_pressed(KEY_A)
	var right_input = Input.is_action_pressed("ui_right") || Input.is_key_pressed(KEY_D)
	var flap_input = Input.is_key_pressed(KEY_SPACE)
	
	# Flight model - bird always moves forward
	var direction = Vector3.ZERO
	direction.z = -1.0  # Always fly forward
	
	# Apply turning based on input, with limits
	var turn_input = 0.0
	if right_input: turn_input += 1.0  
	if left_input: turn_input -= 1.0   
    
	# Calculate the new turn angle
	current_turn_angle += turn_input * turning_speed * delta
	
	# Clamp the turn angle to our limits
	current_turn_angle = clamp(current_turn_angle, -max_turn_angle, max_turn_angle)
	
	# Apply the clamped rotation to Y axis (bird turns left/right)
	# This rotates around the vertical (Y) axis only
	rotation.y = base_rotation_y + deg_to_rad(current_turn_angle)
	
	# REMOVED: No more roll effect
	# Bird stays level at all times
	
	# Direct lateral movement based on input (similar to rabbit)
	# This makes the bird actually move sideways, not just rotate
	var lateral_velocity = turn_input * max_lateral_speed
	velocity.x = lateral_velocity
	
	# Always move forward (like the rabbit)
	velocity.z = -flight_speed
	
	# Apply custom gravity (bird always drifts down)
	# Increased gravity scale for faster falling
	velocity.y -= gravity_force * bird_gravity_scale * delta
	
	# Apply upward impulse when space is pressed
	if flap_input and Input.is_action_just_pressed("ui_select"):
		velocity.y = vertical_flight_force
		emit_signal("bird_flapped")
	
	# Apply drag
	velocity *= flight_drag
	
	# Apply movement
	move_and_slide()
	
	# Check if bird has fallen below death threshold
	if global_position.y < -50.0:
		emit_signal("player_died")

# Add the reset method to match the signal connection in the scene
func _on_game_manager_reset_player_requested(reset_position):
	# Immediately set position
	global_position = reset_position
	# Reset physics
	velocity = Vector3.ZERO
	# Reset turn angle when respawning
	current_turn_angle = 0.0
	rotation.y = base_rotation_y
