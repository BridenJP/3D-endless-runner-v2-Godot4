extends CharacterBody3D

const SPEED = 8.0
const JUMP_VELOCITY = 4.5
const LANE_W = 3.3
const LANE_CHANGE_SPEED = 10.0  # Speed of lane change, higher is faster
const SLIDE_TIME = 0.8

enum Action {Run, Jump, Dive}
enum State {Normal, Airborne, Diving}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var lane = 0 # Current lane
var target_x = 0.0  # Target x position for smooth lane changes
var action: Action
var state: State

func _ready():
	update_target_x()
	set_action(Action.Run)
	state = State.Normal
	velocity.z = -SPEED

func update_target_x():
	target_x = lane * LANE_W

func _physics_process(delta):
	# Always running!
	
	# Add the gravity.
	if not is_on_floor() and state != State.Diving:
		state = State.Airborne
		velocity.y -= gravity * delta
	elif state == State.Airborne:
		state = State.Normal
		set_action(Action.Run)

	# Things that only work in normal state (running)
	if state == State.Normal:
		# Handle jump.
		if Input.is_action_just_pressed("ui_up"):
			velocity.y = JUMP_VELOCITY
			set_action(Action.Jump)
		## Handle slide.
		if Input.is_action_just_pressed("ui_down"):
			set_action(Action.Dive)
		# Handle lane changes.
		if Input.is_action_just_pressed("ui_left") and lane > -1:
			lane -= 1
			update_target_x()
		elif Input.is_action_just_pressed("ui_right") and lane < 1:
			lane += 1
			update_target_x()

	# This still needs to happen even if not "normal" in case it hadn't finished
	# Smooth transition to the target lane.
	global_transform.origin.x = move_toward(global_transform.origin.x, target_x, LANE_CHANGE_SPEED * delta)

	move_and_slide()
	
	# Check for collisions
	if is_on_wall():
		$PlayerModel/AnimationPlayer.play("Hurt")
		set_physics_process(false)
		$RestartTimer.start()

func set_default_transform():
	$PlayerColl.set_rotation_degrees(Vector3(0, 0, 0))
	$PlayerModel.set_rotation_degrees(Vector3(0, -180, 0))
	$PlayerModel.set_position(Vector3(0, -0.8, 0))

func set_diving_transform():
	$PlayerColl.set_rotation_degrees(Vector3(90, 0, 0))
	$PlayerModel.set_rotation_degrees(Vector3(-90, -180, 0))
	$PlayerModel.set_position(Vector3(0, -0.1, -0.8))

func set_action(value: Action):
	var animation
	match value:
		Action.Run:
			animation = "Run"
			set_default_transform()

		Action.Jump:
			animation = "Jump"
			set_default_transform()
			
		Action.Dive:
			animation = "Fall"
			set_diving_transform()
			$Timer.stop()
			$Timer.start(SLIDE_TIME)
			state = State.Diving

	$PlayerModel/AnimationPlayer.play(animation)

func _on_timer_timeout():
	state = State.Normal
	set_action(Action.Run)

func _on_restart_timer_timeout():
	get_tree().reload_current_scene()
