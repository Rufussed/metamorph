extends Node3D

@onready var animation_player = $AnimationPlayer
var paused_at_frame_10 = false

func _ready():
	# Find the player node and connect to its signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("player_jumped", Callable(self, "_on_player_jumped"))
		player.connect("player_landed", Callable(self, "_on_player_landed"))
	
	# Start playing animation
	if animation_player:
		animation_player.play("hop")

func _on_player_jumped():
	if animation_player:
		# Continue playing until frame 10
		animation_player.seek(0.1)  # Frame 10 at 0.1 seconds (assuming 30fps)
		animation_player.pause()
		paused_at_frame_10 = true

func _on_player_landed():
	if animation_player and paused_at_frame_10:
		# Resume animation
		animation_player.play()
		paused_at_frame_10 = false
