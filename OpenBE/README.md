# Welcome to the Bridge Engine Open Source!

This is the beginning of the Bridge Engine Open Source Library. We're excited to involve the community in the future of the Bridge Enigne. 

## Overview  
This library is based on an [Entity-Component System](https://en.wikipedia.org/wiki/Entity%E2%80%93component%E2%80%93system). All these exmples below are included in **OpenBE** -- feel free to add your own! 

To use, just include the `OpenBE.framework` in your XCode Project. 

####  It starts with the SceneManager
The `SceneManager` controls all updates to the game, and knows about all Entities contained in it.

`[[SceneManager main] initWithMixedRealityMode:_mixedReality stereo:YES];`

#### Create an Entity
Ask the scene manager to give you a registered entity for customization.

`GKEntity *robotEntity = [[SceneManager main] createEntity];`

####  Add Components
This won't do anything yet, until you add components to the Entity. You will need a geometry component at a minimum to see something in the scene.
for Example: 

`_robot = [[RobotActionComponent alloc] init];
[robotEntity addComponent:_robot]; `

You will generally add many small Components to create complex behavior. See `Samples/Bridget/ViewController.h` for all the componennts we have delevoped.

#### Start

Finally, after everything is set up, call 

`[[SceneManager main] startWithMixedRealityMode:_mixedReality];`

which will call `start` on all registered entities.     

####  Update Loop

In the update loop, you must call :

`[[SceneManager main] updateAtTime:time andMixedRealityMode:_mixedReality];`

This updates all Entities, which will in turn, update their Components. 

For more information, read about `GKEntity` in [Apple's Documentation](https://developer.apple.com/reference/gameplaykit/gkentity).

A good overview of using this architecture for implementing IOS games can be found in the [GameplayKit Programming Guide](https://developer.apple.com/library/content/documentation/General/Conceptual/GameplayKit_Guide/EntityComponent.html#//apple_ref/doc/uid/TP40015172-CH6). 

## More is on the Way
We are still working on polishing more components to integrate with this library. Stay tuned for : 
 - Portal rendering
 - Javascript animation and interaction scripting environment
 - Enhanced Documentation

## Get Involved
Want to help us expand the capabilities of Bridge Engine? We'd love contributions in the form of pull requests. Soon, we will formalize how to best contribute to Bridge Engine, but feel free to contact us and get involved here on Github.
 
## Changelog

##### Version 0.1
- **Components for**
    - Pathfinding
    - Bridget Animation control
    - Model Spawning
    - Reticle + Gaze Selection UI
    - Selectable Models
    - Environment Scan Shaders
    - Buttons and Menus
 - **Core Functionality**
    - Audio Contoller
    - Event Manager
    - Scene and Camera Utilites
    - Core Motion 
- **Utilities**
    - Robust asset loading
    - Shader helpers
    - SceneKit + Bridge Engine interop: lighting, physics and more
 
