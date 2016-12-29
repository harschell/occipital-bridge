/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "MoveToBehaviourComponent.h"
#import "../RobotMeshControllerComponent.h"
#import "../../Utils/Math.h"
@import GLKit;

#define ROBOT_LOOK_DURATION 0.2

@interface MoveToBehaviourComponent()
@property (atomic) float lookAtMicroMovementTimer;
@property (atomic) float lookAtMicroMovementTimeInterval;
@property (atomic) float movementCoolDown;
@property (atomic) GLKVector3 lookAtTargetLocation;
@end

@implementation MoveToBehaviourComponent

- (void) start {
    [super start];
    self.movementCoolDown = 0.f;
    self.speed = ROBOT_DEFAULT_MOVE_SPEED;
}

#pragma mark - moveTo

- (float) durationToTarget:(GLKVector3) targetPosition {
    float distance = GLKVector3Distance([[self getRobot] getPosition], targetPosition);
    return distance / _speed;
}

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock {
    [super runBehaviourFor:seconds targetPosition:targetPosition callback:callbackBlock];
    
    [self.meshController moveTo:targetPosition moveIn:seconds];
    
    GLKVector3 fwd = GLKVector3Normalize(GLKVector3Subtract(targetPosition, [[self getRobot] getPosition]));
    GLKVector3 projectedPosition = GLKVector3Add(targetPosition, fwd);
    projectedPosition.y = -0.5; // Make target eye-height for robot.
    self.targetPosition = projectedPosition;
    
    self.lookAtMicroMovementTimeInterval = 1.f;
    self.lookAtMicroMovementTimer = 0.f;
    [self.meshController lookAt:self.targetPosition rotateIn:ROBOT_LOOK_DURATION];
    self.meshController.looking = YES;
    self.meshController.lookAtCamera = NO;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    
    self.movementCoolDown -= seconds;
    
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    self.lookAtMicroMovementTimer += seconds;
    
    if( self.lookAtMicroMovementTimer > self.lookAtMicroMovementTimeInterval ) {
        self.lookAtMicroMovementTimeInterval = .5f + 1.f*random01();
        self.lookAtMicroMovementTimer = 0.f;
        
        GLKVector3 newTarget = self.targetPosition;
        
        newTarget.x += .1f*random01();
        newTarget.y += .1f*random01();
        newTarget.z += .1f*random01();
        
        [self.meshController lookAt:newTarget rotateIn:ROBOT_LOOK_DURATION];
    }
    
    if( self.timer > self.intervalTime ) {
        self.meshController.looking = NO;
        [self stopRunning];
    }
}

- (float) getIdleWeight {
    if( self.movementCoolDown > 0.f ) return 0.f;
    
    return [super getIdleWeight];
}

@end
