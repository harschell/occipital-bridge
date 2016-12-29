/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/EventComponentProtocol.h"
#import "../Core/ComponentProtocol.h"
#import "../Core/Component.h"
#import "RobotBehaviourComponent.h"

@class PhysicsContactAudioComponent;
 
@interface SpawnComponent : Component <EventComponentProtocol, ComponentProtocol>

@property(nonatomic) float spawnDistanceAlongHitNormal;
@property(nonatomic) bool usePhysics;
@property(nonatomic, weak) RobotBehaviourComponent * robotBehaviourComponent;
@property(nonatomic, weak) PhysicsContactAudioComponent * physicsContactAudio;

- (void) start;

@end
