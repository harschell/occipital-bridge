/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import "ViewController.h"
#import "AppDelegate.h"

#import <BridgeEngine/BridgeEngine.h>

// Bridge Open Source
#import <OpenBE/Core/SceneManager.h>
#import <OpenBE/Core/AudioEngine.h>

#import <OpenBE/Components/AnimationComponent.h>
#import <OpenBE/Components/BeamComponent.h>
#import <OpenBE/Components/BlockDemoReticleComponent.h>
#import <OpenBE/Components/ButtonContainerComponent.h>
#import <OpenBE/Components/ButtonComponent.h>
#import <OpenBE/Components/BridgeControllerComponent.h>
#import <OpenBE/Components/FetchEventComponent.h>
#import <OpenBE/Components/FixedSizeReticleComponent.h>
#import <OpenBE/Components/GazeComponent.h>
#import <OpenBE/Components/MoveRobotEventComponent.h>
#import <OpenBE/Components/RobotActionComponent.h>
#import <OpenBE/Components/RobotBehaviourComponent.h>
#import <OpenBE/Components/RobotBodyEmojiComponent.h>
#import <OpenBE/Components/RobotMeshControllerComponent.h>
#import <OpenBE/Components/RobotSeesMeComponent.h>
#import <OpenBE/Components/RobotVemojiComponent.h>
#import <OpenBE/Components/ScanEventComponent.h>
#import <OpenBE/Components/ScanComponent.h>
#import <OpenBE/Components/SpawnComponent.h>
#import <OpenBE/Components/SpawnPortalComponent.h>
#import <OpenBE/Components/VRWorldComponent.h>
#import <OpenBE/Components/ProjectedGeometryComponent.h>

#import <OpenBE/Shaders/ScanEnvironmentShader.h>

// Behaviors
#import <OpenBE/Components/BehaviourComponents/BeamUIBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/LookAtBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/LookAtNodeBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/LookAtCameraBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/ExpressionBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/MoveToBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/PathFindMoveToBehaviourComponent.h>
#import <OpenBE/Components/BehaviourComponents/ScanBehaviourComponent.h>


#import <OpenBE/Utils/ComponentUtils.h>
#import <OpenBE/Utils/SceneKitExtensions.h>

//------------------------------------------------------------------------------
#pragma mark - ViewController ()


@interface ViewController () <BEMixedRealityModeDelegate, BEControllerDelegate>

@property (nonatomic, strong) RobotActionComponent* robot;
@property (nonatomic, strong) GKEntity * robotEntity;
@property (nonatomic, strong) ButtonContainerComponent * renderMenu;
@property (nonatomic, strong) FixedSizeReticleComponent *fixedSizeReticle;
@property (nonatomic, strong) BridgeControllerComponent* bControllerComponent;
@property (nonatomic, strong) ProjectedGeometryComponent *robotProjectionComponent;

@end
//------------------------------------------------------------------------------

#pragma mark - ViewController

@implementation ViewController
{
    BEMixedRealityMode* _mixedReality;
    NSArray*            _markupNameList;
    BOOL                _sceneIsRunning;
    BOOL                _experienceIsRunning; // Hold input events until we're done markup editing and experience is going. 
    VRWorldComponent *_vrWorld;
    PortalComponent *_portal;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Markup is optional physical annotations of a scanned scene, that persist between app launches.
    // Here is a list of markup we'll use for our sample.
    // If the user decides, the locations of this markup will be saved on device.
    NSMutableArray<NSString*> *markupNames = @[].mutableCopy;
    if (![BEAppSettings booleanValueFromAppSetting:SETTING_STEREO_SCANNING defaultValueIfSettingIsNotInBundle:NO]) {
        [markupNames addObject:@"Bridget"];
        if ([BEAppSettings booleanValueFromAppSetting:SETTING_SHOW_RENDER_TYPES defaultValueIfSettingIsNotInBundle:NO]) {
            [markupNames addObject:@"Rendering Menu"];
        }
    } else {
        _markupNameList = @[]; // Go with auto-placement of bridget for better default Stereo Set-up experience. 
    }
    _markupNameList = markupNames.copy;
    

    BECaptureReplayMode replayMode = BECaptureReplayModeDisabled;
    if ([BEAppSettings booleanValueFromAppSetting:SETTING_REPLAY_CAPTURE
             defaultValueIfSettingIsNotInBundle:NO])
    {
        replayMode = BECaptureReplayModeRealTime;
    }
    
    _mixedReality = [[BEMixedRealityMode alloc]
        initWithView:(BEView*)self.view
        engineOptions:@{
            kBETrackerFallbackOnIMUEnabled:@(YES),
            kBECaptureReplayMode:
                @(replayMode),
            kBEUsingWideVisionLens:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_USE_WVL
                       defaultValueIfSettingIsNotInBundle:YES]),
            kBEStereoRenderingEnabled:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_STEREO_RENDERING
                       defaultValueIfSettingIsNotInBundle:YES]),
            kBEUsingColorCameraOnly:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_COLOR_CAMERA_ONLY
                       defaultValueIfSettingIsNotInBundle:NO]),
            kBERecordingOptionsEnabled:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_ENABLE_RECORDING
                       defaultValueIfSettingIsNotInBundle:NO]),
            kBEEnableStereoScanningBeta:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_STEREO_SCANNING
                       defaultValueIfSettingIsNotInBundle:NO]),
        }
        markupNames:_markupNameList
    ];

    _mixedReality.delegate = self;

    // Link the event manager to this mixed reality instance.
    [EventManager main].mixedRealityMode = _mixedReality;

    // Establish use of reticle or not.
    if( [BEAppSettings booleanValueFromAppSetting:SETTING_STEREO_RENDERING defaultValueIfSettingIsNotInBundle:YES] ) {
        [EventManager main].useReticleAsTouchLocation = YES;
    } else {
        [EventManager main].useReticleAsTouchLocation = NO;
    }
    
    [_mixedReality start];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    {
        // Allocate and initialize the gesture as a double-tap one.
        UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
        twoFingerTapRecognizer.numberOfTouchesRequired = 2;
        [self.view addGestureRecognizer:twoFingerTapRecognizer];
    }
}

- (void)setupRenderingMenu
{
    //---------------------------------------------------------------------
    // let's make another menu for Rendering options
    _renderMenu = [[ButtonContainerComponent alloc] init];
    
    ButtonComponent * buttonRenderStyle0 = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_wire.png"] andBlock:^{
        [_mixedReality setRenderStyle:BERenderStyle::BERenderStyleSceneKitAndWireframe withDuration:1.0];
    }];
    [buttonRenderStyle0 setDepthTesting:YES];
    
    ButtonComponent * buttonRenderStyle1 = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_cam.png"] andBlock:^{
        [_mixedReality setRenderStyle:BERenderStyle::BERenderStyleSceneKitAndColorCamera withDuration:1.0];
    }];
    [buttonRenderStyle1 setDepthTesting:YES];
    
    ButtonComponent * buttonRenderStyle2 = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_wire_cam.png"] andBlock:^{
        [_mixedReality setRenderStyle:BERenderStyle::BERenderStyleSceneKitAndColorCameraAndWireframe withDuration:1.0];
    }];
    [buttonRenderStyle2 setDepthTesting:YES];
    
    [[[SceneManager main] createEntity] addComponent:buttonRenderStyle0];
    [[[SceneManager main] createEntity] addComponent:buttonRenderStyle1];
    [[[SceneManager main] createEntity] addComponent:buttonRenderStyle2];
    
    [[[SceneManager main] createEntity] addComponent:_renderMenu];
    
    _renderMenu.buttonComponents = [[NSMutableArray alloc] initWithArray:@[buttonRenderStyle0, buttonRenderStyle1, buttonRenderStyle2]];
    [_renderMenu setEnabled:YES];
}

-(void) setUpEntityComponentSystem
{
    BOOL stereo = [BEAppSettings booleanValueFromAppSetting:SETTING_STEREO_RENDERING defaultValueIfSettingIsNotInBundle:YES];
    
    // main Audio engine and Scene Manager
    [[SceneManager main] initWithMixedRealityMode:_mixedReality stereo:stereo];
    [AudioEngine main];

    // Selection UI
    GazeComponent *gazeComponent = [[GazeComponent alloc] init];
    GKEntity * gazeEntity = [[SceneManager main] createEntity];
    [gazeEntity addComponent:gazeComponent];
    
    // Try some other reticles!
    self.fixedSizeReticle = [[FixedSizeReticleComponent alloc] init];
    //Component *fixedSizeReticle = [[BlockDemoReticleComponent alloc] init];
    [gazeEntity addComponent:_fixedSizeReticle];
    
    // BController Entity
    self.bControllerComponent = [[BridgeControllerComponent alloc] init];
    GKEntity *controllerEntity = [[SceneManager main] createEntity];
    [controllerEntity addComponent:self.bControllerComponent];
    [self.bControllerComponent setEnabled:YES];

    [self updateReticleInputMode];
    
    // The main Robot object
    self.robotEntity = [[SceneManager main] createEntity];
    
    _robot = [[RobotActionComponent alloc] init];
    [self.robotEntity addComponent:_robot];
    
    // Appearance Components
    RobotMeshControllerComponent * robotMeshControllerComponent = [[RobotMeshControllerComponent alloc] initWithUnboxingExperience:YES];
    [self.robotEntity addComponent:robotMeshControllerComponent];
    
    [self.robotEntity addComponent:[[AnimationComponent alloc] init]];
    [self.robotEntity addComponent:[[BeamComponent alloc] init]];
    [self.robotEntity addComponent:[[RobotSeesMeComponent alloc] init]];
    [self.robotEntity addComponent:[[RobotBodyEmojiComponent alloc] init]];
    [self.robotEntity addComponent:[[RobotVemojiComponent alloc] init]];
    [self.robotEntity addComponent:(RobotBodyEmojiComponent*)[_robotEntity componentForClass:RobotBodyEmojiComponent.class]];

    ScanComponent * scanComponent = [[ScanComponent alloc] init];
    [self.robotEntity addComponent:scanComponent];
    
    // Markup Projection Object
    SCNNode *robotBoxNode = [SCNNode firstNodeFromSceneNamed:@"Robot_Box.dae"];
    robotBoxNode.eulerAngles = {-M_PI, 0, 0};  // flip it to upright
    self.robotProjectionComponent = [[ProjectedGeometryComponent alloc] initWithChildNode:robotBoxNode];
    self.robotProjectionComponent.node.scale = {0.25, 0.25, 0.25};
    
    // Behaviour Components
    RobotBehaviourComponent * behaviourComponent = [[RobotBehaviourComponent alloc] init];
    [self.robotEntity addComponent:behaviourComponent];
    PathFindMoveToBehaviourComponent * pathFindingComponent = [[PathFindMoveToBehaviourComponent alloc] initWithIdleWeight:0.f andAllowCameraMovementTriggerAttention:NO];
    [self.robotEntity addComponent:pathFindingComponent];
    [self.robotEntity addComponent:[[ExpressionBehaviourComponent alloc] initWithIdleWeight:0.f andAllowCameraMovementTriggerAttention:YES]];
    [self.robotEntity addComponent:[[LookAtBehaviourComponent alloc] initWithIdleWeight:50.f andAllowCameraMovementTriggerAttention:YES]];
    [self.robotEntity addComponent:[[LookAtCameraBehaviourComponent alloc] initWithIdleWeight:20.f andAllowCameraMovementTriggerAttention:NO]];
    [self.robotEntity addComponent:[[LookAtNodeBehaviourComponent alloc] initWithIdleWeight:0.f andAllowCameraMovementTriggerAttention:YES]];
    [self.robotEntity addComponent:[[MoveToBehaviourComponent alloc] initWithIdleWeight:0.f andAllowCameraMovementTriggerAttention:YES]];
    [self.robotEntity addComponent:[[ScanBehaviourComponent alloc] initWithIdleWeight:0.f andAllowCameraMovementTriggerAttention:NO]];
    
    
    //---------------------------------------------------------------------
    // Event components that need to be added to the main event manager.
    MoveRobotEventComponent * moveComponent = [[MoveRobotEventComponent alloc] init];
    FetchEventComponent *fetchComponent = [[FetchEventComponent alloc] init];
    ScanEventComponent * scanEventComponent = [[ScanEventComponent alloc] init];
    SpawnComponent * spawnObjectComponent = [[SpawnComponent alloc] init];

    // add components to the main Event Manager
    [[EventManager main] addGlobalEventComponent:moveComponent];
    [[EventManager main] addGlobalEventComponent:fetchComponent];
    [[EventManager main] addGlobalEventComponent:scanEventComponent];
    [[EventManager main] addGlobalEventComponent:spawnObjectComponent];
    
    // portal
    ColorOverlayComponent *colorOverlay = [[ColorOverlayComponent alloc] init];
    [[[SceneManager main] createEntity] addComponent:colorOverlay];
    
    _vrWorld = [[VRWorldComponent alloc] init];
    [[[SceneManager main] createEntity] addComponent:_vrWorld];
    _portal = [[PortalComponent alloc] init];
    _portal.mixedReality = _mixedReality;
    _portal.overlayComponent = colorOverlay;
    _vrWorld.portalComponent = _portal;
    _portal.robotEntity = self.robotEntity;
    _portal.bridgeControllerComponent = self.bControllerComponent;
    _portal.stereoRendering = stereo;
    //_portal.interactive = [BEAppSettings booleanValueFromAppSetting:SETTING_PLAY_SCRIPT defaultValueIfSettingIsNotInBundle:NO] == NO;
    [[[SceneManager main] createEntity] addComponent:_portal];
    
    // spawn portal
    SpawnPortalComponent * spawnPortalComponent = [[SpawnPortalComponent alloc] init];
    spawnPortalComponent.vrWorldComponent = _vrWorld;
    spawnPortalComponent.portalComponent = _portal;
    spawnPortalComponent.robotActionSequencer = _robot;
    [[EventManager main] addGlobalEventComponent:spawnPortalComponent];

    // The event components are hooked to the robot Behaviour to trigger animations and movements.
    moveComponent.robotBehaviourComponent = behaviourComponent;
    fetchComponent.robotBehaviourComponent = behaviourComponent;
    scanEventComponent.robotBehaviourComponent = behaviourComponent;
    spawnObjectComponent.robotBehaviourComponent = behaviourComponent;

    // This lets physics drive audio
    PhysicsContactAudioComponent *physicsContactAudioComponent = [[PhysicsContactAudioComponent alloc] init];
    physicsContactAudioComponent.physicsWorld = [Scene main].scene.physicsWorld;
    [[[SceneManager main] createEntity] addComponent:physicsContactAudioComponent];
    
    // hook up audio for physics to the fetch and furniture drop
    spawnObjectComponent.physicsContactAudio = physicsContactAudioComponent;
    fetchComponent.physicsContactAudio = physicsContactAudioComponent;

    // A custom Environment shader example, driven by the ScanComponent
    ScanEnvironmentShader * customEnvironmentShader = [[ScanEnvironmentShader alloc] init];
    customEnvironmentShader.mixedRealityMode = _mixedReality;
    [customEnvironmentShader compile];
    scanComponent.scanEnvironmentShader = customEnvironmentShader;
    
    // diable behaviors to start
    [fetchComponent setEnabled:NO];
    [moveComponent setEnabled:NO];
    [scanEventComponent setEnabled:NO];
    [spawnObjectComponent setEnabled:NO];
    
    // Here is where we hook up the menu buttons to components
    ButtonContainerComponent * bridgetMenu = [[ButtonContainerComponent alloc] init];
    GKEntity * uiEntity = [[SceneManager main] createEntity];
    [uiEntity addComponent:bridgetMenu];

    // hook the menu up to the robot, with a little projector beam
    BeamUIBehaviourComponent * beamUIComponent = [[BeamUIBehaviourComponent alloc] initWithIdleWeight:0.f andAllowCameraMovementTriggerAttention:NO];
    beamUIComponent.uiComponent = bridgetMenu;
    [self.robotEntity addComponent:beamUIComponent];
    
    ButtonComponent * buttonMoveComponent = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_move.png"] andBlock:^{
        [behaviourComponent stopAllBehaviours];
        [bridgetMenu setEnabled:NO];
        [moveComponent setEnabled:YES];
        [fetchComponent setEnabled:NO];
        [scanEventComponent setEnabled:NO];
        [behaviourComponent addPointOfInterest:[Camera main].position];
        [spawnObjectComponent setEnabled:NO];
        [spawnPortalComponent setEnabled:NO];
    }];
    
    ButtonComponent * buttonScanComponent = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_scan.png"] andBlock:^{
        [behaviourComponent stopAllBehaviours];
        [bridgetMenu setEnabled:NO];
        [fetchComponent setEnabled:NO];
        [scanEventComponent setEnabled:YES];
        [moveComponent setEnabled:NO];
        [spawnObjectComponent setEnabled:NO];
        [spawnPortalComponent setEnabled:NO];
    }];
    
    ButtonComponent * buttonSpawnObjectComponent = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_chair.png"] andBlock:^{
        [behaviourComponent stopAllBehaviours];
        [bridgetMenu setEnabled:NO];
        [fetchComponent setEnabled:NO];
        [scanEventComponent setEnabled:NO];
        [moveComponent setEnabled:NO];
        [spawnObjectComponent setEnabled:YES];
        [spawnPortalComponent setEnabled:NO];
    }];
    
    ButtonComponent * buttonFetchComponent = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_bone.png"] andBlock:^{
        [behaviourComponent stopAllBehaviours];
        [bridgetMenu setEnabled:NO];
        [moveComponent setEnabled:NO];
        [fetchComponent setEnabled:YES];
        [scanEventComponent setEnabled:NO];
        [spawnObjectComponent setEnabled:NO];
        [spawnPortalComponent setEnabled:NO];
    }];
    
    ButtonComponent * buttonPortalComponent = [[ButtonComponent alloc] initWithImage:[SceneKit pathForImageResourceNamed:@"button_wallPortal.png"] andBlock:^{
        [behaviourComponent stopAllBehaviours];
        [bridgetMenu setEnabled:NO];
        [fetchComponent setEnabled:NO];
        [spawnPortalComponent setEnabled:YES];
        [spawnObjectComponent setEnabled:NO];
        [scanEventComponent setEnabled:NO];
        [moveComponent setEnabled:NO];
    }];

    [[[SceneManager main] createEntity] addComponent:buttonMoveComponent];
    [[[SceneManager main] createEntity] addComponent:buttonScanComponent];
    [[[SceneManager main] createEntity] addComponent:buttonSpawnObjectComponent];
    [[[SceneManager main] createEntity] addComponent:buttonFetchComponent];
    [[[SceneManager main] createEntity] addComponent:buttonPortalComponent];

    // Determines the order in which the buttons appear on the hologram menu projected by the robot
    bridgetMenu.buttonComponents = @[
        buttonMoveComponent,
        buttonScanComponent,
        buttonSpawnObjectComponent,
        buttonFetchComponent,
        buttonPortalComponent,
        ].mutableCopy;
    
    if ([BEAppSettings booleanValueFromAppSetting:SETTING_SHOW_RENDER_TYPES defaultValueIfSettingIsNotInBundle:NO]) {
        [self setupRenderingMenu];
    }
    
    // Ready to start the Scene Manager- this will start all the components in the scene.
    [[SceneManager main] startWithMixedRealityMode:_mixedReality];
    
    // now we can manually tweak the components that have been created, after they have been started
    //---------------------------------------------------------------------
    [bridgetMenu setEnabled:NO];
    [spawnPortalComponent setEnabled:NO];
    
    float scale = .13f;
    bridgetMenu.node.scale = SCNVector3Make(scale, scale, scale);
    bridgetMenu.node.position = SCNVector3Make(0, -0.8, .7);
    
    scale = 0.4;
    [_renderMenu.node setScale:SCNVector3Make(scale, scale, scale)];
    
    
    // Find a roughly good starting position. If available, this will load floor and cover maps
    // and find an open and uncovered area. Otherwise we'll use the normal obstacle occupancy map
    // which may e.g. place the robot under a table.
    GLKVector3 openPositon;
    if (pathFindingComponent.noCoverPathFinding != nil) {
        openPositon = [pathFindingComponent findLargestOpenAreaPoint:pathFindingComponent.noCoverPathFinding];
    } else {
        openPositon = [pathFindingComponent findLargestOpenAreaPoint:pathFindingComponent.pathFinding];
    }

    pathFindingComponent.reachableReferencePoint = openPositon;
    [robotMeshControllerComponent setPosition:openPositon];
    
    //---------------------------------------------------------------------
    // now go to the markup if we need to
    bool foundAllMarkup = YES;
    for (id markupName in _markupNameList)
    {
        if (![_mixedReality markupNodeForName:markupName])
        {
            foundAllMarkup = NO;
        } else
        {
            [self mixedRealityMarkupDidChange:markupName];
        }
    }
 
    // setup controller
    [BEController sharedController].delegate = self;
    [self updateReticleInputMode];

    // if we found all the markups, skip markup editing.
    if (foundAllMarkup)
    {
        [self startExperience];
    }
    else
    {
        [_mixedReality startMarkupEditing];
    }
}

- (void) mixedRealitySensorsStatusChanged:(BESensorsStatus)sensorsStatus
{
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

- (void)mixedRealitySetUpSceneKitWorlds:(BEMappedAreaStatus)mappedAreaStatus
{
    _experienceIsRunning = NO;
    _sceneIsRunning = NO;

    [self setUpEntityComponentSystem];

    _sceneIsRunning = YES;
}

- (void)startExperience
{
    // For this experience, let's switch to a mode with AR objects composited with the passthrough camera.
    [_mixedReality setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:0.5];

    RobotBehaviourComponent * behaviourComponent = (RobotBehaviourComponent *)[ComponentUtils getComponentFromEntity:self.robotEntity ofClass:[RobotBehaviourComponent class]];
    [behaviourComponent runIdleBehaviours:YES];
    [behaviourComponent cameraMovementTriggerAttention:YES];
    
    _experienceIsRunning = YES;
    
    [self updateReticleInputMode];
}

- (void)mixedRealityMarkupEditingEnded
{
    self.robotProjectionComponent.node.hidden = YES;
    
    // If markup editing is over, then any experience in the scene may be started.
    [self startExperience];
}

- (void)mixedRealityMarkupDidChange:(NSString*)markupChangedName
{
    SCNNode * markupNode = [_mixedReality markupNodeForName:markupChangedName];
    
    if (!markupNode)
        return;
    
    if ([markupChangedName isEqualToString: @"Bridget"])
    {
        // Double check and align to nearest open point.
        PathFindMoveToBehaviourComponent * pathFindingComponent = (PathFindMoveToBehaviourComponent*)[self.robotEntity componentForClass:PathFindMoveToBehaviourComponent.class];
        GLKVector3 markupPoint = SCNVector3ToGLKVector3(markupNode.position);
        GLKVector3 markupRotationEuler = SCNVector3ToGLKVector3(markupNode.eulerAngles);
        if( [pathFindingComponent occupied:markupPoint] == NO ) {
            pathFindingComponent.reachableReferencePoint = markupPoint;

            RobotMeshControllerComponent *meshController = (RobotMeshControllerComponent *)[self.robotEntity componentForClass:[RobotMeshControllerComponent class]];
            [meshController setPosition:markupPoint];
            [meshController setRotationEuler:markupRotationEuler];
        } else {
            RobotBehaviourComponent *robotBehaviour = (RobotBehaviourComponent *)[self.robotEntity componentForClass:[RobotBehaviourComponent class]];
            [robotBehaviour beSad];
        }
    }
    else if ([markupChangedName isEqualToString: @"Rendering Menu"])
    {
        SCNVector3 p = markupNode.position;
        
        // Shift the vertical position up to make sure we can see the entire panel
        // if the user placed it on the ground.
        p.y -= _renderMenu.node.scale.y*0.6;
        
        // Also make it a bit closer to us, in case the user put it on a wall.
        p.z -= 0.51f;
        
        [_renderMenu.node setPosition:p];
        [_renderMenu.node setRotation:markupNode.rotation];
    }
}

- (BOOL)mixedRealityBridgeShouldProjectMarkupNode:(NSString *)markupName position:(SCNVector3)position eulerAngles:(SCNVector3)eulerAngles
{
    if ([markupName isEqualToString: @"Bridget"])
    {
        self.robotProjectionComponent.node.position = position;
        self.robotProjectionComponent.node.eulerAngles = eulerAngles;
        self.robotProjectionComponent.node.hidden = NO;
        
        return NO;
    } else {
        self.robotProjectionComponent.node.hidden = YES;
    }
    
    return YES;
}

- (void)mixedRealityUpdateAtTime:(NSTimeInterval)time
{
    // Update the controller's camera world transform, so we're tracking with it.
    [BEController sharedController].cameraTransform = SCNMatrix4ToGLKMatrix4(_mixedReality.localDeviceNode.worldTransform);

    if( !_sceneIsRunning ) {
        return;
    }
    
    // this updates all components
    [[SceneManager main] updateAtTime:time mixedRealityMode:_mixedReality];
}


// BEController Delegate Methods

- (void)controllerDidConnect {
    [self updateReticleInputMode];
}

- (void)controllerDidDisconnect {
    [self updateReticleInputMode];
}

- (void)controllerButtons:(BEControllerButtons)buttons down:(BEControllerButtons)buttonsDown up:(BEControllerButtons)buttonsUp {
    if( _experienceIsRunning ) {
        if( (buttonsDown & BEControllerButtonPrimary) != 0) {
            [[EventManager main] controllerButtonDown];
        }
        
        if( (buttonsUp & BEControllerButtonPrimary) != 0) {
            [[EventManager main] controllerButtonUp];
        }
    }
}

- (void)controllerMotionTransform:(GLKMatrix4)transform {
}

- (void)controllerTouchPosition:(GLKVector2)position status:(BEControllerTouchStatus)status{
}

// Touch handling helpers
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( _experienceIsRunning ) {
        [[EventManager main] touchesBegan:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( _experienceIsRunning ) {
        [[EventManager main]  touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( _experienceIsRunning ) {
        [[EventManager main] touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( _experienceIsRunning ) {
        [[EventManager main] touchesMoved:touches withEvent:event];
    }
}

- (void)handleTwoFingerTap:(UITapGestureRecognizer *)sender
{
    // Increment through render styles, with fading transitions.
    
    BERenderStyle renderStyle = [_mixedReality renderStyle];
    BERenderStyle nextRenderStyle = BERenderStyle((renderStyle + 1) % NumBERenderStyles);
    
    [_mixedReality setRenderStyle:nextRenderStyle withDuration:0.5];
}

#pragma mark - Support Methods

/// Hook reticle visibility to controller connected status.
- (void) updateReticleInputMode {
    BOOL stereo = [BEAppSettings booleanValueFromAppSetting:SETTING_STEREO_RENDERING defaultValueIfSettingIsNotInBundle:YES];
    BOOL connected = [BEController sharedController].isConnected;
    BOOL enableReticleInput = (connected || stereo);
    
    [EventManager main].useReticleAsTouchLocation = enableReticleInput;
    [_fixedSizeReticle setEnabled:enableReticleInput && _experienceIsRunning];

    // Only show Bridge Controller if it's specifically connected. 
    [_bControllerComponent setEnabled:BEController.sharedController.isBridgeControllerConnected];
}

@end
