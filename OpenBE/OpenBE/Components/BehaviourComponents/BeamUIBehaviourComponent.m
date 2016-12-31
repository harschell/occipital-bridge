/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BeamUIBehaviourComponent.h"
#import "LookAtCameraBehaviourComponent.h"
#import "../BeamComponent.h"
#import "../../Core/AudioEngine.h"
@import GLKit;

typedef NS_ENUM (NSUInteger, RobotBeamUIState) {
    BEAM_UI_LOOK_AT,
    BEAM_UI_BEAM
};

#define UI_DISTANCE (0.5f)
#define UI_DISTANCE_Y_SLOPE (.07f)
#define UI_LOOKAT_DURATION 0.3f
#define UI_ACTIVATION_DURATION 0.3f

@interface BeamUIBehaviourComponent ()
@property (weak) BeamComponent * beamComponent;
@property (atomic) RobotBeamUIState beamUIState;

@property (nonatomic, strong) AudioNode *menuOpenSound;
@property (nonatomic, strong) AudioNode *menuCloseSound;

@end

@implementation BeamUIBehaviourComponent

#pragma mark - Beam UI
bool menuSoundPlayed;
- (void) start {
    [super start];
    
    self.beamComponent = (BeamComponent *)[self.entity componentForClass:[BeamComponent class]];
    [self.beamComponent setEnabled:NO];
    [self.uiComponent setEnabled:NO];
    self.menuOpenSound = [[AudioEngine main] loadAudioNamed:@"Robot_MenuOpen.caf"];
    self.menuCloseSound = [[AudioEngine main] loadAudioNamed:@"Robot_MenuClose.caf"];
    menuSoundPlayed = NO;
}

- (void) runBehaviourFor:(float)seconds callback:(void (^)(void))callbackBlock {
    // Check if Robot is unfolded, if not then unfold her first.
    if( [self.getRobot isUnfolded] == NO) {
        return;
    }

    [[self getRobot] stopAllBehaviours];
    [[EventManager main] pauseGlobalEventComponents];

    LookAtCameraBehaviourComponent *component = (LookAtCameraBehaviourComponent *)[self.getRobot.entity componentForClass:[LookAtCameraBehaviourComponent class]];
    [component runBehaviourFor:UI_LOOKAT_DURATION callback:nil];
    self.beamUIState = BEAM_UI_LOOK_AT;

    [super runBehaviourFor:seconds callback:callbackBlock];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    // Get the main camera position
    // Calculate relative forward vector from camera to robot (** change this to relative to robot's forward vector)
//    GLKVector3 cameraPos = [Camera main].position;
    
    GLKVector3 robotSensorPos = [[self getRobot] getBeamStartPosition];
    GLKVector3 robotFwd = [self.meshController getForward]; //GLKVector3Normalize(GLKVector3Subtract( [self.meshController getPosition], cameraPos ));

    // Calculate the facing angle along level axis, used for rotating the UI component into the right facing angle.
//    float rot = atan2f( robotFwd.z, robotFwd.x );
    
    // Project the UI Distance from camera position.
    GLKVector3 uiFwd = GLKVector3MultiplyScalar(robotFwd, UI_DISTANCE);
    GLKVector3 uiPos = GLKVector3Add(robotSensorPos, uiFwd);
    uiPos.y -= UI_DISTANCE_Y_SLOPE * UI_DISTANCE;
    
    // Adjust look at to fixed height relative to robot.
//    GLKVector3 lookatPos = cameraPos;
//    lookatPos.y = uiPos.y;
//    [self.meshController lookAt:lookatPos rotateIn:UI_ACTIVATION_DURATION];
    
    self.uiComponent.node.position = SCNVector3FromGLKVector3( uiPos );
    self.uiComponent.node.eulerAngles = SCNVector3Make( -M_PI_4, 0, 0 );
    
    self.beamComponent.startPos = robotSensorPos; //[[self getRobot] getBeamStartPosition];
    
    self.beamComponent.endPos = uiPos;
    
    if( self.timer > UI_LOOKAT_DURATION && self.beamUIState == BEAM_UI_LOOK_AT ) {
        self.beamUIState = BEAM_UI_BEAM;
    }
    
    if( self.beamUIState == BEAM_UI_BEAM ) {
        [self.beamComponent setEnabled:YES];
        [self.uiComponent setEnabled:YES];
        
        if(!menuSoundPlayed) {
            [self.menuOpenSound play];
            menuSoundPlayed = YES;
        }
        
        float active = MAX(0.f,MIN(1.f, (self.timer-UI_LOOKAT_DURATION)/UI_ACTIVATION_DURATION));
        
        [self.beamComponent setActive:active*.075f beamWidth:.1f * (float)[self.uiComponent activeButtonsCount] beamHeight:.05f*active];
        self.uiComponent.node.opacity = active * .5f;
    } else {
        [self.beamComponent setEnabled:NO];
        [self.uiComponent setEnabled:NO];
    }
}

- (void) stopRunning {
    [super stopRunning];
    
    [self.beamComponent setEnabled:NO];
    [self.uiComponent setEnabled:NO];
    
    [self.menuCloseSound play];
    menuSoundPlayed = NO;

    [[EventManager main] resumeGlobalEventComponents];
}

#pragma mark - EvenComponent

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( [self isRunning] ) {
        [self stopRunning];
    } else {
        [self runBehaviourFor:0.f callback:nil];
    }
    
    return YES;
}

- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

@end
