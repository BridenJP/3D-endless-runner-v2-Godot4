extends Node3D
class_name TrackSegment

# Preload track segment and obstacles
var box_obstacle = preload("res://Objects/box_obstacle.tscn")
var collectible = preload("res://Objects/collectible.tscn")

# Center position of the obstacles (x coordinate)
var lanes = [-3.3, 0, 3.3]

# Save the parent for later use
var main: Node3D
var player_collect: Callable

func set_main(value):
	main = value
	player_collect = Callable(main, "_on_player_collect")

func clear_children_of(node):
	# Free up all the children - we do this when we reuse the track
	var children = node.get_children()
	for child in children:
		child.queue_free()  # Safely mark the child for deletion

func random_pos(z):
	# Randomly select a lane
	var lane_index = randi() % lanes.size()  
	# Randomly select high or low position
	var height_index = randi() % 2 

	return Vector3(lanes[lane_index], 0.5 + height_index * 1.5, z)

func create_obstacle_at(pos):
	# New obstacle
	var obstacle = box_obstacle.instantiate()
	# Add inside the Obstacles node - we clean this up later
	$Obstacles.add_child(obstacle)
	# Position relative to this track segment
	obstacle.transform.origin = pos

func create_collectible_at(pos):
	# New collectible
	var collect = collectible.instantiate()
	# Add inside the Obstacles node - we clean this up later
	$Collectibles.add_child(collect)
	# Position relative to this track segment
	collect.transform.origin = pos
	# Connect our collision signal
	collect.connect("body_entered", player_collect.bind(collect))

func create_objects(first_track):
	# Clear each time
	clear_children_of($Obstacles)
	clear_children_of($Collectibles)

	# Break down our 100m into 40 subpositions (every 2.5 m)
	for i in range(4 if first_track else 0, 40):
		var z = 50 - i * 2.5
		var obstacle_pos = null
		# Every 4th time (10m) we do an obstacle
		if i % 4 == 0:
			obstacle_pos = random_pos(z)
			create_obstacle_at(obstacle_pos)
		var collectible_pos = random_pos(z)
		# Avoid overlap
		while collectible_pos == obstacle_pos:
			collectible_pos = random_pos(z)
		create_collectible_at(collectible_pos)
