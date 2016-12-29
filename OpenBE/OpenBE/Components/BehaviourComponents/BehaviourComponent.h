/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../../Core/Core.h"
#import "../../Core/Component.h"
#import "../RobotBehaviourComponent.h"
#import "../RobotMeshControllerComponent.h"

@interface BehaviourComponent : Component <ComponentProtocol>

// Interval of this behaviour's planned execution.
@property (atomic) float intervalTime;

// Timer that counts up over the component's execution.
@property (atomic) float timer;

// (optional) Target position for a component's action.
@property (atomic) GLKVector3 targetPosition;

- (id) initWithIdleWeight:(float)weight andAllowCameraMovementTriggerAttention:(bool)allowAttention;
- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock;
- (void) runBehaviourFor:(float)seconds callback:(void (^)(void))callbackBlock;
- (float) getIdleWeight;
- (bool) isRunning;
- (bool) allowCameraMovementTriggerAttention;
- (void) stopRunning;
- (RobotBehaviourComponent *) getRobot;
- (RobotMeshControllerComponent*) meshController;

@end
