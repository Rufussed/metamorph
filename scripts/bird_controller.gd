extends CharacterBody3D

# Flight parameters
@export var flight_speed: float = 15.0
@export var flight_acceleration: float = 5.0
@export var flight_drag: float = 0.95
@export var vertical_flight_force: float = 8.0
@export var dive_force: float = 12.0
@export var turning_speed: float = 3.0
@export var max_roll_angle: float = 40.0  # In degrees
@export var roll_speed: float = 5.0

# Camera settings
@export var camera_lag: float = 0.1

# State variables
var current_roll: float = 0.0

# Reference to camera
@onready var camera = $Camera3D

# Add signals
signal bird_flapped
signal bird_dived

func _ready():
	# Initialize physics
	move_and_slide()

func _physics_process(delta):
	# Get input
	var forward_input = Input.is_action_pressed("ui_up") || Input.is_key_pressed(KEY_W)
	var backward_input = Input.is_action_pressed("ui_down") || Input.is_key_pressed(KEY_S)
	var left_input = Input.is_action_pressed("ui_left") || Input.is_key_pressed(KEY_A)
	var right_input = Input.is_action_pressed("ui_right") || Input.is_key_pressed(KEY_D)
	var flap_input = Input.is_key_pressed(KEY_SPACE)
	var dive_input = Input.is_key_pressed(KEY_SHIFT)
	
	# Flight model - bird always moves forward but can steer
	var direction = Vector3.ZERO
	direction.z = -1.0  # Always fly forward
	
	# Apply turning based on input
	var turn_input = 0.0
	if right_input: turn_input -= 1.0
	if left_input: turn_input += 1.0
	
	# Apply roll based on turning
	current_roll = lerp(current_roll, turn_input * max_roll_angle, delta * roll_speed)
	
	# Rotate the bird for turning
	rotation.y += turn_input * turning_speed * delta
	
	# Apply roll visually (this would affect the model, not the collision)
	# This needs to be applied to the model node
	if has_node("Model"):
		$Model.rotation.z = deg_to_rad(current_roll)
	
	# Transform direction to global space
	direction = direction.rotated(Vector3.UP, rotation.y)
	
	# Apply vertical movement
	if flap_input:
		velocity.y += vertical_flight_force * delta
		emit_signal("bird_flapped")
	if dive_input:
		velocity.y -= dive_force * delta
		emit_signal("bird_dived")
	else:
		# Gradually lose altitude when not flapping
		velocity.y -= 0.5 * delta
	
	# Apply forward movement
	var target_velocity = direction * flight_speed
	velocity.x = lerp(velocity.x, target_velocity.x, delta * flight_acceleration)
	velocity.z = lerp(velocity.z, target_velocity.z, delta * flight_acceleration)
	
	# Apply drag
	velocity *= flight_drag
	
	# Apply movement
	move_and_slide()
	
	# Camera follows with slight lag for cinematic effect
	if camera:
		var target_pos = camera.global_position.lerp(global_position, 1.0 - camera_lag)
		camera.global_position = target_pos
		camera.look_at(global_position + direction * 10.0)

func _input(event):
	# Any bird-specific input processing here
	pass
