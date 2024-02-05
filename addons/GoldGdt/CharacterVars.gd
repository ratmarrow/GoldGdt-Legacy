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

extends Resource
class_name CharacterVars
## Resource containing movement prameters for the GoldGdtMovement node.

@export_group("Configuration")
@export var AUTOHOP = false ## Tells the character to check for the jump action being held instead of pressed, which will make all jumps perfect bunny hops.

@export_group("Engine Dependant Variables")
@export var FORWARD_SPEED = 8.128 ## Forward and backward move speed. The default value equals 8.128 (or 320 Hammer units/inches).
@export var SIDE_SPEED = 8.128 ## Left and right move speed. The default value equals 8.128 (or 320 Hammer units/inches).
@export var MAX_AIR_SPEED = 0.762 ## The maximum speed you can accelerate to in the [method _airaccelerate] function. The default value equals 0.762 (or 30 Hammer units/inches).
@export var STOP_SPEED = 2.54 ## Speed threshold for stopping in the [method _friction] function. The default value equals 2.540 (or 100 Hammer units/inches).
@export var GRAVITY = 20.32 ## Speed of gravity. The default value equals 20.320 (or 800 Hammer units/inches).
@export var JUMP_HEIGHT = 1.143 ## Height of the player's jump. The default value equals 1.143 (or 45 Hammer units/inches).

@export_subgroup("Player Dimensions")
@export var HULL_STANDING_BOUNDS = Vector3(0.813, 1.829, 0.813) ## The dimensions of the player's collision hull while standing. The default dimensions are [0.813, 1.829, 0.813] (or [32, 72, 32] in Hammer units/inches).
@export var HULL_DUCKING_BOUNDS = Vector3(0.813, 0.914, 0.813) ## The dimensions of the player's collision hull while ducking. The default dimensions are [0.813, 0.914, 0.813] (or [32, 36, 32] in Hammer units/inches).
@export var VIEW_OFFSET = 0.711 ## How much the camera hovers from player origin while standing. The default value equals 0.711 (or 28 Hammer units/inches).
@export var DUCK_VIEW_OFFSET = 0.305 ## How much the camera hovers from player origin while crouching. The default value equals 0.305 (or 12 Hammer units/inches).

@export_group("Engine Agnostic Variables")
@export var ACCELERATION = 10.0 ## The base acceleration amount that is multiplied by [code]wishspeed[/code] inside of [method _accelerate]. The default value equals 10.
@export var AIR_ACCELERATION = 10.0 ## The base acceleration amount that is multiplied by [code]wishspeed[/code] inside of [method _airaccelerate]. The default value equals 10.
@export var FRICTION = 4.0 ## The multiplier of dropped speed when friction is acting on the player. The default value equals 4.
@export var DUCKING_SPEED_MULTIPLIER = 0.333; ## The multiplier placed on the player's desired input speed while ducking. The default value equals 0.333.

@export_subgroup("Camera")
@export var MOUSE_SENSITIVITY : float = 15.0 ## How fast the camera moves in response to player input. The default value equals 15.
@export var BOB_FREQUENCY : float = 0.008
@export var BOB_FRACTION : float = 12
@export var ROLL_ANGLE : float = 0.65
@export var ROLL_SPEED : float = 300
