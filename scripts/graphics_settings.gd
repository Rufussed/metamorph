extends Node

func _ready():
	# Detect platform and apply appropriate settings
	var os_name = OS.get_name()
	print("Running on: ", os_name)
	
	# Fix ghosting issues specifically on Windows
	if os_name == "Windows":
		# Disable temporal anti-aliasing
		get_viewport().use_taa = false
		
		# Force V-Sync to be on for Windows
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		
		# Ensure motion blur is disabled
		if ProjectSettings.has_setting("rendering/quality/filters/use_fxaa"):
			ProjectSettings.set_setting("rendering/quality/filters/use_fxaa", false)
		
		# Disable any other post-processing that could cause ghosting
		# (These settings may vary based on your Godot version)
		if ProjectSettings.has_setting("rendering/quality/filters/use_debanding"):
			ProjectSettings.set_setting("rendering/quality/filters/use_debanding", false)
	
	print("Graphics settings applied for platform: ", os_name)
