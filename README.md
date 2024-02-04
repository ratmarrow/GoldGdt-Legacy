# GoldGdt
![goldgdtorng](https://github.com/ratmarrow/GoldGdt/assets/155324574/f1d5fdaf-40c7-443f-a8c5-f41cb487ecc0)

GoldGdt intends to be an accurate port of the GoldSrc movement code into Godot 4.

## Changelog

### Update 3.1
- Fixed a bug with the camera rotation clamp causing the camera to flip around when looking directly up or down.

## Roadmap

- Relocating movement variables into Resources.
- Detection and response for stair-like geometry.
- Creating a system for ladder and water movement.
- Viewmodel system (maybe).

## Installation

### From GitHub:
1. Open your Godot project.
2. Copy the 'addons' folder from this repository into the project folder for your Godot project.
3. Drop the 'Player' scene found in the add-on into whatever scenes you need it in.

## Setup

### Input Map

GoldGdt has pre-defined inputs that it is programmed around. Unless you want to go into the code and change them to your own input mappings, I recommend recreating these inputs in your Project Settings, binding them to whatever you see fit.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/b9d3efcd-f289-4f23-8bd3-1486063fcf2a)


### Physics

The input and physics in the GoldGdtMovement.gd script are handled in `_physics_process()` to ensure that the movement feels consistent regardless of framerate.

The default physics update rate is 100 frames-per-second in order to make the physics behave like Half-Life 1 speedruns [as explained here](https://wiki.sourceruns.org/wiki/FPS_Effects), which in turn makes bunnyhopping faster. This can be changed by going into `Project Settings>Physics>Common`

![physics settings](https://github.com/ratmarrow/GoldGdt/assets/155324574/a0425b64-53ac-41d9-a086-19733971de95)
