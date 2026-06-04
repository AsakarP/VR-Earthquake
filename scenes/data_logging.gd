extends Node

var csv_path := ""
var tracker_path := ""
var current_subject_number := 1

func _ready() -> void:
	if OS.get_name() == "Android":
		OS.request_permissions()

	# 2. Hardcode the absolute paths directly for the headset
	csv_path = "/storage/emulated/0/Download/simulation_results.csv"
	tracker_path = "/storage/emulated/0/Download/subject_tracker.txt"
	
	#csv_path = "user://simulation_results.csv"
	#tracker_path = "user://subject_tracker.txt"
	
	if FileAccess.file_exists(tracker_path):
		var file = FileAccess.open(tracker_path, FileAccess.READ)
		current_subject_number = file.get_as_text().to_int()
		file.close()

func get_player_id() -> String:
	return "Subject_%03d" % current_subject_number

func save_session_data(magnitude: float, hit_count: int, hit_objects: Array[String], time_survived: float, reaction_time: float, entered_zone: String, entered_safe: bool, entered_hazard: bool) -> void:
	var file: FileAccess
	var is_new_file = not FileAccess.file_exists(csv_path)
		
	if is_new_file:
		file = FileAccess.open(csv_path, FileAccess.WRITE)
		file.store_line("Player ID,Magnitude,Hit Count,Objects Hit,Time Survived,Reaction Time,Zone Entered,Reached Safety,Entered Hazard")
	else:
		file = FileAccess.open(csv_path, FileAccess.READ_WRITE)
		file.seek_end() 

	if file:
		var object_string := "None"
		if hit_objects.size() > 0:
			object_string = '"%s"' % ", ".join(hit_objects)
			
		var reaction_string := "None"
		var zone_string := "None"
		
		if entered_zone != "":
			reaction_string = "%.2f" % reaction_time # Format as decimal only if they chose a zone
			zone_string = entered_zone
			
		var player_id = get_player_id()
		
		# --- UPDATED: Added two extra %s placeholders and converted the booleans to strings ---
		var data_row = "%s,%.1f,%d,%s,%.2f,%s,%s,%s,%s" % [
			player_id,
			magnitude,
			hit_count,
			object_string,
			time_survived,
			reaction_string,
			zone_string,
			str(entered_safe),
			str(entered_hazard)
		]
		
		file.store_line(data_row)
		file.close()
		print("SUCCESS: Data saved for ", player_id)
		print("Row Data: ", data_row)
	else:
		printerr("ERROR: Could not open the CSV file to save data.")

func advance_to_next_subject() -> void:
	current_subject_number += 1
	var file = FileAccess.open(tracker_path, FileAccess.WRITE)
	file.store_string(str(current_subject_number))
	file.close()
