/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BehaviourComponent.h"

typedef void (^callback)(void);

@interface BehaviourComponent()

@property (atomic) float idleWeight;
@property (atomic) bool allowAttention;
@property (weak) RobotBehaviourComponent * robotBehaviourComponent;
@property (atomic) bool running;
@property (strong) callback callbackBlock;

@end

@implementation BehaviourComponent

- (id) initWithIdleWeight:(float)weight andAllowCameraMovementTriggerAttention:(bool)allowAttention {
    self = [super init];
    
    self.timer = 0.f;
    self.intervalTime = 0.f;
    self.idleWeight = weight;
    self.running = NO;
    self.allowAttention = allowAttention;
    
    return self;
}

- (void) start {
    [super start];
    
    self.robotBehaviourComponent = (RobotBehaviourComponent *)[self.entity componentForClass:[RobotBehaviourComponent class]];
}

- (bool) allowCameraMovementTriggerAttention {
    return self.allowAttention;
}

- (float) getIdleWeight {
    return self.idleWeight;
}

- (bool) isRunning {
    return self.running;
}

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock {
    if(![self isEnabled]) {
        NSLog(@"Component is disabled. Can't run %@", [self class]);
        return;
    }
    self.targetPosition = targetPosition;
    [self runBehaviourFor:seconds callback:callbackBlock];
}


- (void) runBehaviourFor:(float)seconds callback:(void (^)(void))callbackBlock {
    if(![self isEnabled]) {
        NSLog(@"Component is disabled. Can't run %@", [self class]);
        return;
    }
    
    if( [self isRunning] ) {
        [self stopRunning];
    }
    
    self.callbackBlock = callbackBlock;
    
    self.timer = 0.f;
    self.intervalTime = seconds;
    self.running = YES;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    self.timer += seconds;
}

- (void) stopRunning {
    self.running = NO;
    if( self.callbackBlock ) {
        callback callbackref = self.callbackBlock;
        
        self.callbackBlock = nil;
        
        callbackref();
    }
}

#pragma mark - Related Components

- (RobotBehaviourComponent *) getRobot {
    return self.robotBehaviourComponent;
}

- (RobotMeshControllerComponent*) meshController {
    RobotMeshControllerComponent *controller = (RobotMeshControllerComponent*)[self.getRobot.entity componentForClass:RobotMeshControllerComponent.class];
    return controller;
}



@end
