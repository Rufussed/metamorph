extends CharacterBody3D

# Physics parameters - match rabbit but with bird-specific adjustments
@export var initial_forward_speed: float = 0.0
@export var max_forward_speed: float = 20.0
@export var min_forward_speed: float = 10.0
@export var forward_acceleration: float = 4.0
@export var boost_acceleration: float = 8.0
@export var deceleration: float = 8.0
@export var flap_force: float = 10.0  # Replaces jump_force
@export var gravity: float = 15.0  # Reduced from rabbit's 30.0
@export var lateral_force: float = 60.0  # Increased from 20.0 to make turning more responsive
@export var mass: float = 2.0  # Reduced from 3.0 to make the bird feel lighter and more agile
@export var lateral_drag: float = 0.95  # Increased from 0.9 for smoother sideways movement
@export var max_lateral_speed: float = 12.0  # Increased from 8.0 for faster sideways movement

# State variables
var is_jumping: bool = false
var current_forward_speed: float = 0.0
var was_on_floor: bool = false

# Add signals for game events
signal player_died
signal bird_flapped

# Add death threshold
@export var death_y_threshold: float = -50.0
@export var reset_z_threshold: float = -560.0

func _ready():
	# Initialize starting speed
	current_forward_speed = initial_forward_speed
	was_on_floor = is_on_floor()
	move_and_slide()

func _physics_process(delta):
	# Update floor state
	var on_floor_now = is_on_floor()
	if on_floor_now and !was_on_floor:
		is_jumping = false
	was_on_floor = on_floor_now
	
	# Get inputs
	var up_input = Input.is_action_pressed("ui_up") || Input.is_key_pressed(KEY_W)
	var down_input = Input.is_action_pressed("ui_down") || Input.is_key_pressed(KEY_S)
	var left_input = Input.is_action_pressed("ui_left") || Input.is_key_pressed(KEY_A)
	var right_input = Input.is_action_pressed("ui_right") || Input.is_key_pressed(KEY_D)
	
	# Handle speed changes
	var speed_input = 0.0
	if up_input: speed_input += 1.0
	if down_input: speed_input -= 1.0
	
	if speed_input > 0:
		current_forward_speed += (forward_acceleration + boost_acceleration) * delta
	elif speed_input < 0:
		current_forward_speed -= deceleration * delta
	else:
		current_forward_speed += forward_acceleration * delta
	
	current_forward_speed = clamp(current_forward_speed, min_forward_speed, max_forward_speed)
	velocity.z = -current_forward_speed
	
	# Handle lateral movement - ENHANCED FOR BETTER RESPONSIVENESS
	var lateral_input = 0.0
	if right_input: lateral_input += 1.0
	if left_input: lateral_input -= 1.0
	
	if lateral_input != 0:
		# Apply a stronger immediate impulse for more responsive turning
		var force = lateral_input * lateral_force
		var acceleration = force / mass
		velocity.x += acceleration * delta * 1.5  # Apply 50% more force than rabbit
	
	# Apply a more gentle drag to maintain momentum better
	velocity.x *= lateral_drag
	velocity.x = clamp(velocity.x, -max_lateral_speed, max_lateral_speed)
	
	# Apply gravity
	velocity.y -= gravity * delta
	
	# Check for spacebar flapping - FIXED: use is_action_just_pressed instead
	if Input.is_action_just_pressed("ui_accept"):
		flap()
	
	# Check death and reset conditions
	if global_position.y < death_y_threshold:
		emit_signal("player_died")
	
	if global_position.z < reset_z_threshold:
		global_position.z = 0
		current_forward_speed = initial_forward_speed
	
	move_and_slide()

func flap():
	# Bird can flap anytime (no floor check)
	velocity.y = flap_force
	is_jumping = true
	emit_signal("bird_flapped")

func _on_game_manager_reset_player_requested(reset_position):
	global_position = reset_position
	velocity = Vector3.ZERO
	current_forward_speed = initial_forward_speed
	is_jumping = false
