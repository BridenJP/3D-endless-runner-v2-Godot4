extends Node3D

const TRACK_LEN: float = 100
const N_SEGMENTS: int = 3

# Preload track segment
const TRACK_SEGMENT: PackedScene = preload("res://Objects/track_segment.tscn")

var milestone: float # next change of track
var track_index: int # which track we will change
var tracks: Array # array of tracks
var track_z: float # z pos of next track
var first_track: bool # the first track we don't have our objects too close
var score: int # keep score

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	$Player.hide()
	$HUD.hide()
	$Start.show()

func _process(_delta: float) -> void:
	# If we're gone past the end of a track segment, we can reuse it
	if (milestone - $Player.global_transform.origin.z) > 10:
		position_next_track()

func position_next_track() -> void:
	var track: Node3D = tracks[track_index]
	track.global_transform.origin.z = track_z
	track.create_objects(first_track)
	track_z -= TRACK_LEN
	milestone -= TRACK_LEN
	track_index = (track_index + 1) % N_SEGMENTS

func _on_player_collect(_player: Player, collectible: Area3D) -> void:
	score += 5
	$HUD/ScoreLabel.text = "score: " + str(score)
	collectible.queue_free()

func play() -> void:
	score = 0
	first_track = true
	# Create 2 tracks and add them to the Tracks node
	tracks = []
	for i in range(N_SEGMENTS):
		var track: Node3D = TRACK_SEGMENT.instantiate()
		tracks.append(track)
		track.set_main(self)
		$Tracks.add_child(track)

	# Initial z-position of first track
	track_z = -TRACK_LEN * 0.5
	# We use this to know which track we can reposition next
	track_index = 0
	# The milestone helps us know when to move a track segment (once it's behind us)
	milestone = TRACK_LEN
	# We use the same code to position at the start and for repositioning later
	position_next_track()
	first_track = false
	position_next_track()

	$Player.global_position = Vector3(0, 0, 0)
	$Player.show()

	set_physics_process(true)
	set_process(true)

func _on_button_pressed() -> void:
	$Start.hide()
	$HUD.show()
	play()
