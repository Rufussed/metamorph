extends Node3D

# Form references
@export var rabbit_form: NodePath
@export var bird_form: NodePath

# Current active form
var current_form: CharacterBody3D
var rabbit: CharacterBody3D
var bird: CharacterBody3D

# Form-specific animations
var rabbit_animation_controller: Node
var bird_animation_controller: Node

# Signal for transformation
signal form_changed(from_form, to_form)

func _ready():
	# Get references to forms
	rabbit = get_node_or_null(rabbit_form)
	bird = get_node_or_null(bird_form)
	
	# Initialize animation controllers if they exist
	if rabbit and rabbit.has_node("Model/AnimationController"):
		rabbit_animation_controller = rabbit.get_node("Model/AnimationController")
	
	if bird and bird.has_node("Model/AnimationController"):
		bird_animation_controller = bird.get_node("Model/AnimationController")
	
	# Start with rabbit form active by default
	if rabbit:
		current_form = rabbit
		if bird:
			bird.set_physics_process(false)
			bird.visible = false

func _input(event):
	# Example transformation trigger (could be changed to collision or game event)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:  # T for transform
			transform_player()

func transform_player():
	# If current form is rabbit, switch to bird
	if current_form == rabbit and bird:
		# Store position and other relevant state
		var current_position = current_form.global_position
		var current_velocity = current_form.velocity
		
		# Disable rabbit
		rabbit.set_physics_process(false)
		rabbit.visible = false
		
		# Enable bird
		bird.global_position = current_position
		bird.velocity = current_velocity
		bird.set_physics_process(true)
		bird.visible = true
		
		# Update current form
		current_form = bird
		
		# Emit signal
		emit_signal("form_changed", "rabbit", "bird")
	
	# If current form is bird, switch to rabbit
	elif current_form == bird and rabbit:
		# Store position and other relevant state
		var current_position = current_form.global_position
		var current_velocity = current_form.velocity
		
		# Disable bird
		bird.set_physics_process(false)
		bird.visible = false
		
		# Enable rabbit
		rabbit.global_position = current_position
		rabbit.velocity = current_velocity
		rabbit.set_physics_process(true)
		rabbit.visible = true
		
		# Update current form
		current_form = rabbit
		
		# Emit signal
		emit_signal("form_changed", "bird", "rabbit")

# Function to get current active form
func get_current_form() -> CharacterBody3D:
	return current_form
