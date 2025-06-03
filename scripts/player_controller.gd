extends CharacterBody3D

# Physics parameters - adjust these in the Inspector
@export var forward_speed: float = 10.0
@export var jump_force: float = 12.0
@export var gravity: float = 20.0
@export var lateral_speed: float = 8.0

# State variables
var is_jumping: bool = false
var lane: int = 0  # 0 is center, -1 is left, 1 is right
var lane_width: float = 3.0  # Distance between lanes

func _physics_process(delta):
	# Apply constant forward movement
	velocity.z = -forward_speed  # Negative Z is forward in most 3D setups
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		is_jumping = false
	
	# Handle lane changing (side to side movement)
	var target_x = lane * lane_width
	var current_x = position.x
	var direction = sign(target_x - current_x)
	
	if abs(target_x - current_x) > 0.1:
		velocity.x = direction * lateral_speed
	else:
		velocity.x = 0
		position.x = target_x
	
	# Move the character
	move_and_slide()

func jump():
	if is_on_floor() and not is_jumping:
		velocity.y = jump_force
		is_jumping = true

func move_left():
	if lane > -1:  # Don't move beyond leftmost lane
		lane -= 1

func move_right():
	if lane < 1:  # Don't move beyond rightmost lane
		lane += 1

func _input(event):
	# Handle player input
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		jump()
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		move_left()
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		move_right()
