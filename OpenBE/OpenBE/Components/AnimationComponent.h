/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "../Core/Core.h"

@interface AnimationComponent : Component
<
    ComponentProtocol,
    SCNAnimatable
>

- (void) start;

/**
 * General purpose animation loading
 */ 
+ (CAAnimation*) animationWithSceneNamed:(NSString*)name;

// Convenience function for loading an animation, same as class method.
- (CAAnimation*) loadAnimationNamed:(NSString*)animName;

// This class implements the full SCNAnimatable protocol.
// - (void)addAnimation:(nonnull CAAnimation*)animation forKey:(NSString*)animKey;
// - (void)removeAllAnimations;
// - (void)removeAnimationForKey:(NSString *)key;
// etc...

@end
