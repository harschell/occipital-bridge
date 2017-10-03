/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <SceneKit/SceneKit.h>

/**
 `PhysicsEventComponentProtocol` is an interface that defines mixed-reality objects that can be  picked up and manipulated using somthing like the 'BridgeControllerManipulationComponent'.
 
  Objects should respond to gaze events to indicate they can be manipulated, and may want to enabled or disable certain physics attributes while held. (A good example is adding angular dampening to reduce rotation).
 */

@protocol PhysicsEventComponentProtocol

- (SCNNode *)node;
- (SCNPhysicsBody *)getPhysicsBody;

- (void) gazeStart:(SCNHitTestResult *)hit;
- (void) gazeStay:(SCNHitTestResult *)hit;
- (void) gazeExit;

- (void)heldStart;
- (void)heldEnded;

@end
