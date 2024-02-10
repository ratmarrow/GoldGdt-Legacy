# GoldGdt
![goldgdtorng](https://github.com/ratmarrow/GoldGdt/assets/155324574/f1d5fdaf-40c7-443f-a8c5-f41cb487ecc0)

GoldGdt intends to be an accurate port of the GoldSrc movement code into Godot 4.

## Changelog

### Update 6.0

- [3rd-Party-Guy](https://github.com/3rd-Party-Guy) found and fixed an oversight where the camera roll function was using magic numbers instead of the defined Player Parameters for camera roll.
- Implemented third person camera functionality.
  - New Player Parameters for desired camera distance and offset.
  - Currently no native support for switching to 3P models -as it was out of scope for the update. I have plans for it as an ancillary update in the future.
- Implemented an optional bunny-hop cap toggle.
  - New Player Parameters for the way your velocity gets cropped and a multiplier for how fast above normal speed you can have when performing a jump.
  - Currently, the "GoldSrc accurate" version of the bunny-hop cap isn't implemented. I plan to add a version of it that doesn't have magic values.

## Roadmap

- Detection and response for stair-like geometry.
- Creating a system for ladder and water movement.
- Viewmodel system (ancillary change).
- 1P/3P model swapping system (ancillary change).
- Refactor for a composition-based architecture (Only when fully feature complete).

## Installation

### From GitHub:
1. Open your Godot project.
2. Copy the "addons" folder from this repository into the project folder for your Godot project.
3. Enable "GoldGdt Character Controller" in your project's addon page.
4. Reload your project.
5. Drop the "Player" scene found in the add-on into whatever scenes you need it in.

## Setup

### Input Map

GoldGdt has pre-defined inputs that it is programmed around. Unless you want to go into the code and change them to your own input mappings, I recommend recreating these inputs in your Project Settings, binding them to whatever you see fit.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/2bdd25bc-d9bf-41f4-acd9-6e9c4e38e9ae)

### Physics

The input and physics in the GoldGdtMovement.gd script are handled in `_physics_process()` to ensure that the movement feels consistent regardless of framerate.

In GoldGdt, your physics framerate *does* matter. This is intended, as GoldSrc physics were tied to the application's framerate.

The image below shows what physics settings I developed GoldGdt on, but you can change it to your liking.

I recommend turning off Physics Jitter Fix.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/f2511d83-2e6f-4ea8-87fe-a987c41bf589)

### Player Parameter Resources

You are able to create a custom Player Parameters resource either locally in the Player scene, or in your directory by right-clicking FileSystem and creating a new resource.
Search for "PlayerParameters" and it should show up.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/c264d522-ae64-4437-af59-4c4047ac69a3)

When editing your custom parameters, BE AWARE that Godot uses meters, and GoldSrc games like Half-Life use inches.

All the values that need to be in meters are under the "Engine Dependant Variables" category.

![image](https://github.com/ratmarrow/GoldGdt/assets/155324574/a05dbf39-9105-4820-a22a-b51dfa5410da)
