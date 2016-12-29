/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "LookAtNodeBehaviourComponent.h"
#import "../RobotMeshControllerComponent.h"
#import "../../Utils/Math.h"
@import GLKit;

#define LOOKAT_RETARGET_DURATION 0.25
#define LOOKAT_RETARGET_DELAY 0.1

@interface LookAtNodeBehaviourComponent()
@property(nonatomic) NSTimeInterval nextRegargettingTime;
@end

@implementation LookAtNodeBehaviourComponent

#pragma mark - lookAt Node

- (void) runBehaviourFor:(float)seconds lookAtNode:(SCNNode *)targetNode callback:(void (^)(void))callbackBlock{
    [super runBehaviourFor:seconds callback:callbackBlock];
    self.targetNode = targetNode;
    self.meshController.looking = YES;
    self.meshController.lookAtCamera = NO;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    if( self.timer >= self.intervalTime ) {
        self.meshController.looking = NO;
        self.nextRegargettingTime = 0;
        [self stopRunning];
    }
    
    self.nextRegargettingTime -= seconds;
    if( self.nextRegargettingTime <= 0 ) {
        self.nextRegargettingTime += LOOKAT_RETARGET_DELAY;
        GLKVector3 target = SCNVector3ToGLKVector3(self.targetNode.presentationNode.position);
        [self.meshController lookAt:target rotateIn:LOOKAT_RETARGET_DURATION];
    }
}

@end
