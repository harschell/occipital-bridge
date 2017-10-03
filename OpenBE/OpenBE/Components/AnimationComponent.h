/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "../Core/Core.h"


/// Take care of animation starts/stops and graceful loading of animation groups exported
/// from 3D modelling software to Collada DAE file format.
///
/// Have a look at the Animation exporting workflow in the Maya Modo and Blender - Animation section in the wiki here:
/// https://github.com/OccipitalOpenSource/bridge-engine-beta/wiki/Documentation:-Getting-Started-with-Bridge-Engine
@interface AnimationComponent : Component
<
    ComponentProtocol,
    SCNAnimatable
>

- (void) start;

/// General purpose animation loading
+ (CAAnimation*) animationWithSceneNamed:(NSString*)name;

/// Convenience function for loading an animation, same as class method.
- (CAAnimation*) loadAnimationNamed:(NSString*)animName;

// This class passes through the full SCNAnimatable protocol
// to the RobotMeshControllerComponent.robotNode
//
// - (void)addAnimation:(nonnull CAAnimation*)animation forKey:(NSString*)animKey;
// - (void)removeAllAnimations;
// - (void)removeAnimationForKey:(NSString *)key;
// etc...

// Potentially this AnimationComponent could be associated with any GeometryComponent in the future.

@end
