/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#if TARGET_OS_IOS
#import <GLKit/GLKit.h>
#import "BridgeEngineUnity.h"
#import "BridgeEngineAppController.h"

#import "IUnityInterface.h"
#import "IUnityGraphics.h"
#endif

#import "BEUnityControllerInterop.h"

static BEUnityInteropController *beControllerInterop = nil;

#pragma mark - Interop Callbacks

static BEVoidEventCallback controllerBridgeEngineEventDidConnect;
static BEVoidEventCallback controllerBridgeEngineEventDidDisconnect;

static BEControllerMotionEventCallback controllerBridgeEngineMotionEvent;
static BEControllerTouchEventCallback controllerBridgeEngineTouchEvent;
static BEControllerButtonEventCallback controllerBridgeEngineButtonEvent;

#pragma mark - Interop Functions

extern "C"
{
    /// Initialize a controller class that will hook delegates and callback the registered interop callbacks.
    void beControllerInit() {
        beControllerInterop = [[BEUnityInteropController alloc] init];
    }
    
    void beControllerShutdown() {
        beControllerInterop = nil;
    }

    /// Update the controller from cameraTransform matrix
    void beControllerUpdateCamera( beMatrix4 cameraTransform ) {
        GLKMatrix4 beCameraMatrix = Unity2BEMatrix((GLKMatrix4&)cameraTransform.m);
        [beControllerInterop.beController setCameraTransform:beCameraMatrix];
    }
    
    /// Check if the bridge controller is presently connected.
    bool beControllerIsBridgeControllerConnected() {
        return beControllerInterop.beController.isBridgeControllerConnected;
    }
    
    // get a pointer to a delegate in Mono from Unity to send controller updates
    void be_registerControllerEventDidConnectCallback(void (*cb)())
    {
        controllerBridgeEngineEventDidConnect = cb;
    }

    void be_registerControllerEventDidDisconnectCallback(void (*cb)())
    {
        controllerBridgeEngineEventDidDisconnect = cb;
    }
    
    void be_registerControllerMotionEventCallback(void (*cb)(beVector3, beVector4))
    {
        controllerBridgeEngineMotionEvent = cb;
    }
    
    void be_registerControllerButtonEventCallback(void (*cb)(BEControllerButtons, BEControllerButtons, BEControllerButtons))
    {
        controllerBridgeEngineButtonEvent = cb;
    }
    
    void be_registerControllerTouchEventCallback(void (*cb)(beVector2, BEControllerTouchStatus))
    {
        controllerBridgeEngineTouchEvent = cb;
    }
}

#pragma mark - Interop Class

@interface BEUnityInteropController () <BEControllerDelegate>
@end

@implementation BEUnityInteropController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Activate the controller and hook up the delegate handlers.
        self.beController = [[BEController alloc] init];
        _beController.delegate = self;
    }
    return self;
}

#pragma mark - BEControllerDelegate

- (void)controllerDidConnect
{
    if (controllerBridgeEngineEventDidConnect) {
        NSLog(@"controllerBridgeEngineEventDidConnect");
        controllerBridgeEngineEventDidConnect();
    }
}

- (void)controllerDidDisconnect
{
    if (controllerBridgeEngineEventDidDisconnect) {
        NSLog(@"controllerBridgeEngineEventDidDisconnect");
        controllerBridgeEngineEventDidDisconnect();
    }
}

/**
 * Controller motion event:
 * @parameter orientation Controller position and rotatation in world coordinate space
 */
- (void)controllerMotionTransform:(GLKMatrix4)transform
{
    //    controllerUpdateInterop.poseTimestamp = ::msecFromMach(mach_absolute_time());
    
    GLKMatrix4 unityMatrix = BE2UnityMatrix(transform);
    beVector3 position = GLKMatrix4ToPositionVector3(unityMatrix);
    beVector4 rotationQuaternion = GLKMatrix4ToVector4Quaternion(unityMatrix);
    
    //    controllerUpdateInterop.position = position;
    //    controllerUpdateInterop.rotationQuaternion = rotationQuaternion;
    
    if (controllerBridgeEngineMotionEvent) {
        controllerBridgeEngineMotionEvent(position, rotationQuaternion);
    }
}

/**
 * Called when any button is pressed or released
 * @parameter buttons Current state of all buttons (1 - held down, 0 - released)
 * @parameter buttonsDown Buttons that have changed to down state (1 - click down, 0 - no change)
 * @parameter buttonsUp Buttons that have changed to released state (1 - released, 0 - no change)
 */
- (void)controllerButtons:(BEControllerButtons)buttons down:(BEControllerButtons)buttonsDown up:(BEControllerButtons)buttonsUp
{
    NSLog(@"controllerButtons:%@ down:%@ up:%@", @(buttons), @(buttonsDown), @(buttonsUp));
    
    //    // Update the button state
    //    controllerUpdateInterop.buttons = buttons;
    
    if (controllerBridgeEngineButtonEvent) {
        controllerBridgeEngineButtonEvent(buttons, buttonsDown, buttonsUp);
    }
}

/**
 * Controller touch events
 * @parameter position relative position across the touch pad
 * @parameter status Active tracking touch status
 */
- (void)controllerTouchPosition:(GLKVector2)position status:(BEControllerTouchStatus)status
{
    if (controllerBridgeEngineTouchEvent) {
        beVector2 p = GLKVector2ToVector2(position);
        
        controllerBridgeEngineTouchEvent(p, status);
    }
}


@end
