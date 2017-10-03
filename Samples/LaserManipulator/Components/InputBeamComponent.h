/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

#import <OpenBE/Core/CoreMotionComponentProtocol.h>
#import <OpenBE/Core/ComponentProtocol.h>
#import <OpenBE/Core/GeometryComponent.h>

#import "../Core/PhysicsEventComponentProtocol.h"


typedef NS_ENUM(NSUInteger, InputBeamState) {
    InputBeamStateIdle,
    InputBeamStateItemDetected,
    InputBeamStateActiveNoItem,
    InputBeamStateActiveItem
};

/**
 `InputBeamComponent` is a component that draws a beam used to identify, move, and throw components that follow 'PhysicsEventComponentProtocol'.
 
 @warning Make sure to call start() BEFORE you add this beam to a parent node.
 */
@interface InputBeamComponent : Component <ComponentProtocol>

@property (strong) SCNNode * node;

/**
 These properties are used to alter the beam's appearance.
 */
@property (atomic) float beamWidth;
@property (atomic) float beamHeight;
@property (atomic) GLKVector3 startPos;
@property (atomic) GLKVector3 endPos;

/**
 This will tell the beam to react to an event corresponding to the InputBeamState.
 @params state The current state to set the beam.
 
 @warning This will override current beamWidth and beamHeight properties.
*/
- (void)setBeamState:(InputBeamState)state;

@end
