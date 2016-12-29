/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>

#import "GazePointerProtocol.h"
#import "../Core/Core.h"

@interface FixedSizeReticleComponent  : GeometryComponent <GazePointerProtocol, ComponentProtocol>

@property (nonatomic) float radius;
@property (nonatomic) float idleDistance;
@property (nonatomic) float dampFactor;

- (void) onGazeStart:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive;

- (void) onGazeStay:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive;

- (void) onGazeExit:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity;

@end
