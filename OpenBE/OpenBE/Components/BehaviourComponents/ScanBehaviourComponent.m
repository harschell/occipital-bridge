/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ScanBehaviourComponent.h"
#import "../RobotMeshControllerComponent.h"
#import "../BeamComponent.h"
#import "../ScanComponent.h"
#import "../../Utils/Math.h"
@import GLKit;

#define ROBOT_LOOK_DURATION 0.4f
#define ROBOT_TRACKING_LOOK_DURATION 0.0f  // can be zero because the targetposition will change smooth
                                            // in scaneventcomponent

typedef NS_ENUM (NSUInteger, RobotScanState) {
    SCAN_LOOK_AT,
    SCAN_SCAN
};

@interface ScanBehaviourComponent()
@property (weak) BeamComponent * beamComponent;
@property (weak) ScanComponent * scanComponent;
@property (atomic) float scanRadius;
@property (atomic) RobotScanState scanState;
@end

@implementation ScanBehaviourComponent

- (void) start {
    [super start];

    self.scanComponent = ((ScanComponent *)[self.entity componentForClass:[ScanComponent class]]);
    self.beamComponent = ((BeamComponent *)[self.entity componentForClass:[BeamComponent class]]);
    self.scanRadius = 2.0;
    [self.beamComponent setEnabled:NO];
}

- (void) setTargetPosition:(GLKVector3)targetPosition {
    [super setTargetPosition:targetPosition];
    if( self.isRunning ) {
        if( _scanState == SCAN_LOOK_AT ) {
            [self.meshController lookAt:targetPosition rotateIn:MAX(ROBOT_LOOK_DURATION - self.timer, ROBOT_TRACKING_LOOK_DURATION)];
        } else {
            [self.meshController lookAt:targetPosition rotateIn:ROBOT_TRACKING_LOOK_DURATION];
        }
    }
}


#pragma mark - Scan

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock {
    [self runBehaviourFor:seconds targetPosition:targetPosition radius:.75f callback:callbackBlock];
}

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition radius:(float)radius callback:(void (^)(void))callbackBlock {
    [super runBehaviourFor:seconds targetPosition:targetPosition callback:callbackBlock];
    
    self.scanRadius = radius;
    self.scanState = SCAN_LOOK_AT;

    [self.meshController lookAt:targetPosition rotateIn:ROBOT_LOOK_DURATION];
    self.meshController.looking = YES;
    self.meshController.lookAtCamera = NO;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    if( self.timer > ROBOT_LOOK_DURATION && self.scanState == SCAN_LOOK_AT ) {
        self.scanState = SCAN_SCAN;
        
        // perform scan
        [self.scanComponent startScan:true atPosition:self.targetPosition duration:self.intervalTime-1.f radius:_scanRadius];
    }
    
    // Keep tracking where our target is.
    self.scanComponent.scanOrigin = self.targetPosition;
    
    if( self.timer > ROBOT_LOOK_DURATION && self.scanState == SCAN_SCAN ) {
        if( self.timer < self.intervalTime - ROBOT_LOOK_DURATION ) {
            self.beamComponent.startPos = [[self getRobot] getBeamStartPosition];
            self.beamComponent.endPos = self.targetPosition;
            
            float fadeIn = saturatef( (self.timer - ROBOT_LOOK_DURATION)*2.f );
            float fadeOut = 1.-saturatef( (self.intervalTime - self.timer - ROBOT_LOOK_DURATION)*2.f );
            float radius = (fadeIn-fadeOut) * .05f;
            [self.beamComponent setEnabled:YES];
            [self.beamComponent setActive:(fadeIn+fadeOut)*.5 beamWidth:radius beamHeight:radius];
        } else {
            [self.beamComponent setEnabled:NO];
        }
    }
    
    if(  self.timer >= self.intervalTime && self.scanState == SCAN_SCAN ) {
        [[self getRobot] addPointOfInterest:self.targetPosition];
        // done with scanning
        [self stopRunning];
    }
}

- (void) stopRunning {
    [super stopRunning];
    
    self.meshController.looking = NO;
   [self.beamComponent setEnabled:NO];
}

- (RobotMeshControllerComponent*) meshController {
    RobotMeshControllerComponent *controller = (RobotMeshControllerComponent*)[self.getRobot.entity componentForClass:RobotMeshControllerComponent.class];
    return controller;
}

@end
