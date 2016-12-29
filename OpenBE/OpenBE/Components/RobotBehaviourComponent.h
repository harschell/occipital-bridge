/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GamePlayKit/GamePlayKit.h>
#import <SceneKit/SceneKit.h>

#import "../Core/Core.h"
#import "NavigationComponent.h"

@interface RobotBehaviourComponent : Component <ComponentProtocol>

@property (strong) NavigationComponent * navigationComponent;

- (void) start;

- (bool) isIdle;
- (void) runIdleBehaviours:(bool)runIdle;
- (void) cameraMovementTriggerAttention:(bool)triggerAttention;

- (void) stopAllBehaviours;

// add point of interest. Robot will look at position if idle
- (void) addPointOfInterest:(GLKVector3)lookAtPosition;

// start different behaviours - wrapper, you could also call the corresponding component direct
- (void) startScan:(GLKVector3)targetPosition;
- (void) startMoveTo:(GLKVector3)targetPosition;
- (void) startLookAtNode:(SCNNode *)node;
- (void) startLookAtMainCamera;
- (void) startLookAtPosition:(GLKVector3)targetPosition;

// mesh wrappers
- (BOOL) isUnfolded;

- (GLKVector3) getPosition;
- (GLKVector3) getBeamStartPosition;
- (GLKVector3) getEyePosition;
- (GLKVector3) getForward;
- (GLKVector3) getBodyPosition;

- (void) doDance; // Do the dance.
- (void) beHappy; // Play a happy squee expression.
- (void) beSad; // Play a sad expression.

- (void) bePowerDown; // Switch to low power mode.
- (void) bePowerUp; // Switch to charged power up mode.

// Expose the battery level from RobotBodyEmojiComponent.
/**
 * Show this battery level when idle.
 * 0 is empty to 4 is full
 * -1 or outside of range, shows blank battery status.
 */
@property(nonatomic) int batteryLevel;

//- (void) lookAt:(GLKVector3)lookAtPosition;
//- (void) lookAt:(GLKVector3)lookAtPosition rotateIn:(float)seconds;
//- (void) moveTo:(GLKVector3)moveToTarget moveIn:(float)seconds;

@end
