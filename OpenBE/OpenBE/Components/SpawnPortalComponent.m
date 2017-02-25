/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "SpawnPortalComponent.h"
#import "VRWorldComponent.h"
#import "RobotActionComponent.h"
@import GLKit;

//#define ENABLE_ROBOTROOM

@interface SpawnPortalComponent()
@property (nonatomic) bool pausing;
@property (nonatomic) BOOL ejectFromVR;
@end

@implementation SpawnPortalComponent

- (void) start {
    [super start];
    _pausing = YES;
}

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.portalComponent.isInsideAR == NO ) {
        // We're presently inside VR, enable emergency exit on button down.
        self.portalComponent.emergencyExitVR = YES;
    }

    return YES;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    // Release cancels the emergencyExitVR.
    if( self.portalComponent.emergencyExitVR ) {
        self.portalComponent.emergencyExitVR = NO;
    }

    if( [self.portalComponent isFullyClosed] == NO ) {
        be_dbg("touchEnded: Portal isn't fully closed!");
        if( self.portalComponent.isInsideAR == YES && _portalComponent.open ) {
            be_dbg("We're in AR so Re-close it.");
            [self.portalComponent closePortal];
        }
        return YES;
    }

    if(hit) {
        
        // Delay looking at the portal to avoid load and turn-around glitch.
        [_robotActionSequencer wait:0.2];
        
        GLKVector3 hitPos = SCNVector3ToGLKVector3(hit.worldCoordinates);

        //  Place a floor portal if hitNormal is an upward vector (roughly ±20°) near the ground.
        GLKVector3 hitNormal = SCNVector3ToGLKVector3(hit.worldNormal);
        GLKVector3 up = GLKVector3Make(0, -1, 0);
        float upThreshold = cos(20.0*M_PI/180); // ~0.94
        if( GLKVector3DotProduct(hitNormal, up) > upThreshold
           && hitPos.y > -0.2) {
            _vrWorldComponent.mode = VRWorldRobotRoom;
            [_vrWorldComponent setEnabled:YES];
            [_portalComponent openPortalOnFloorPosition:SCNVector3FromGLKVector3(hitPos)
                                           facingTarget:SCNVector3FromGLKVector3([Camera main].position)
                                              toVRWorld:_vrWorldComponent];
            
            // Look at the portal mid-height
            [_robotActionSequencer lookAtX:hitPos.x Y:-1.0 Z:hitPos.z];
        }
        else
        {
            _vrWorldComponent.mode = VRWorldBookstore;
            [_vrWorldComponent setEnabled:YES];
            [_portalComponent openPortalOnWallPosition:SCNVector3FromGLKVector3(hitPos)
                                            wallNormal:SCNVector3FromGLKVector3(hitNormal)
                                             toVRWorld:_vrWorldComponent];
            
            // Look at the portal center.
            [_robotActionSequencer lookAtX:hitPos.x Y:hitPos.y Z:hitPos.z];
        }
    }
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (void) setPause:(bool)pausing {
    _pausing = pausing;
    if( pausing ) {
        [self setEnabled:false];
        [_portalComponent closePortal];
    }
}

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
}


@end
