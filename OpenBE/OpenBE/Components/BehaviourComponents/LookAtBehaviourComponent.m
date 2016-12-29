/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "LookAtBehaviourComponent.h"
#import "../RobotMeshControllerComponent.h"
#import "../../Utils/Math.h"
@import GLKit;

#define LOOKAT_RETARGET_DURATION 0.25

@interface LookAtBehaviourComponent()
@property(nonatomic) float lookAtMicroMovementTimer;
@property(nonatomic) float lookAtMicroMovementTimeInterval;
@end


@implementation LookAtBehaviourComponent

#pragma mark - lookAt

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3)target callback:(void (^)(void))callbackBlock {
    [super runBehaviourFor:seconds targetPosition:target callback:callbackBlock];

    [self.meshController lookAt:target rotateIn:seconds];
    self.meshController.looking = YES;
    self.meshController.lookAtCamera = NO;

    // randomize the micromovement idle timing.
    self.lookAtMicroMovementTimeInterval = .5f + .2f*random01();
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    // handle lookAt
    self.lookAtMicroMovementTimer += seconds;
    
    if( self.lookAtMicroMovementTimer > self.lookAtMicroMovementTimeInterval ) {
        self.lookAtMicroMovementTimeInterval = 2.5f + 2.5f*random01();
        self.lookAtMicroMovementTimer = 0.f;
        
        GLKVector3 newTarget = self.targetPosition;
        GLKVector3 forward = GLKVector3Subtract( [[self getRobot] getEyePosition], newTarget );
        
        float offset = .25f * GLKVector3Length(forward);
        newTarget.x += random11() * offset;
        newTarget.y += random11() * offset;
        newTarget.z += random11() * offset;
        [self.meshController lookAt:newTarget rotateIn:LOOKAT_RETARGET_DURATION];
//        NSLog(@"LaBC: Micro movement retargetting");
    }
    
    if( self.timer > self.intervalTime ) {
        self.meshController.looking = NO;
        [self stopRunning];
    }
}

@end
