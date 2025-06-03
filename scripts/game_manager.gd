extends Node

# Game state
var score: int = 0
var game_running: bool = true
var initial_player_position: Vector3

# Reference to player node
@onready var player = get_tree().get_first_node_in_group("player")

# Add reset signal
signal reset_player_requested(position)

func _ready():
	if player:
		# Store initial position for reset
		initial_player_position = player.global_position
	else:
		# We need to keep this error message for debugging critical issues
		push_error("No player found in 'player' group")

# This function matches the connection in your scene
func _on_character_body_3d_player_died():
	reset_game()

func reset_game():
	if player:
		# Emit the signal to reset player
		emit_signal("reset_player_requested", initial_player_position)
	else:
		# Try to find player again in case it was lost
		player = get_tree().get_first_node_in_group("player")
		if player:
			initial_player_position = player.global_position
			emit_signal("reset_player_requested", initial_player_position)
		else:
			push_error("ERROR: Can't reset player - reference lost")
	
	# Reset score
	score = 0
