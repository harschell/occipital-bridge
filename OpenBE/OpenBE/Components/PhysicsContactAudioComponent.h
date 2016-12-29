/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "../Core/AudioEngine.h"
#import "../Core/Core.h"

/**
 * Tracking for a particular node contact and sound playback
 * with cool-down interval.
 */
@interface PhysicsContactAudio : NSObject
@property(nonatomic, copy) NSString *nodeName; // The scene's node to play this sound on.
@property(nonatomic, strong) AudioNode *audioNode; // The audio node playing the sound.
@property(nonatomic) NSTimeInterval bounceCoolOffTime;  // Interval to wait before re-triggering the sound effect.
@property(nonatomic) float minImpulse; // Minimum impulse threshold to consider playing the sound.
@property(nonatomic) float maxImpulse; // Upper max impulse threshold, for calculating peak volume.

- (instancetype) initWithNodeName:(NSString*)nodeName audioName:(NSString*)audioName;

/**
 * Reset the cooloff timer, so next bounce will always trigger.
 */
- (void) resetBounceCooloffTimer;

@end

@interface PhysicsContactAudioComponent : Component
<
    ComponentProtocol,
    SCNPhysicsContactDelegate
>

/**
 * Attach to the physicsWorld as the contact delegate.
 */ 
@property(nonatomic, weak) SCNPhysicsWorld *physicsWorld;

/**
 * Associate a node's contact with a particular sound effect
 */ 
- (PhysicsContactAudio*) addNodeName:(NSString*)nodeName audioName:(NSString*)audioName;

/**
 * Get the physics audio from node name.
 */
- (PhysicsContactAudio*) physicsAudioForNodeName:(NSString*)nodeName;

/**
 * Remove the physics audio node name.
 */ 
- (void) removeNodeName:(NSString*)nodeName;

@end
