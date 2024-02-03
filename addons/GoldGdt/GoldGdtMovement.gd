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
#	"GoldGdt" is an attempt at faithfully recreating the movement seen in GoldSrc games like Half-Life, Team Fortress: Classic, and Counter-Strike 1.6.
#	Thank you for using GoldGdt, and happy developing!
#	
#	- ratmarrow <3

extends CharacterBody3D

#region Variables
# A "Hammer Unit" (Quake, GoldSrc, etc.) is 1 inch.
# multiply Godot units (meters) by this to get the Hammer unit conversion,
# divide Hammer units by this to get the Godot unit conversion.
const HAMMERUNIT = 39.37 

# Debug

@onready var start_pos : Vector3 = position

# Player Input

var input_vector : Vector2 = Vector2.ZERO
var move_dir : Vector3 = Vector3.ZERO
var jump_on : bool = false
var duck_on : bool = false

# Player Movement

# Common movement speeds include:
# 250 HU (6.350m) (Counter-Strike)
# 320 HU (8.128m) (Half-Life)
# 400 HU (10.160m) (Quake/Deathmatch Classic)
const FORWARD_SPEED = 8.128 # Forward and backward move speed, measured in meters
const SIDE_SPEED = 8.128 # Left and right move speed, measured in meters

const WALKACCEL = 10.0 # Ground acceleration multiplier, engine agnostic
const MAXAIRSPEED = 0.762 # The maximum speed you can accelerate to in the _airaccelerate() function, measured in meters (30 HU)
const AIRACCEL = 10.0 # Air acceleration multiplier, engine agnostic
const FRICTION = 4.0 # Friction multiplier, engine agnostic
const STOPSPEED = 2.54 # Speed threshold for stopping in the _friction() function, measured in meters (100 HU)
const GRAVITY = 20.32 # Speed of gravity, measured in meters (800 HU)
const JUMPHEIGHT = 1.143 # Height of the player's jump, measured in meters (45 HU)
const DUCKINGSPEEDMULTIPLIER = 0.333; # Value to multiply move_dir by when crouching, engine agnostic

var FRICTION_STRENGTH = 1.0 # How much the overall friction calculation applies to your velocity. Not constant to allow for surface-based changes.

# Player State
@export var duck_timer : Timer
var ducked : bool = false
var ducking : bool = false

# Player Dimensions
# Currently, the player uses a capsule collision hull, which isn't accurate to GoldSrc. This was because I ran into issues with slop movement
# using a Box Shape, but I am keeping the code like this in the even either someone can make Box Shape work, or if it's just a bug with Godot Physics.

const BBOX_STANDING_BOUNDS = Vector3(0.813, 1.829, 0.813) # 32 HU x 72 HU x 32 HU
const BBOX_DUCKING_BOUNDS = Vector3(0.813, 0.914, 0.813) # 32 HU x 36 HU x 32 HU
const VIEW_OFFSET = 0.711 # How much the camera hovers from player origin while standing, measured in meters (28 HU)
const DUCK_VIEW_OFFSET = 0.305 # How much the camera hovers from player origin while crouching, measured in meters(12 HU)

var BBOX_STANDING = BoxShape3D.new() 
var BBOX_DUCKING = BoxShape3D.new() 

@export var player_hull : CollisionShape3D

# Player Camera

var mouse_sensitivity : float = 15.0
var head_resting_position : Vector3
var offset : float = 0.711
var look_input : Vector2

var prev_headtrans : Transform3D
var curr_headtrans : Transform3D

var camera_bob_freq : float = 0.008
var camera_bob_amp : float = 12

# FIXME: This can be handled leagues better than I handled it.
@export var head : Node3D # Used for rotating the input_vector to where you are facing
@export var vision : Node3D # Used for looking up and down in order to avoid any contamination in the input process
@export var camera : Node3D # Used for the _calc_roll() function to avoid any contamination in the input process

# UI

@export var speedometer : Label
@export var info : Label

# Configuration

## Allows holding down the "pm_jump" input to jump the moment you hit the ground
var autohop : bool = true 
#endregion

# Using _ready() to initialize variables
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set bounding box dimensions.
	BBOX_STANDING.size = BBOX_STANDING_BOUNDS
	BBOX_DUCKING.size = BBOX_DUCKING_BOUNDS
	
	prev_headtrans.origin = global_position + (Vector3.UP * offset)
	curr_headtrans.origin = global_position + (Vector3.UP * offset)
	
	# Set hull and head position to default.
	player_hull.shape = BBOX_STANDING
	offset = VIEW_OFFSET

# Using _input() to handle collecting mouse input
func _input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			look_input.x = event.relative.x
			look_input.y = event.relative.y
			_handle_camera()

# Using _process() to handle camera look logic
func _process(delta):
	# Camera logic
	head_resting_position = prev_headtrans.interpolate_with(curr_headtrans, clamp(Engine.get_physics_interpolation_fraction(), 0, 0.925)).origin
	head.global_position = head_resting_position
	
	#region Character Info UI, remove if deemed necessary
	var speed_format = "%s in/s (goldsrc)\n%s m/s (godot)"
	var speed_string = speed_format % [str(roundi((Vector3(velocity.x * HAMMERUNIT, 0.0, velocity.z * HAMMERUNIT).length()))), str(roundi((Vector3(velocity.x, 0.0, velocity.z).length())))]
	speedometer.text = speed_string
	
	var info_format = "rendering fps: %s\nframetime: %s\npos (meters): %s\nvel (meters): %s\ngrounded: %s\ncrouching: %s"
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
	# FIXME: Debug code that teleports you to start_pos in case you fall out of map.
	# Remove this condition and the action "debug_respawn" as you see fit.
	if Input.is_action_just_pressed("debug_respawn"):
		get_tree().quit()
	
	_handle_input()
	_handle_movement(delta)
	_handle_collision()
	
	prev_headtrans.origin = curr_headtrans.origin
	curr_headtrans.origin = global_position + (Vector3.UP * offset)
	vision.rotation.z = _calc_roll(0.6, 200)

func _handle_camera() -> void:
	head.rotate_y((-look_input.x * mouse_sensitivity) * 0.0001)
	vision.rotate_x((-look_input.y * mouse_sensitivity) * 0.0001)
	vision.rotation.x = clamp(vision.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	look_input = Vector2.ZERO

# Intercepts CharacterBody3D collision logic a bit to add slope sliding, recreating surfing.
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
	var ix = Input.get_action_raw_strength("pm_moveright") - Input.get_action_raw_strength("pm_moveleft")
	var iy = Input.get_action_raw_strength("pm_movebackward") - Input.get_action_raw_strength("pm_moveforward")
	input_vector = Vector2(ix, iy).normalized()
	move_dir = head.transform.basis * Vector3(input_vector.x * SIDE_SPEED, 0, input_vector.y * FORWARD_SPEED)
	
	jump_on = Input.is_action_pressed("pm_jump") if autohop else Input.is_action_just_pressed("pm_jump")
	duck_on = Input.is_action_pressed("pm_duck")

# Handles movement and jumping physics
func _handle_movement(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Check for anything partaining to ducking every physics step
	_duck()
	
	# Check if we are on ground
	if is_on_floor():
		if jump_on:
			_do_jump(delta) # Not running friction on ground if you press jump fast enough allows you to preserve all speed
			#_airaccelerate(delta, move_dir.normalized(), move_dir.length(), AIRACCEL)
		else:
			_friction(delta, FRICTION_STRENGTH)
			_accelerate(delta, move_dir.normalized(), move_dir.length(), WALKACCEL)
	else: 
		_airaccelerate(delta, move_dir.normalized(), move_dir.length(), AIRACCEL)
	
	_camera_bob()

# Adds to the player's velocity based on direction, speed and acceleration.
func _accelerate(delta: float, wishdir: Vector3, wishspeed: float, accel: float):
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
func _airaccelerate(delta: float, wishdir: Vector3, wishspeed: float, accel: float):
	var addspeed : float
	var accelspeed : float
	var currentspeed : float
	var wishspd : float = wishspeed
	
	if (wishspd > MAXAIRSPEED):
		wishspd = MAXAIRSPEED
	
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
func _friction(delta: float, strength: float):
	var speed = velocity.length()
	
	# Bleed off some speed, but if we have less that the bleed
	# threshold, bleed the threshold amount.
	var control = STOPSPEED if (speed < STOPSPEED) else speed
	
	# Add the amount to the drop amount
	var drop = control * (FRICTION * strength) * delta
	
	# Scale the velocity.
	var newspeed = speed - drop
	
	if newspeed < 0:
		newspeed = 0
	
	if speed > 0:
		newspeed /= speed
	
	velocity.x *= newspeed
	velocity.z *= newspeed

# Applies a jump force to the player.
func _do_jump(delta: float) -> void:
	# Apply the jump impulse
	velocity.y = sqrt(2 * GRAVITY * 1.143)
	
	# Add in some gravity correction
	velocity.y -= (GRAVITY * delta * 0.5 )

# Handles crouching logic.
func _duck() -> void:
	var time : float
	var frac : float
	
	# Bring down the move direction to a third of it's speed.
	if ducked:
		move_dir *= DUCKINGSPEEDMULTIPLIER
	
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
				offset = DUCK_VIEW_OFFSET
				ducked = true
				ducking = false
				
			# Move our character down in order to stop them from "falling" after crouching, but ONLY on the ground.
				if is_on_floor():
					position.y -= 0.457
			else:
				var fmore = 0.457
					
				frac = _spline_fraction(time, 2.5)
				offset = ((DUCK_VIEW_OFFSET - fmore ) * frac) + (VIEW_OFFSET * (1-frac))
	
	# Check for if we are ducking and if we are no longer holding the "pm_duck" input...
	if !duck_on and (ducking or ducked):
		# ... And try to get back up to standing height.
		_unduck()

# Checks to make sure uncrouching won't clip us into a ceiling.
func _unduck():
	if _unduck_trace(position + Vector3.UP * 0.458, BBOX_STANDING, self) == true:
		ducked = true
		return
	else:
		ducked = false
		ducking = false
		player_hull.shape = BBOX_STANDING
		offset = VIEW_OFFSET
		if is_on_floor(): position.y += 0.457

func _camera_bob():
	var bob : float
	var simvel : Vector3
	simvel = velocity
	simvel.y = 0
	
	if is_on_floor() && !jump_on:
		bob = lerp(0.0, sin(Time.get_ticks_msec() * camera_bob_freq) / camera_bob_amp, (simvel.length() / 2.0) / FORWARD_SPEED)
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

func _spline_fraction(_value: float, _scale: float) -> float:
	var valueSquared : float;

	_value = _scale * _value;
	valueSquared = _value * _value;

	return 3 * valueSquared - 2 * valueSquared * _value;
