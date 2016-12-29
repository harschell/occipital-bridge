/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "LookAtCameraBehaviourComponent.h"
#import "../RobotMeshControllerComponent.h"

#define LOOK_DEFAULT_DURATION 0.25

@interface LookAtCameraBehaviourComponent ()
@property(nonatomic) NSTimeInterval nextRegargettingTime;
@end

@implementation LookAtCameraBehaviourComponent

#pragma mark - lookAt Camera

- (void) runBehaviourFor:(float)seconds callback:(void (^)(void))callbackBlock {
    [super runBehaviourFor:seconds callback:callbackBlock];

    GLKVector3 target = [Camera main].position;
    [self.meshController lookAt:target rotateIn:MIN(seconds, LOOK_DEFAULT_DURATION)];
    self.meshController.looking = YES;
    self.meshController.lookAtCamera = YES; // Continuous re-targetting to camera
}

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock {
    NSAssert( NO, @"Invalid Call");
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    if( self.timer > self.intervalTime ) {
        self.meshController.looking = NO;
        [self stopRunning];
    }
}

@end
