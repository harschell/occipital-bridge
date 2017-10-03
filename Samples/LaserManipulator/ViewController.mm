/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ViewController.h"

#import <SceneKit/SceneKit.h>
#import <BridgeEngine/BridgeEngine.h>

// Bridge Open Source
#import <OpenBE/Core/SceneManager.h>
#import <OpenBE/Core/AudioEngine.h>
#import <OpenBE/Core/Scene.h>

#import <OpenBE/Components/SpawnComponent.h>
#import <OpenBE/Components/BridgeControllerComponent.h>

#import "Components/BridgeControllerManipulationComponent.h"
#import "Components/InputBeamComponent.h"
#import "Components/InteractablePhysicsComponent.h"
#import "Components/InteractableSpawnComponent.h"

#import <OpenBE/Utils/SceneKitExtensions.h>

@interface ViewController () <BEMixedRealityModeDelegate, BEControllerDelegate>
@property (nonatomic,strong) BridgeControllerManipulationComponent *controllerManipulationComponent;
@property (nonatomic,strong) InteractableSpawnComponent *spawnComponent;
@end

@implementation ViewController {
    BEMixedRealityMode* _mixedReality;
    BOOL                _experienceIsRunning;
    BOOL                _controllerConnected;
}

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Markup is optional physical annotations of a scanned scene, that persist between app launches.
    // We aren't using markup in this sample.
    
    BECaptureReplayMode replayMode = BECaptureReplayModeDisabled;
    if ([BEAppSettings booleanValueFromAppSetting:@"replayCapture"
             defaultValueIfSettingIsNotInBundle:NO])
    {
        replayMode = BECaptureReplayModeDeterministic;
    }
    
    _mixedReality = [[BEMixedRealityMode alloc]
                     initWithView:(BEView*)self.view
                     engineOptions:@{
                                     kBETrackerFallbackOnIMUEnabled:@(YES),
                                     kBECaptureReplayMode:
                                         @(replayMode),
                                     kBEUsingWideVisionLens:
                                         @([BEAppSettings booleanValueFromAppSetting:@"useWVL"
                                                defaultValueIfSettingIsNotInBundle:YES]),
                                     kBEStereoRenderingEnabled:
                                         @([BEAppSettings booleanValueFromAppSetting:@"stereoRendering"
                                                defaultValueIfSettingIsNotInBundle:YES]),
                                     kBEUsingColorCameraOnly:
                                         @([BEAppSettings booleanValueFromAppSetting:@"colorCameraOnly"
                                                defaultValueIfSettingIsNotInBundle:NO]),
                                     kBERecordingOptionsEnabled:
                                         @([BEAppSettings booleanValueFromAppSetting:@"enableRecording"
                                                defaultValueIfSettingIsNotInBundle:NO]),
                                     kBEEnableStereoScanningBeta:
                                         @([BEAppSettings booleanValueFromAppSetting:@"stereoScanning"
                                                defaultValueIfSettingIsNotInBundle:NO]),
                                     }
                     markupNames:nil
                     ];
    
    _mixedReality.delegate = self;
    [BEController sharedController].delegate = self;
    
    [_mixedReality start];
}

- (void)startExperience {
    
    // For this experience, let's switch to a mode with AR objects composited with the passthrough camera.
    
    [_mixedReality setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:0.5];
    _experienceIsRunning = YES;
    
    if (_controllerConnected) {
        [self.controllerManipulationComponent setEnabled:YES];
    }
    
    be_dbg("Experience Started");
}

- (void)setupWorld {
    
    // Setup the Scene and Audio Managers
    
    BOOL stereo = [BEAppSettings booleanValueFromAppSetting:@"stereoRendering" defaultValueIfSettingIsNotInBundle:YES];
    [[SceneManager main] initWithMixedRealityMode:_mixedReality stereo:stereo];
    [AudioEngine main];
    
    
    // Put the controller near the waist, on the right hand side.
    [BEController sharedController].offsetFromCamera = kBEControllerOffsetRightHandedTallerWaist;
    
    // Compose a SceneManager entity, add a BridgeControllerComponent (3D model) and other bits below.
    GKEntity *entity = [[SceneManager main] createEntity];
    BridgeControllerComponent *controllerComponent = [[BridgeControllerComponent alloc] init];
    [entity addComponent:controllerComponent];
    
    InputBeamComponent *beamComponent = [[InputBeamComponent alloc] init];
    beamComponent.startPos = GLKVector3Make(0, 0, 0);
    beamComponent.endPos = GLKVector3Make(0, 0, 1);
    [beamComponent start];
    [controllerComponent.node addChildNode:beamComponent.node];
    [entity addComponent:beamComponent];
    
    self.controllerManipulationComponent = [[BridgeControllerManipulationComponent alloc] init];
    [entity addComponent:self.controllerManipulationComponent];
    [self.controllerManipulationComponent start];
    
    // Create a ball spawner
    SCNNode *ballToSpawn = [SCNNode firstNodeFromSceneNamed:@"Objects/SphereToy.dae"];
    ballToSpawn.scale = SCNVector3Make(0.65, 0.65, 0.65);
    InteractablePhysicsComponent *ballComponent = [[InteractablePhysicsComponent alloc] initWithVisibleNode:ballToSpawn physicsGeometry:[SCNSphere sphereWithRadius:0.11]];
    
    self.spawnComponent = [[InteractableSpawnComponent alloc] init];
    self.spawnComponent.componentToSpawn = ballComponent;
    [[[SceneManager main] createEntity] addComponent:self.spawnComponent];
}

#pragma mark - BEMixedRealityModeDelegate

- (void) mixedRealitySensorsStatusChanged:(BESensorsStatus)sensorsStatus {
    if (sensorsStatus.allSensorsReady)
    {
        be_dbg("sensorStatus: OK");
    }
    else
    {
        be_dbg("sensorStatus: %s%s%s%s",
               sensorsStatus.needToConnectDepthSensor ? "[NeedToConnectDepthSensor]" : "",
               sensorsStatus.needToChargeDepthSensor ? "[NeedToChargeDepthSensor]" : "",
               sensorsStatus.needToRunCalibrator ? "[NeedToRunCalibrator]" : "",
               sensorsStatus.needToAuthorizeIOSCamera ? "[NeedToAuthorizeIOSCamera]" : "");
    }
}

- (void) mixedRealityMarkupDidChange:(NSString*)markupChangedName {
}

- (void) mixedRealityMarkupEditingEnded {
    [self startExperience];
}

- (void)mixedRealitySetUpSceneKitWorlds:(BEMappedAreaStatus)mappedAreaStatus {
    [self setupWorld];
    [self startExperience];
}

- (void) mixedRealityUpdateAtTime:(NSTimeInterval)time {
    // Update the controller's camera world transform, so we're tracking with it.
    [BEController sharedController].cameraTransform = SCNMatrix4ToGLKMatrix4(_mixedReality.localDeviceNode.worldTransform);

    // This updates all components
    [[SceneManager main] updateAtTime:time mixedRealityMode:_mixedReality];
}

#pragma mark - BEControllerDelegate

- (void)controllerDidConnect {
    [self.controllerManipulationComponent setEnabled:YES];
    be_dbg("Controller Connected");
    _controllerConnected = YES;
}

- (void)controllerDidDisconnect {
    [self.controllerManipulationComponent setEnabled:NO];
    be_dbg("Controller Disconnected");
    _controllerConnected = NO;
}

/* 
 Buttons returns correctly on the first down event, then they are switched and backwards from that point on.
 */
- (void)controllerButtons:(BEControllerButtons)buttons down:(BEControllerButtons)buttonsDown up:(BEControllerButtons)buttonsUp {
//    NSLog(@"buttons up: %d", buttonsUp);
//    NSLog(@"result: %d", (BEControllerButtonSecondary & buttonsUp));

    // Make manipulations, spawing etc, inline with the render thread.
    [_mixedReality runBlockInRenderThread:^{
        if ((BEControllerButtonSecondary & buttonsDown) == BEControllerButtonSecondary) {
            SCNVector3 intersectionPoint = self.controllerManipulationComponent.currentIntersectionPoint;
            if (intersectionPoint.x < INTERSECTION_FAR_DISTANCE) {
                [self.spawnComponent spawnWithPosition:SCNVector3Make(intersectionPoint.x,
                                                                      intersectionPoint.y - 0.3,
                                                                      intersectionPoint.z)];
            }
        }
        
        if( (buttonsDown & BEControllerButtonPrimary) != 0 ) {
            [self.controllerManipulationComponent setTriggerDown:YES];
        } else {
            if( (buttonsUp & BEControllerButtonPrimary) != 0 ) {
                [self.controllerManipulationComponent setTriggerDown:NO];
            }
        }
    }];
}

- (void)controllerMotionTransform:(GLKMatrix4)transform {
}

/* 
 Status doesn't work in this one. It's always IDLE.  Position returns (-1, -1) one last time
 on an up event. 
 */

- (void)controllerTouchPosition:(GLKVector2)position status:(BEControllerTouchStatus)status {
    [self.controllerManipulationComponent controllerTouchPosition:position status:status];
}

@end
