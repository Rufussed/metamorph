extends CharacterBody3D

# Physics parameters - adjust these in the Inspector
@export var initial_forward_speed: float = 0.0  # Starting speed
@export var max_forward_speed: float = 20.0  # Maximum forward speed
@export var min_forward_speed: float = 10.0  # Minimum forward speed
@export var forward_acceleration: float = 4.0  # Will reach max speed in 5 seconds
@export var boost_acceleration: float = 8.0  # Extra acceleration when pressing W
@export var deceleration: float = 8.0  # Deceleration when pressing S
@export var jump_force: float = 10.0  # Increased for better jump height
@export var gravity: float = 30.0  # Increased to ensure player comes down
@export var lateral_force: float = 20.0  # Force applied when moving sideways
@export var mass: float = 3.0  # Character's mass
@export var lateral_drag: float = 0.9  # Drag coefficient to slow down sideways movement
@export var max_lateral_speed: float = 8.0  # Maximum sideways speed

# Double jump settings
@export var double_jump_enabled: bool = true
@export var double_jump_force: float = 10.0  # Set equal to the first jump force
@export var debug_jumps: bool = false  # Enable for troubleshooting

# State variables
var is_jumping: bool = false
var jump_count: int = 0
var max_jumps: int = 2  # Set to 2 for double jump
var current_forward_speed: float = 0.0  # Track current speed
var was_on_floor: bool = false  # Track previous floor state

# Add signals for game events
signal player_died

# Add signals for animation control
signal player_jumped
signal player_landed

# Add death threshold
@export var death_y_threshold: float = -10.0  # Player dies if they fall below this Y position

# Add Z position threshold
@export var reset_z_threshold: float = -560.0  # Reset player when Z goes below this value

# Camera reference 
@onready var camera = $Camera3D

func _ready():
	# Initialize starting speed - this will use the value from Inspector if set there
	current_forward_speed = initial_forward_speed
	
	# Ensure jump count starts at 0
	jump_count = 0
	was_on_floor = is_on_floor()

	# Make sure physics is properly initialized
	move_and_slide()

func _physics_process(delta):
	# More reliable floor detection
	var on_floor_now = is_on_floor()
	
	# Reset jump count when landing on the floor
	if on_floor_now and !was_on_floor:
		jump_count = 0
		is_jumping = false
		emit_signal("player_landed")  # Emit signal when landing
		if debug_jumps:
			print("Landed on floor, reset jump count")
	
	# Update previous floor state
	was_on_floor = on_floor_now
	
	# Custom input handling for both WASD and arrow keys
	var up_input = Input.is_action_pressed("ui_up") || Input.is_key_pressed(KEY_W)
	var down_input = Input.is_action_pressed("ui_down") || Input.is_key_pressed(KEY_S)
	var left_input = Input.is_action_pressed("ui_left") || Input.is_key_pressed(KEY_A)
	var right_input = Input.is_action_pressed("ui_right") || Input.is_key_pressed(KEY_D)
	
	# Calculate speed input (-1 to +1)
	var speed_input = 0.0
	if up_input: speed_input += 1.0
	if down_input: speed_input -= 1.0
	
	# Handle speed changes based on input
	if speed_input > 0:
		# Boost with W or Up
		current_forward_speed += (forward_acceleration + boost_acceleration) * delta
	elif speed_input < 0:
		# Slow down with S or Down
		current_forward_speed -= deceleration * delta
	else:
		# Normal acceleration
		current_forward_speed += forward_acceleration * delta
	
	# Clamp speed between min and max
	current_forward_speed = clamp(current_forward_speed, min_forward_speed, max_forward_speed)
	
	# Apply current forward movement
	velocity.z = -current_forward_speed
	
	# Calculate lateral input (-1 to +1)
	var lateral_input = 0.0
	if right_input: lateral_input += 1.0
	if left_input: lateral_input -= 1.0
	
	# Handle lateral movement with forces
	if lateral_input != 0:
		var force = lateral_input * lateral_force
		var acceleration = force / mass
		velocity.x += acceleration * delta
	
	# Apply drag to slow down when no input
	velocity.x *= lateral_drag
	
	# Clamp lateral speed
	velocity.x = clamp(velocity.x, -max_lateral_speed, max_lateral_speed)
	
	# Apply gravity more consistently
	velocity.y -= gravity * delta
	
	# Check if player has fallen below the death threshold
	if global_position.y < death_y_threshold:
		emit_signal("player_died")
	
	# Check if player has gone too far in Z direction
	if global_position.z < reset_z_threshold:
		# Reset only Z position to zero, keeping X and Y as is
		global_position.z = 0
		# Optional: reset forward speed if you want a fresh start
		current_forward_speed = initial_forward_speed
	
	# Move the character
	move_and_slide()
	
	# Debug info if enabled
	if debug_jumps and Input.is_key_pressed(KEY_SPACE):
		print("Jump key pressed - Floor: ", on_floor_now, " Jump count: ", jump_count)

func jump():
	if debug_jumps:
		print("Jump function called. On floor: ", is_on_floor(), " Jump count: ", jump_count)
	
	# First jump from the ground
	if is_on_floor():
		velocity.y = jump_force
		is_jumping = true
		jump_count = 1
		emit_signal("player_jumped")  # Emit signal when jumping
		if debug_jumps:
			print("First jump executed, count: ", jump_count)
	# Double jump in the air
	elif double_jump_enabled and jump_count < max_jumps:
		# Reset any downward momentum to ensure full jump height
		velocity.y = 0
		# Apply the same jump force as the first jump
		velocity.y = double_jump_force
		jump_count = max_jumps  # Use all available jumps
		is_jumping = true
		emit_signal("player_jumped")  # Emit signal for double jump too
		if debug_jumps:
			print("Second jump executed, count: ", jump_count)
	elif debug_jumps:
		print("Jump not allowed: on_floor=", is_on_floor(), " jump_count=", jump_count, " max_jumps=", max_jumps)

func _input(event):
	# Handle jump input with both Space and other possible keys
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			jump()
		# Toggle debug mode with F3
		elif event.keycode == KEY_F3:
			debug_jumps = !debug_jumps
			print("Jump debugging: ", debug_jumps)

# Add the reset method to match the signal connection in the scene
func _on_game_manager_reset_player_requested(reset_position):
	# Immediately set position
	global_position = reset_position
	# Reset physics
	velocity = Vector3.ZERO
	current_forward_speed = initial_forward_speed
	is_jumping = false
	jump_count = 0  # Reset jump count on game reset
