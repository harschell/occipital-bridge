/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import "ViewController.h"
#import "AppDelegate.h"
#import "EAGLView.h"

#import <BridgeEngine/BridgeEngine.h>
#import <cassert>

//------------------------------------------------------------------------------

#define ASSETS_DIR "Assets.scnassets" // The SceneKit assets root folder.

// Our custom BE Scene path can be saved and loaded from any name.
// However must be "BridgeEngineScene" to find a capture.occ or other OCC for replay.
#define BRIDGEENGINESCENE_PATH @"BridgeEngineScene"

// Since -Y is up in Bridge Engine convention, the pivot rotates from the typical convention.
static const SCNMatrix4 defaultPivot = SCNMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);

// Display related members.
struct DisplayData
{
   // OpenGL context.
    EAGLContext *context = nil;
    
    // OpenGL viewport.
    GLfloat viewport[4];
    
    BEOpenGLRenderStyle currentGLRenderStyle = BEOpenGLRenderStyle::BEOpenGLRenderStyleColorCamera;
    
    CADisplayLink* displayLink = nil;
    
    GLKMatrix4 projectionMatrix = GLKMatrix4Identity;
};

enum class AppState
{
    Initial,
    EnteredScanningMode,
    Scanning,
    Tracking,
};

//------------------------------------------------------------------------------

#pragma mark - ViewController ()

@interface ViewController () < BEMixedRealityModeDelegate, BEControllerDelegate>
@property (nonatomic) AppState appState;
@end

//------------------------------------------------------------------------------

#pragma mark - ViewController

@implementation ViewController
{
    BEMixedRealityMode* _mixedReality;
    BOOL                _experienceIsRunning;
    DisplayData         _display;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupGL];
    
    BECaptureReplayMode replayMode;
    if([BEAppSettings booleanValueFromAppSetting:@"replayCapture"
        defaultValueIfSettingIsNotInBundle:NO])
    {
        replayMode = BECaptureReplayModeRealTime; //  Deterministic;
    } else {
        replayMode = BECaptureReplayModeDisabled;
    }
    
    _mixedReality = [[BEMixedRealityMode alloc]
        initWithView:nil // no view, headless mode.
        engineOptions:@{
            kBEUsingWideVisionLens:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_USE_WVL
                       defaultValueIfSettingIsNotInBundle:YES]),
            kBEUsingColorCameraOnly:
                @([BEAppSettings booleanValueFromAppSetting:SETTING_COLOR_CAMERA_ONLY
                       defaultValueIfSettingIsNotInBundle:NO]),
            kBECaptureReplayMode:
                @(replayMode),
        }
        markupNames:nil
        eaglSharegroup:[_display.context sharegroup]
    ];
    
    BEController *controller = [BEController sharedController];
    controller.delegate = self;

    self.appState = AppState::Initial;
    
    _mixedReality.delegate = self;
    [_mixedReality start];
}

- (void)setAppState:(AppState)appState
{
    _appState = appState;
    
    switch (_appState)
    {
        case AppState::Initial:
        {
            _resetScanningButton.hidden = YES;
            _startStopScanningButton.hidden = YES;
            _enterScanningModeButton.hidden = NO;
            _enterTrackingModeButton.hidden = NO;
            break;
        }
            
        case AppState::EnteredScanningMode:
        {
            _resetScanningButton.hidden = YES;
            _startStopScanningButton.hidden = NO;
            [_startStopScanningButton setTitle:@"Start Scanning" forState:UIControlStateNormal];
            _enterScanningModeButton.hidden = YES;
            _enterTrackingModeButton.hidden = NO;
            break;
        }
            
        case AppState::Scanning:
        {
            _resetScanningButton.hidden = NO;
            _startStopScanningButton.hidden = NO;
            [_startStopScanningButton setTitle:@"Stop Scanning" forState:UIControlStateNormal];
            _enterScanningModeButton.hidden = YES;
            _enterTrackingModeButton.hidden = YES;
            break;
        }
            
        case AppState::Tracking:
        {
            _resetScanningButton.hidden = YES;
            _startStopScanningButton.hidden = YES;
            _enterScanningModeButton.hidden = NO;
            _enterTrackingModeButton.hidden = YES;
            break;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // The framebuffer will only be really ready with its final size after the view appears.
    [(EAGLView *)self.view setFramebuffer];
    
    [self setupGLViewport];
    
    [self startDisplayLink];
    
    // Here we initialize two gesture recognizers as a way to expose features.
    
    {
        // Allocate and initialize the first tap gesture.
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        
        // Specify that the gesture must be a single tap.
        
        tapRecognizer.numberOfTapsRequired = 1;
        
        // Add the tap gesture recognizer to the view.
        
        [self.view addGestureRecognizer:tapRecognizer];
    }
    
    {
        // Allocate and initialize the second gesture as a double-tap one.
        
        UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeRenderMode)];
        
        twoFingerTapRecognizer.numberOfTouchesRequired = 2;
        
        [self.view addGestureRecognizer:twoFingerTapRecognizer];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)startDisplayLink
{
    _display.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDraw)];
    _display.displayLink.frameInterval = 2; // 30 FPS.
    [_display.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)setupGL
{
    // Create an EAGLContext for our EAGLView.
    _display.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_display.context) { NSLog(@"Failed to create ES context"); }
    
    [EAGLContext setCurrentContext:_display.context];
    [(EAGLView*)self.view setContext:_display.context];
    [(EAGLView*)self.view setFramebuffer];
}

- (void)setupGLViewport
{
    const float vgaAspectRatio = 640.0f/480.0f;
    
    // Helper function to handle float precision issues.
    auto nearlyEqual = [] (float a, float b) { return std::abs(a-b) < std::numeric_limits<float>::epsilon(); };
    
    CGSize frameBufferSize = [(EAGLView*)self.view getFramebufferSize];
    
    float imageAspectRatio = 1.0f;
    
    float framebufferAspectRatio = frameBufferSize.width/frameBufferSize.height;
    
    // The iPad's diplay conveniently has a 4:3 aspect ratio just like our video feed.
    // Some iOS devices need to render to only a portion of the screen so that we don't distort
    // our RGB image. Alternatively, you could enlarge the viewport (losing visual information),
    // but fill the whole screen.
    if (!nearlyEqual(framebufferAspectRatio, vgaAspectRatio))
        imageAspectRatio = 480.f/640.0f;
    
    _display.viewport[0] = 0;
    _display.viewport[1] = 0;
    _display.viewport[2] = frameBufferSize.width*imageAspectRatio;
    _display.viewport[3] = frameBufferSize.height;
    
    const float verticalFovDegrees = 90;
    const float aspectRatio = framebufferAspectRatio;
    const float zNear = 0.1; // meters
    const float zFar = 20.0;
    _display.projectionMatrix = GLKMatrix4MakePerspective(verticalFovDegrees*M_PI/180.,
                                                          aspectRatio,
                                                          zNear, zFar);
    // We need to flip Y and Z because the coordinate system assumed by GLK is X right, Y up, Z backwards
    // while BridgeEngine coordinate system is X right, Y down, Z forward.
    GLKMatrix4 flipYZ = GLKMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);
    _display.projectionMatrix = GLKMatrix4Multiply(_display.projectionMatrix, flipYZ);
}

- (void)startExperience
{
    // For this experience, let's switch to a mode with AR objects composited with the passthrough camera.
    
    [_mixedReality setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:0.5];
    _experienceIsRunning = YES;
}

// --------------------------------------------
// Game loop

GLKMatrix4 Matrix4fMakePerspective(float nearZ, float farZ)
{
    struct {
        int width = 640;
        int height = 480;
        float fx = 500;
        float fy = 500;
        float cx = 320;
        float cy = 240;
    } intr;
    
    GLKMatrix4 Ortho = GLKMatrix4Make (2.0/intr.width, 0, 0, -1,
                                       0, 2.0/intr.height, 0, -1,
                                       0, 0, -2/(farZ-nearZ), -(farZ+nearZ)/(farZ-nearZ),
                                       0, 0, 0, 1);
    
    Ortho = GLKMatrix4Transpose(Ortho);
    
    // This is important!!!!!
    // The corner of openGL space is bottom left
    GLKMatrix4 m = GLKMatrix4Make (intr.fx,    0.0f,   -intr.cx,  0.0f,
                                   0.0f, intr.fy,    intr.cy-intr.height,  0.0f,
                                   0.0f, 0.0f,   (farZ + nearZ), (nearZ * farZ),
                                   0.0f, 0.0f,   -1.0f,  0.0f);
    
    m = GLKMatrix4Transpose(m);
    
    GLKMatrix4 flipYZ = GLKMatrix4MakeRotation(M_PI, 1.0, 0.0, 0.0);
        
    return GLKMatrix4Multiply(GLKMatrix4Multiply(Ortho, m), flipYZ);
}

- (void)displayLinkDraw
{
    const NSTimeInterval displayLinkStartTime = CACurrentMediaTime();
    
    EAGLView* glView = (EAGLView*)self.view;
    
    [glView setFramebuffer];
    
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // worldFromColorCamera
    BEMixedRealityPrediction* prediction = [_mixedReality predictColorCameraPoseForDisplayLinkStart:displayLinkStartTime];
    
    if (_mixedReality.lastTrackerPoseAccuracy != BETrackerPoseAccuracy::BETrackerPoseAccuracyHigh
        && _appState != AppState::Initial) // allow the color passthrough initially.
    {
        [self dumpTrackerState];
    }
    
    if (_mixedReality.lastTrackerPoseAccuracy != BETrackerPoseAccuracy::BETrackerPoseAccuracyHigh)
    {
        [_mixedReality renderSceneMeshFromColorCameraViewpointWithStyle:BEOpenGLRenderStyleColorCamera
                                                   associatedColorFrame:prediction.associatedColorFrame];
    }
    else if (_appState == AppState::Scanning)
    {
        [_mixedReality renderSceneMeshFromColorCameraViewpointWithStyle:_display.currentGLRenderStyle
                                                   associatedColorFrame:prediction.associatedColorFrame];
    }
    else
    {
        // During tracking, leave the possibility to render using a different modelView or projection matrix
        // if we want to. Still using the color camera one as an example, but this can be changed.
        
        // modelView is colorCameraFromWorld, we need to invert it.
        GLKMatrix4 modelView = GLKMatrix4Invert(prediction.associatedColorFramePose, nullptr);
        // GLKMatrix4 projection = _display.projectionMatrix;
        GLKMatrix4 projection = prediction.colorFrameGLProjection; // for MR

        // Update the controller's camera world transform, so we're tracking with it.
        [BEController sharedController].cameraTransform = modelView;
        
        [_mixedReality renderSceneMeshWithStyle:_display.currentGLRenderStyle
                                      modelView:modelView
                                     projection:projection
                           associatedColorFrame:prediction.associatedColorFrame];
    }
    
    [glView presentFramebuffer];
}

- (void)dumpTrackerState
{
    switch (_mixedReality.lastTrackerPoseAccuracy)
    {
        case BETrackerPoseAccuracyHigh:
            be_dbg ("Tracker accuracy is high.");
            break;
            
        case BETrackerPoseAccuracyLow:
            be_dbg ("Tracker accuracy is low.");
            break;
            
        case BETrackerPoseAccuracyNotAvailable:
            be_dbg ("Tracker accuracy is not available (sensor not connected?).");
            break;
    }
    
    BETrackerHints hints = _mixedReality.lastTrackerHints;
    be_dbg ("Tracker hints [isOrientationOnly=%d] [mappedAreaNotVisible=%d] [modelVisibilityPercentage=%f]",
            hints.isOrientationOnly, hints.mappedAreaNotVisible, hints.modelVisibilityPercentage);
}

// --------------------------------------------
// MixedReality Delegate Methods

- (void)mixedRealitySensorsStatusChanged:(BESensorsStatus)sensorsStatus
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
    // No SceneKit setup editing in headless mode.
    be_assert (false, "Should never get called.");
}

- (void) mixedRealityDidLoadScene:(BEMappedAreaStatus)mappedAreaStatus
{
    // Retrieve the mesh once the scene is loaded.
    
    BEMesh* beMesh = [_mixedReality lockAndGetSceneMesh];
    NSLog(@"Loaded BEMesh: %d meshes", [beMesh numberOfMeshes]);
    if ([beMesh numberOfMeshes] > 0)
    {
        NSLog(@"First submesh: %d vertices, ptr=%p", [beMesh numberOfMeshVertices:0], [beMesh meshVertices:0]);
    }
    [_mixedReality unlockSceneMesh];
}

- (void)mixedRealityMarkupEditingEnded
{
    // No markup editing in headless mode.
    be_assert (false, "Should never get called.");
}

- (void)mixedRealityMarkupDidChange:(NSString*)markupChangedName
{
    // no markups in headless mode.
    be_assert (false, "Should never get called.");
}

- (void)mixedRealityUpdateAtTime:(NSTimeInterval)time
{
    // This method is never called in headless mode. You need to create your own game/randering loop.
    be_assert (false, "Should never get called.");
}

// end MixedReality Delegate Methods
// --------------------------------------------

// --------------------------------------------
// BEController Delegate Methods
// see the delegate definition for other optional meth0ds

- (void)controllerDidConnect
{
    be_dbg("controllerDidConnect");
}

- (void)controllerDidPressButton
{
    be_dbg("controllerDidPressButton");
}

- (void)controllerDidHoldButton
{
    be_dbg("controllerDidHoldButton");
}

// end BEController Delegate Methods
// --------------------------------------------

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    // add custom code here.
}

- (void) changeRenderMode
{
    const int styleIndex = (_display.currentGLRenderStyle + 1) % BEOpenGLRenderStyle::BEOpenGLRenderStyleCustomShader;
    _display.currentGLRenderStyle = (BEOpenGLRenderStyle)styleIndex;
}

- (IBAction)enterTrackingModeButtonPressed:(id)sender {

    self.appState = AppState::Tracking;
    [_mixedReality startWithSavedSceneAtPath:BRIDGEENGINESCENE_PATH];
    _display.currentGLRenderStyle = BEOpenGLRenderStyleColorCameraAndWireframe;
    
}

- (IBAction)startStopScanningButtonPressed:(id)sender {
    
    switch (_appState)
    {
        case AppState::EnteredScanningMode:
        {
            self.appState = AppState::Scanning;
            [_mixedReality startScanning];
            break;
        }
            
        case AppState::Scanning:
        {
            self.appState = AppState::Tracking;
            [_mixedReality stopScanningAndExportToPath:BRIDGEENGINESCENE_PATH];
            break;
        }
            
        default:
            NSAssert (false, @"Does not make sense to hit start scanning in that state.");
            break;
    }
    
    _display.currentGLRenderStyle = BEOpenGLRenderStyleColorCameraAndWireframe;
}

- (IBAction)enterScanningModeButtonPressed:(id)sender {
    self.appState = AppState::EnteredScanningMode;
    [_mixedReality enterScanningMode];
    _display.currentGLRenderStyle = BEOpenGLRenderStyleColorCamera;
}

- (IBAction)resetScanningButtonPressed:(id)sender {
    
    NSAssert (_appState == AppState::Scanning, @"Does not make sense to reset scanning in that state.");
    self.appState = AppState::EnteredScanningMode;
    [_mixedReality resetScanning];
}

@end
