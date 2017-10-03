/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#define INTERSECTION_FAR_DISTANCE 100

#import <BridgeEngine/BridgeEngine.h>
#import <OpenBE/Core/ComponentProtocol.h>
#import <OpenBE/Core/Component.h>

/**
 `BridgeControllerManipulationComponent` is a component that manages the
 identifying and manipulating of objects that follow the
 'PhysicsEventComponentProtocol'.
 
 You are required to register as a delegate to BEController and pass button, motion transform, and trackpad events through this component for it to function.
 
 @warning When you call the start command, this component will look for the existence of the 'BridgeControllerComponenet' and the 'InputBeamComponent' on its entity and throw an assert if they are not found.
 */

@interface BridgeControllerManipulationComponent : Component

/**
 This will raycast from the current position + orientation and get the nearest intersection point available.
 
 If no intersection point is found, the vector will have an x/y/z of INTERSECTION_FAR_DISTANCE.
 */
- (SCNVector3)currentIntersectionPoint;

/// BEController Input Functions

/**
 The setTriggerDown: function is temporary and should be replaced by 
 - (void)controllerButtons:(BEControllerButtons)buttons down:(BEControllerButtons)buttonsDown up:(BEControllerButtons)buttonsUp;
 once the bugs are ironed out.
 */
- (void)setTriggerDown:(BOOL)down;
- (void)controllerTouchPosition:(GLKVector2)position status:(BEControllerTouchStatus)status;

@end
