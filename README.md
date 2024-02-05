# GoldGdt
![goldgdtorng](https://github.com/ratmarrow/GoldGdt/assets/155324574/f1d5fdaf-40c7-443f-a8c5-f41cb487ecc0)

GoldGdt intends to be an accurate port of the GoldSrc movement code into Godot 4.

## Changelog

### Update 5.0

- Actually set up the GoldGdt folder to be a plugin, because by some miracle I managed to forget that.
- Added a neat little icon to the Player Parameters resource.

## Roadmap

- Detection and response for stair-like geometry.
- Creating a system for ladder and water movement.
- Viewmodel system (maybe).

## Installation

### From GitHub:
1. Open your Godot project.
2. Copy the "addons" folder from this repository into the project folder for your Godot project.
3. Enable "GoldGdt Character Controller" in your project's addon page.
4. Drop the "Player" scene found in the add-on into whatever scenes you need it in.

## Setup

### Input Map

GoldGdt has pre-defined inputs that it is programmed around. Unless you want to go into the code and change them to your own input mappings, I recommend recreating these inputs in your Project Settings, binding them to whatever you see fit.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/2bdd25bc-d9bf-41f4-acd9-6e9c4e38e9ae)

### Physics

The input and physics in the GoldGdtMovement.gd script are handled in `_physics_process()` to ensure that the movement feels consistent regardless of framerate.

The default physics update rate is 100 frames-per-second in order to make the physics behave like Half-Life 1 speedruns [as explained here](https://wiki.sourceruns.org/wiki/FPS_Effects), which in turn makes bunnyhopping faster. This can be changed by going into `Project Settings>Physics>Common`

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/f2511d83-2e6f-4ea8-87fe-a987c41bf589)

### Player Parameter Resources

You are able to create a custom Player Parameters resource either locally in the Player scene, or in your directory by right-clicking FileSystem and creating a new resource.
Search for "PlayerParameters" and it should show up.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/c264d522-ae64-4437-af59-4c4047ac69a3)

When editing your custom parameters, BE AWARE that Godot uses meters, and GoldSrc games like Half-Life use inches.

All the values that need to be in meters are under the "Engine Dependant Variables" category.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/a05dbf39-9105-4820-a22a-b51dfa5410da)
