# GoldGdt
![goldgdtorng](https://github.com/ratmarrow/GoldGdt/assets/155324574/f1d5fdaf-40c7-443f-a8c5-f41cb487ecc0)

GoldGdt intends to be an accurate port of the GoldSrc movement code into Godot 4.

This is a project template that comes with the custom inputs and physics changes, and is the recommended version to reduce hiccups setting up GoldGdt.

## Changelog

### Update 3
- Changed the camera movement to be based in the `_input()` function alongside rewriting the camera position interpolation to use the physics interpolation fraction.

## How to setup

When downloading the foundation, you can simply open it using the Godot Launcher, and immediately start tinkering with it.

## How to update

Every update for GoldGdt going forward will be regarding scripts, so all you should have to do is replace the .gd files.

## Things to note

### Movement Physics

The input and physics in the GoldGdtMovement.gd script are handled in `_physics_process()` to ensure that the movement feels consistent regardless of framerate, which was a shortcoming of games like Half-Life 1.


The default physics update rate is 100 frames-per-second in order to make the physics behave like Half-Life 1 speedruns [as explained here](https://wiki.sourceruns.org/wiki/FPS_Effects), which in turn makes bunnyhopping faster. This can be changed by going into `Project Settings>Physics>Common`

![physics settings](https://github.com/ratmarrow/GoldGdt/assets/155324574/a0425b64-53ac-41d9-a086-19733971de95)
