/*
This file is part of the Structure SDK.
Copyright © 2016 Occipital, Inc. All rights reserved.
http://structure.io
*/

#import "ViewController.h"
#import "AppSettings.h"

#import <BridgeEngine/BridgeEngine.h>
#import "CustomRenderMode.h"
#import <cassert>

#import <OpenBE/Components/RobotBehaviourComponent.h>
#import <OpenBE/Components/RobotActionComponent.h>
#import <OpenBE/Components/SpawnPortalComponent.h>

#import "WindowComponent.h"
#import "OutsideWorldComponent.h"

//------------------------------------------------------------------------------

#define ASSETS_DIR "Assets.scnassets" // The SceneKit assets root folder.

// Since -Y is up in Bridge Engine convention, the pivot rotates from the typical convention.

static const SCNMatrix4 defaultPivot = SCNMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);

//------------------------------------------------------------------------------

#pragma mark - ViewController ()

@interface ViewController ()<BEMixedRealityModeDelegate, BEControllerDelegate>

@property(strong) SCNNode *reticleNode;
//@property(strong) SCNNode *portalNode;

@property bool runningInStereo;

@end

//------------------------------------------------------------------------------

#pragma mark - ViewController

@implementation ViewController {
    BEMixedRealityMode *_mixedReality;
    NSArray *_markupNameList;
    BOOL _experienceIsRunning;
//    WindowComponent *_portal;
    OutsideWorldComponent *_outsideWorld;
    ColorOverlayComponent *_colorOverlay;
}

+ (SCNNode *)loadNodeNamed:(NSString *)nodeName fromSceneNamed:(NSString *)sceneName {
    SCNScene *scene = [SCNScene sceneNamed:sceneName];

    if (!scene) {
        NSLog(@"Could not load scene named: %@", sceneName);

        assert(scene);
    }

    SCNNode *node = [scene.rootNode childNodeWithName:nodeName recursively:YES];
    if (!node) {
        NSLog(@"Could not find node (%@) in scene named: %@\nHere's all the nodes I could find in the scene:\n",
              nodeName,
              sceneName);
        [self printSceneNodes:scene.rootNode showHidden:false];
        assert(node);
    }

    node.pivot = defaultPivot;

    return node;
}

+ (void)printSceneNodes:(SCNNode *)rootNode showHidden:(bool)hidden {
    [self printSceneNodes:rootNode withLevel:0 showHidden:hidden];
}

+ (void)printSceneNodes:(SCNNode *)rootNode withLevel:(int)level showHidden:(bool)hidden {
    for (int i = 0; i < level * 4; i++) {
        printf(" ");
    }

    if (rootNode.camera!=nil) {

        printf(" [Camera] ");
    }

    if (hidden && [rootNode isHidden]) {
        printf("%s [Hidden]\n", [[rootNode name] UTF8String]);
    } else {
        printf("%s\n", [[rootNode name] UTF8String]);
    }

    for (SCNNode *child in [rootNode childNodes]) {
        [self printSceneNodes:child withLevel:level + 1 showHidden:hidden];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Markup is optional physical annotations of a scanned scene, that persist between app launches.
    // Here is a list of markup we'll use for our sample.
    // If the user decides, the locations of this markup will be saved on device.

//    _markupNameList = @[@"tree", @"chair", @"gift", @"portal"];
    _markupNameList = @[];

    BECaptureReplayMode replayMode = BECaptureReplayModeDisabled;
    if ([AppSettings booleanValueFromAppSetting:@"replayCapture"
             defaultValueIfSettingIsNotInBundle:NO]) {
        replayMode = BECaptureReplayModeRealTime;
    }

    self.runningInStereo = [AppSettings booleanValueFromAppSetting:@"stereoRendering"
                                defaultValueIfSettingIsNotInBundle:YES];

    _mixedReality = [[BEMixedRealityMode alloc]
            initWithView:(BEView *) self.view
           engineOptions:@{
                   kBECaptureReplayMode:
                   @(replayMode),
                   kBEUsingWideVisionLens:
                   @([AppSettings booleanValueFromAppSetting:@"useWVL"
                          defaultValueIfSettingIsNotInBundle:YES]),
                   kBEStereoRenderingEnabled: @(self.runningInStereo),
                   kBEUsingColorCameraOnly:
                   @([AppSettings booleanValueFromAppSetting:@"colorCameraOnly"
                          defaultValueIfSettingIsNotInBundle:NO]),
                   kBERecordingOptionsEnabled:
                   @([AppSettings booleanValueFromAppSetting:@"enableRecording"
                          defaultValueIfSettingIsNotInBundle:NO]),
                   kBEMapperVolumeResolutionKey:
                   @([AppSettings floatValueFromAppSetting:@"mapperVoxelResolution"
                        defaultValueIfSettingIsNotInBundle:0.02]),
           }
             markupNames:_markupNameList
    ];

    BEController *controller = [BEController sharedController];
    controller.delegate = self;

    _mixedReality.delegate = self;

    [_mixedReality start];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Here we initialize two gesture recognizers as a way to expose features.

    {
        // todo: This gesture recongnizer doesn't seem to work.
        // Allocate and initialize the first tap gesture.

        UITapGestureRecognizer
                *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];

        // Specify that the gesture must be a single tap.

        tapRecognizer.numberOfTapsRequired = 1;

        // Add the tap gesture recognizer to the view.

        [self.view addGestureRecognizer:tapRecognizer];
    }

    {
        // Allocate and initialize the second gesture as a double-tap one.

        UITapGestureRecognizer *twoFingerTapRecognizer =
                [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeRenderMode)];

        twoFingerTapRecognizer.numberOfTouchesRequired = 2;

        [self.view addGestureRecognizer:twoFingerTapRecognizer];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)startExperience {
    // For this experience, let's switch to a mode with AR objects composited with the passthrough camera.

    [_mixedReality setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:0.5];

    _experienceIsRunning = YES;
}

- (void)updateObjectPositionWithMarkupName:(NSString *)markupName {
    // Here, we're using markup to set the location of static objects.
    // However, you could do something much more sophisticated, like have multiple markup points be waypoints for a virtual character.
}

// --------------------------------------------
// MixedReality Delegate Methods

- (void)mixedRealitySensorsStatusChanged:(BESensorsStatus)sensorsStatus {
    if (sensorsStatus.allSensorsReady) {
        be_dbg("sensorStatus: OK");
    } else {
        be_dbg("sensorStatus: %s%s%s%s",
               sensorsStatus.needToConnectDepthSensor ? "[NeedToConnectDepthSensor]" : "",
               sensorsStatus.needToChargeDepthSensor ? "[NeedToChargeDepthSensor]" : "",
               sensorsStatus.needToRunCalibrator ? "[NeedToRunCalibrator]" : "",
               sensorsStatus.needToAuthorizeIOSCamera ? "[NeedToAuthorizeIOSCamera]" : "");
    }
}

- (void)mixedRealitySetUpSceneKitWorlds:(BEMappedAreaStatus)mappedAreaStatus {
    // When this function is called, it is guaranteed that the SceneKit world is set up, and any previously-positioned markup nodes are loaded.
    // As this function is called from a rendering thread, perform only SceneKit updates here.
    // Avoid UIKit manipulation here (use main thread for UIKit).

    if (mappedAreaStatus==BEMappedAreaStatusNotFound) {
        NSLog(@"Your scene does not exist in the expected location on your device!");
        NSLog(@"You probably need to scan and export your local scene!");
        return;
    }

    // It is up to you whether you want to call startMarkupEditing.
    // For this sample, we'll edit markup if any markup is missing from the given name list.

    bool foundAllMarkup = YES;
    for (id markupName in _markupNameList) {
        if (![_mixedReality markupNodeForName:markupName]) {
            foundAllMarkup = NO;
            break;
        }
    }

    // If we have all the markup, let's directly begin the experience.
    // Otherwise, let's activate the markup editing UI.

    if (foundAllMarkup) {
        [self startExperience];
        //_mixedReality.sceneKitCamera.zFar = 100;
    } else {
        [_mixedReality startMarkupEditing];
    }

    // Set any initial objects based on markup.

    for (id markupName in _markupNameList)
        [self updateObjectPositionWithMarkupName:markupName];


    // Add a custom node to indicate where a click will take place in stereo, using the controller.
    self.reticleNode = [SCNNode nodeWithGeometry:[SCNCylinder cylinderWithRadius:0.01 height:0.01]];
    self.reticleNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1];
    self.reticleNode.geometry.firstMaterial.writesToDepthBuffer = NO;
    self.reticleNode.geometry.firstMaterial.readsFromDepthBuffer = NO;
    self.reticleNode.castsShadow = NO;
    // Reticle should be the last thing drawn in the scene, so that it can render on top of everything
    self.reticleNode.renderingOrder = BEEnvironmentScanRenderingOrder + 100;

    self.reticleNode.hidden = ![[BEController sharedController] isConnected] || !self.runningInStereo;

    // rotate the cylinder so that it points the direction of user's gaze, and translate forward by 1m
    self.reticleNode.transform = SCNMatrix4Translate(SCNMatrix4Rotate(SCNMatrix4Identity, M_PI_2, 1, 0, 0), 0, 0, 1);

    // add this as a child of Bridge, not of the scanned world. This will make it follow the user's gaze.
    [_mixedReality.localDeviceNode addChildNode:self.reticleNode];


    // demonstrate using custom render modes
    CustomRenderMode *customRenderMode = [[CustomRenderMode alloc] init];
    [customRenderMode compile];
    [_mixedReality setCustomRenderStyle:customRenderMode];

    // portal
    _colorOverlay = [[ColorOverlayComponent alloc] init];
    [[[SceneManager main] createEntity] addComponent:_colorOverlay];

    _outsideWorld = [[OutsideWorldComponent alloc] init];
    [[[SceneManager main] createEntity] addComponent:_outsideWorld];

//    _portal = [[WindowComponent alloc] init];
//    _portal.mixedReality = _mixedReality;
//    _portal.overlayComponent = _colorOverlay;
//    _portal.stereoRendering = YES;
//    //_portal.interactive = [BEAppSettings booleanValueFromAppSetting:SETTING_PLAY_SCRIPT defaultValueIfSettingIsNotInBundle:NO] == NO;
//    GKEntity *_portalEntity = [[SceneManager main] createEntity];
//    [_portalEntity addComponent:_portal];
//    [[EventManager main] addGlobalEventComponent:_portal];
//
//    self.portalNode = [_portal node];

    // Setup the near/far clipping planes to be large enough for the mountains world.
    //[Camera main].camera.zFar = 10000;

    // uncomment this line to trigger the custom rendering mode.
    [_mixedReality setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:1];
    //[_mixedReality setCustomRenderStyle: ];
    // Ready to start the Scene Manager- this will start all the components in the scene.
    [[SceneManager main] startWithMixedRealityMode:_mixedReality];

}

- (void)mixedRealityMarkupEditingEnded {
    // If markup editing is over, then any experience in the scene may be started.
    [self startExperience];
}

- (void)mixedRealityMarkupDidChange:(NSString *)markupChangedName {
    // In this sample, markup and objects are 1:1, so we simply update the object position accordingly when a markup position changes.
    [self updateObjectPositionWithMarkupName:markupChangedName];
}

- (void)mixedRealityUpdateAtTime:(NSTimeInterval)time {
    // this updates all components
    [[SceneManager main] updateAtTime:time mixedRealityMode:_mixedReality];

    // This method is called before rendering each frame.
    // It is safe to modify SceneKit objects from here.

    {
        // Here, you can control an interaction using the location of the device.

        SCNNode *localDeviceNode = _mixedReality.localDeviceNode;

        // For now, let's just log its position every 5 seconds.

        static NSTimeInterval lastDeviceNodeLoggingTime = time;

        if (time - lastDeviceNodeLoggingTime > 5.0) {
            NSLog(@"localDeviceNode.position: [ %f, %f, %f ]",
                  localDeviceNode.position.x,
                  localDeviceNode.position.y,
                  localDeviceNode.position.z
            );

            lastDeviceNodeLoggingTime = time;
        }
    }
}

// end MixedReality Delegate Methods
// --------------------------------------------

// --------------------------------------------
// BEController Delegate Methods
// see the delegate definition for other optional meth0ds

- (void)controllerDidConnect {
    // show the reticle if we are in stereo mode
    [self.reticleNode setHidden:!self.runningInStereo];
}

- (void)controllerDidPressButton {

    // simulate a screen tap on the center of one eye
    CGPoint tapPoint = CGPointMake(self.view.frame.size.width / 4, self.view.frame.size.height / 2);
    [self userSelection:tapPoint];
}

- (void)controllerDidHoldButton {
    [self changeRenderMode];
}

// end BEController Delegate Methods
// --------------------------------------------

- (void)handleTap:(UITapGestureRecognizer *)sender {
    CGPoint tapPoint = [sender locationInView:self.view];
    [self userSelection:tapPoint];
}

- (void)changeRenderMode {
    // Increment through render styles, with fading transitions.

    BERenderStyle renderStyle = [_mixedReality renderStyle];
    BERenderStyle nextRenderStyle = BERenderStyle((renderStyle + 1) % NumBERenderStyles);

    [_mixedReality setRenderStyle:nextRenderStyle withDuration:0.5];
}

- (void)userSelection:(CGPoint)tapPoint {
    SCNVector3 meshNormal{NAN, NAN, NAN};
    SCNVector3 mesh3DPoint = [_mixedReality mesh3DFrom2DPoint:tapPoint outputNormal:&meshNormal];

    if (mesh3DPoint.x!=NAN && mesh3DPoint.y!=NAN && mesh3DPoint.z!=NAN) {
        NSLog(@"\t mesh3DPoint %f,%f,%f", mesh3DPoint.x, mesh3DPoint.y, mesh3DPoint.z);

        GLKVector3 normal = GLKVector3Make(-meshNormal.x, -meshNormal.y, -meshNormal.z);

        WindowComponent *_portal = [[WindowComponent alloc] init];
        _portal.mixedReality = _mixedReality;
        _portal.overlayComponent = _colorOverlay;
        _portal.stereoRendering = YES;
        [_portal start];

        GKEntity *_portalEntity = [[SceneManager main] createEntity];
        [_portalEntity addComponent:_portal];

        [[EventManager main] addGlobalEventComponent:_portal];

        [_portal openPortalOnWallPosition:mesh3DPoint wallNormal:SCNVector3ToGLKVector3(meshNormal) toVRWorld:_outsideWorld];
    }
}


@end
