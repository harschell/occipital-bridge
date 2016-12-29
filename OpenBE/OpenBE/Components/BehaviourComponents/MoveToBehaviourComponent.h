/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BehaviourComponent.h"

#define ROBOT_DEFAULT_MOVE_SPEED .8f

@interface MoveToBehaviourComponent : BehaviourComponent
@property(nonatomic) float speed;

- (float) durationToTarget:(GLKVector3) targetPosition;
- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock;
- (float) getIdleWeight;

@end
