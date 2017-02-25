/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ScanEventComponent.h"
#import "BehaviourComponents/ScanBehaviourComponent.h"
#import "ScanComponent.h"
#import "GazeComponent.h"
#import "../Utils/ComponentUtils.h"

@interface ScanEventComponent()
@property(nonatomic, strong) ScanBehaviourComponent *scanBehaviour;
@property(nonatomic, strong) ScanComponent *scanComponent;
@property(nonatomic) bool continueScaneWhileTouching;
@property(nonatomic) bool scanning, continueTrackingOnReticle;
@property(nonatomic) float scanTime;
@property(nonatomic) GLKVector3 targetPosition;
@property(nonatomic) GLKVector3 currentPosition;
@end


@implementation ScanEventComponent

- (void) start {
    [super start];
    
    self.scanBehaviour = (ScanBehaviourComponent *)[self.robotBehaviourComponent.entity componentForClass:[ScanBehaviourComponent class]];
    self.scanComponent = (ScanComponent *)[self.robotBehaviourComponent.entity componentForClass:[ScanComponent class]];
    
    self.continueScaneWhileTouching = YES;
}

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.continueScaneWhileTouching && hit ) {
        [self startScan:SCNVector3ToGLKVector3(hit.worldCoordinates)];
        self.scanning = YES;
        
        if( button ) {
            _continueTrackingOnReticle = true;
        } else {
            _continueTrackingOnReticle = false;
        }
    }
    return YES;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.scanning && hit && self.continueScaneWhileTouching ) {
        self.targetPosition = SCNVector3ToGLKVector3(hit.worldCoordinates);
    }

    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.continueScaneWhileTouching == NO ) {
        // Start scan on touch-up (old behaviour)
        [self startScan:SCNVector3ToGLKVector3(hit.worldCoordinates)];
    }
    
    self.scanning = NO;
    return YES;
}

- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    self.scanning = NO;
    return NO;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];
    
    if( self.scanning && self.continueScaneWhileTouching ) {
        self.scanTime += seconds;
        self.scanBehaviour.intervalTime = MAX( self.scanTime + 1., self.scanBehaviour.intervalTime );
        self.scanComponent.duration = self.scanBehaviour.intervalTime;
        
        if( self.continueScaneWhileTouching && _continueTrackingOnReticle ) {
            float maxDistance = GAZE_INTERSECTION_FAR_DISTANCE;
            SCNVector3 from = SCNVector3FromGLKVector3( [Camera main].position );
            SCNVector3 to = SCNVector3FromGLKVector3( GLKVector3Add( [Camera main].position, GLKVector3MultiplyScalar([Camera main].reticleForward, maxDistance) ) );
            
            if( !isnan(from.x)
             && !isnan(from.y)
             && !isnan(from.z) )
            {
                NSDictionary *hitTestOptions = @{
                    SCNHitTestSortResultsKey:@YES,
                    SCNHitTestBackFaceCullingKey:@NO
                };
                NSArray<SCNHitTestResult *> *hitTestResults = [[Scene main].scene.rootNode hitTestWithSegmentFromPoint:from toPoint:to options:hitTestOptions];
                SCNHitTestResult *nearest = nil;
                if( [hitTestResults count] ) {
                    for( SCNHitTestResult * result in [hitTestResults reverseObjectEnumerator] ) {
                        if( !(result.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) {
                            nearest = result;
                        }
                    }
                }
                
                if( nearest ) {
                    GLKVector3 nearestPoint = SCNVector3ToGLKVector3(nearest.worldCoordinates); 
                    NSLog(@"ScanEvent Tracking, distance: %f", GLKVector3Distance([Camera main].position, nearestPoint));
                    self.targetPosition = nearestPoint;
                }
            }
        }
        
        // lerp towards targetposition to get smooth rotations and movements
        self.currentPosition = GLKVector3Lerp( self.currentPosition, self.targetPosition, 1.f - powf(.05f, seconds) );
        [self.scanBehaviour setTargetPosition:self.currentPosition];
    }
}

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    if( !enabled ) {
        self.scanning = NO;
    }
}

- (void) startScan:(GLKVector3) targetPosition {
    [self.robotBehaviourComponent stopAllBehaviours];
    
    self.targetPosition = targetPosition;
    self.currentPosition = targetPosition;
    
    [self.scanBehaviour runBehaviourFor:2.f targetPosition:targetPosition callback:nil];
    self.scanTime = 0.f;
}

@end
