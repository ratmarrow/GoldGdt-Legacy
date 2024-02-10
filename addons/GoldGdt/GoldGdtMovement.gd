#	Copyright (c) 2024 ratmarrow
#	
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#	
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#	
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.
#	
#	-------------------------------------------------------------------------------------------------
#	
#	Thank you for using GoldGdt for your project!
#	
#	- ratmarrow <3

extends CharacterBody3D
class_name GoldGdtMovement

#region Variables

@export var PLAYER_PARAMS : PlayerParameters ## Current [PlayerParams] resource being used by this player instance.

# Movement
var input_vector : Vector2 = Vector2.ZERO # Collector for WASD input.
var move_dir : Vector3 = Vector3.ZERO # Collector for speed and direction.
var jump_on : bool = false # Jump input boolean.
var duck_on : bool = false # Ducking input boolean.
var FRICTION_STRENGTH = 1.0 # How much the overall friction calculation applies to your velocity. Not constant to allow for surface-based changes.

@export_group("Ducking")
@export var duck_timer : Timer ## Timer used for ducking animation and collision hull swapping. Time is set in [method _duck] to 1 second.
var ducked : bool = false 
var ducking : bool = false

@export_group("Collision Hull")
var BBOX_STANDING = BoxShape3D.new() # Cached BoxShape for standing.
var BBOX_DUCKING = BoxShape3D.new() # Cached BoxShape for ducking.
@export var player_hull : CollisionShape3D ## Player collision shape/hull, make sure it's a box unless you edit the script to use otherwise!

@export_group("Player View")
var head_resting_position : Vector3 # Created during _physics_process() to position the player's head.
var offset : float = 0.711 # Current offset from player's origin.
var look_input : Vector2 # Collector for mouse input.
var prev_headtrans : Transform3D # Used for camera position interpolation.
var curr_headtrans : Transform3D # Used for camera position interpolation.

@export_subgroup("Gimbal")
@export var head : Node3D ## Y-axis camera gimbal; also determines position of player's view.
@export var vision : Node3D ## X-axis camera gimbal.

@export_subgroup("Camera")
@export var camera_arm : SpringArm3D ## SpringArm3D that has it's rotation and extension distance set automatically.
@export var camera_anchor : Node3D ## Camera anchor node that is automatically rotated to compensate for the camera arm rotation.
@export var camera : Node3D ## Used for player view aesthetics such as camera tilt and bobbing.

@export_group("UI")
@export var speedometer : Label
@export var info : Label

#endregion

# Using _ready() to initialize variables
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set bounding box dimensions.
	BBOX_STANDING.size = PLAYER_PARAMS.HULL_STANDING_BOUNDS
	BBOX_DUCKING.size = PLAYER_PARAMS.HULL_DUCKING_BOUNDS
	
	prev_headtrans.origin = global_position + (Vector3.UP * offset)
	curr_headtrans.origin = global_position + (Vector3.UP * offset)
	
	# Set hull and head position to default.
	player_hull.shape = BBOX_STANDING
	offset = PLAYER_PARAMS.VIEW_OFFSET

# Using _input() to handle mouse input
func _input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			look_input.x = event.relative.x
			look_input.y = event.relative.y
			_handle_camera_input()

# Using _process() to handle camera look logic
func _process(delta):
	# Interpolate the player's resting position to the desired transform position.
	head_resting_position = prev_headtrans.interpolate_with(curr_headtrans, clamp(Engine.get_physics_interpolation_fraction(), 0, 0.95)).origin
	head.global_position = head_resting_position
	
	# Modify camera nodes to conform with Player Parameters.
	# TODO: I have to make this not run every frame, but as far as I can tell, there is negligible impact on performance, so it stays.
	_handle_camera_settings()
	
	#region Character Info UI, remove if deemed necessary
	var speed_format = "%s in/s (goldsrc)\n%s m/s (godot)"
	var speed_string = speed_format % [str(roundi((Vector3(velocity.x * 39.37, 0.0, velocity.z * 39.37).length()))), str(roundi((Vector3(velocity.x, 0.0, velocity.z).length())))]
	speedometer.text = speed_string
	
	var info_format = "rendering fps: %s\nphysics frametime: %s\npos (meters): %s\nvel (meters): %s\ngrounded: %s\ncrouching: %s"
	var info_string = info_format % [str(Engine.get_frames_per_second()), str(get_physics_process_delta_time()), str(position), str(velocity), str(is_on_floor()), str(ducked)]
	info.text = info_string
	#endregion
	
	# Toggle mouse mode while debugging, remove and replace with your own official setup
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE

# Using _physics_process() for handling movement *and* input in order to make player physics as reliable as possible.
# GoldSrc games like Half-Life operated on the framerate the game was running at, which would make physics inconsistent.
# You can change the physics update rate in the Project Settings, but I built this system around running at 100 FPS.
func _physics_process(delta):
	_handle_input()
	_handle_movement(delta)
	_handle_collision()
	
	# Set up the Transforms for the player's head position interpolation.
	prev_headtrans.origin = curr_headtrans.origin
	curr_headtrans.origin = global_position + (Vector3.UP * offset)
	
	# Create camera tilting.
	camera.rotation.z = _calc_roll(PLAYER_PARAMS.ROLL_ANGLE, PLAYER_PARAMS.ROLL_SPEED)*2

# Manipulates the player's camera gimbals for first-person looking
func _handle_camera_input() -> void:
	head.rotation.y -= (look_input.x * PLAYER_PARAMS.MOUSE_SENSITIVITY) * 0.0001
	vision.rotation.x = clamp(vision.rotation.x - (look_input.y * PLAYER_PARAMS.MOUSE_SENSITIVITY) * 0.0001, -1.5, 1.5)
	look_input = Vector2.ZERO

# Manipulates the camera arm based on Player Parameters.
func _handle_camera_settings() -> void:
	# Check if we are using third person.
	if (PLAYER_PARAMS.THIRD_PERSON_CAMERA):
		# If so, rotate camera parts to "move" the camera.
		camera_arm.spring_length = PLAYER_PARAMS.ARM_LENGTH
		camera_arm.rotation_degrees = Vector3(PLAYER_PARAMS.ARM_OFFSET_DEGREES.x, PLAYER_PARAMS.ARM_OFFSET_DEGREES.y, 0)
		camera_anchor.rotation_degrees.x = -PLAYER_PARAMS.ARM_OFFSET_DEGREES.x
		camera.rotation_degrees.y = -PLAYER_PARAMS.ARM_OFFSET_DEGREES.y
	else:
		# If not, reset.
		camera_arm.spring_length = 0
		camera_arm.rotation_degrees = Vector3.ZERO
		camera_anchor.rotation_degrees.x = 0
		camera.rotation_degrees.y = 0

# Intercepts CharacterBody3D collision logic a bit to add slope sliding, recreating surfing
func _handle_collision() -> void:
	var collided := move_and_slide()
	if collided and not get_floor_normal():
		var slide_direction := get_last_slide_collision().get_normal()
		velocity = velocity.slide(slide_direction)
		floor_block_on_wall = false 
	else: # Hacky McHack to restore wallstrafing behaviour which doesn't work unless 'floor_block_on_wall' is true
		floor_block_on_wall = true

# Gathers player input for use in movement calculations
func _handle_input() -> void:
	# Get input strength on the horizontal axes.
	var ix = Input.get_action_raw_strength("pm_moveright") - Input.get_action_raw_strength("pm_moveleft")
	var iy = Input.get_action_raw_strength("pm_movebackward") - Input.get_action_raw_strength("pm_moveforward")
	
	# Collect input.
	input_vector = Vector2(ix, iy).normalized()
	
	# Create vector that stores speed and direction.
	move_dir = head.transform.basis * Vector3(input_vector.x * PLAYER_PARAMS.SIDE_SPEED, 0, input_vector.y * PLAYER_PARAMS.FORWARD_SPEED)
	
	# Clamp desired speed to max speed
	if (move_dir.length() > PLAYER_PARAMS.MAX_SPEED):
		move_dir *= PLAYER_PARAMS.MAX_SPEED / move_dir.length()
	
	# Gather jumping and crouching input.
	jump_on = Input.is_action_pressed("pm_jump") if PLAYER_PARAMS.AUTOHOP else Input.is_action_just_pressed("pm_jump")
	duck_on = Input.is_action_pressed("pm_duck")

# Handles movement and jumping physics
func _handle_movement(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= PLAYER_PARAMS.GRAVITY * delta
	
	# Check for anything partaining to ducking every physics step
	_duck()
	
	# Check if we are on ground
	if is_on_floor():
		if jump_on:
			_do_jump(delta) # Not running friction on ground if you press jump fast enough allows you to preserve all speed.
		else:
			_friction(delta, FRICTION_STRENGTH)
			_accelerate(delta, move_dir.normalized(), move_dir.length(), PLAYER_PARAMS.ACCELERATION)
	else: 
		_airaccelerate(delta, move_dir.normalized(), move_dir.length(), PLAYER_PARAMS.AIR_ACCELERATION)
	
	_camera_bob()

# Adds to the player's velocity based on direction, speed and acceleration.
func _accelerate(delta: float, wishdir: Vector3, wishspeed: float, accel: float) -> void:
	var addspeed : float
	var accelspeed : float
	var currentspeed : float
	
	# See if we are changing direction a bit
	currentspeed = velocity.dot(wishdir)
	
	# Reduce wishspeed by the amount of veer.
	addspeed = wishspeed - currentspeed
	
	# If not going to add any speed, done.
	if addspeed <= 0:
		return;
		
	# Determine the amount of acceleration.
	accelspeed = accel * wishspeed * delta
	
	# Cap at addspeed
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	# Adjust velocity.
	velocity += accelspeed * wishdir

# Adds to the player's velocity based on direction, speed and acceleration. 
# The difference between _accelerate() and this function is it caps the maximum speed you can accelerate to.
func _airaccelerate(delta: float, wishdir: Vector3, wishspeed: float, accel: float) -> void:
	var addspeed : float
	var accelspeed : float
	var currentspeed : float
	var wishspd : float = wishspeed
	
	if (wishspd > PLAYER_PARAMS.MAX_AIR_SPEED):
		wishspd = PLAYER_PARAMS.MAX_AIR_SPEED
	
	# See if we are changing direction a bit
	currentspeed = velocity.dot(wishdir)
	
	# Reduce wishspeed by the amount of veer.
	addspeed = wishspd - currentspeed
	
	# If not going to add any speed, done.
	if addspeed <= 0:
		return;
		
	# Determine the amount of acceleration.
	accelspeed = accel * wishspeed * delta
	
	# Cap at addspeed
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	# Adjust velocity.
	velocity += accelspeed * wishdir

# Applies friction to the player's horizontal velocity
func _friction(delta: float, strength: float) -> void:
	var speed = velocity.length()
	
	# Bleed off some speed, but if we have less that the bleed
	# threshold, bleed the threshold amount.
	var control =  PLAYER_PARAMS.STOP_SPEED if (speed < PLAYER_PARAMS.STOP_SPEED) else speed
	
	# Add the amount to the drop amount
	var drop = control * (PLAYER_PARAMS.FRICTION * strength) * delta
	
	# Scale the velocity.
	var newspeed = speed - drop
	
	if newspeed < 0:
		newspeed = 0
	
	if speed > 0:
		newspeed /= speed
	
	velocity.x *= newspeed
	velocity.z *= newspeed

# Crops velocity if above a speed threshold, not used if PLAYER_PARAMS.SPEED_CROP_MODE is set to NONE
func _scale_velocity() -> void:
	var spd : float
	var fraction : float
	var maxscaledspeed : float
	
	maxscaledspeed = PLAYER_PARAMS.SPEED_THRESHOLD_FACTOR * PLAYER_PARAMS.MAX_SPEED
	
	if (maxscaledspeed <= 0): 
		return
	
	spd = Vector3(velocity.x, 0.0, velocity.z).length()
	
	if (spd <= maxscaledspeed): return
	
	fraction = (maxscaledspeed / spd)
	
	velocity.x *= fraction
	velocity.z *= fraction

# Applies a jump force to the player.
func _do_jump(delta: float) -> void:
	# Apply the jump impulse
	velocity.y = sqrt(2 * PLAYER_PARAMS.GRAVITY * 1.143)
	
	# Add in some gravity correction
	velocity.y -= (PLAYER_PARAMS.GRAVITY * delta * 0.5 )
	
	# If the Player Parameters wants us to clip the velocity, do it.
	if (PLAYER_PARAMS.SPEED_CROP_MODE != PLAYER_PARAMS.SpeedCropMode.NONE):
		_scale_velocity()

# Handles crouching logic.
func _duck() -> void:
	var time : float
	var frac : float
	
	# Bring down the move direction to a third of it's speed.
	if ducked:
		move_dir *= PLAYER_PARAMS.DUCKING_SPEED_MULTIPLIER
	
	# If we aren't ducking, but are holding the "pm_duck" input...
	if duck_on:
		if !ducked and !ducking:
			ducking = true
			duck_timer.start(1.0)
		
		time = max(0, (1.0 - duck_timer.time_left))
		
		if ducking:
			if duck_timer.time_left <= 0.6 or !is_on_floor():
				# Set the collision hull and view offset to the ducking counterpart.
				player_hull.shape = BBOX_DUCKING
				offset = PLAYER_PARAMS.DUCK_VIEW_OFFSET
				ducked = true
				ducking = false
				
			# Move our character down in order to stop them from "falling" after crouching, but ONLY on the ground.
				if is_on_floor():
					position.y -= 0.457
			else:
				var fmore = 0.457
					
				frac = _spline_fraction(time, 2.5)
				offset = ((PLAYER_PARAMS.DUCK_VIEW_OFFSET - fmore ) * frac) + (PLAYER_PARAMS.VIEW_OFFSET * (1-frac))
	
	# Check for if we are ducking and if we are no longer holding the "pm_duck" input...
	if !duck_on and (ducking or ducked):
		# ... And try to get back up to standing height.
		_unduck()

# Checks to make sure uncrouching won't clip us into a ceiling.
func _unduck():
	if _unduck_trace(position + Vector3.UP * 0.458, BBOX_STANDING, self) == true:
		# If there is a ceiling above the player that would cause us to clip into it when unducking, stay ducking.
		ducked = true
		return
	else: # Otherwise, unduck.
		ducked = false
		ducking = false
		player_hull.shape = BBOX_STANDING
		offset = PLAYER_PARAMS.VIEW_OFFSET
		if is_on_floor(): position.y += 0.457

# Creates a sinusoidal camera bobbing motion whilst moving.
func _camera_bob():
	var bob : float
	var simvel : Vector3
	simvel = velocity
	simvel.y = 0
	
	if is_on_floor() && !jump_on:
		bob = lerp(0.0, sin(Time.get_ticks_msec() * PLAYER_PARAMS.BOB_FREQUENCY) / PLAYER_PARAMS.BOB_FRACTION, (simvel.length() / 2.0) / PLAYER_PARAMS.FORWARD_SPEED)
	else:
		bob = 0.0
	camera.position.y = lerp(camera.position.y, bob, 0.5)

# Returns true if the shape collision detects something above player.
# Kudos to Btan2 for the trace implementation, please give him some love: (https://github.com/Btan2/Q_Move/blob/main/addons/trace.gd)
# I am sorry I bastardized it, please forgive.
func _unduck_trace(origin : Vector3, shape : Shape3D, e) -> bool:
	var params
	var space_state
	
	params = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform.origin = origin
	params.collide_with_bodies = true
	params.exclude = [e]
	
	space_state = get_world_3d().direct_space_state
	var results : Array[Vector3] = space_state.collide_shape(params, 8)
	
	return results.size() > 0

# Returns a value for how much the camera should tilt to the side.
func _calc_roll(rollangle: float, rollspeed: float) -> float:
	
	var side = velocity.dot(head.transform.basis.x)
	
	var roll_sign = 1.0 if side < 0.0 else -1.0
	
	side = absf(side)
	
	var value = rollangle
	
	if (side < rollspeed):
		side = side * value / rollspeed
	else:
		side = value
	
	return side * roll_sign

# Creates a smooth interpolation fraction.
func _spline_fraction(_value: float, _scale: float) -> float:
	var valueSquared : float;

	_value = _scale * _value;
	valueSquared = _value * _value;

	return 3 * valueSquared - 2 * valueSquared * _value;
