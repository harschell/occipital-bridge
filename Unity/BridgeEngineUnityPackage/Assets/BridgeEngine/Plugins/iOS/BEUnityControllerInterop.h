/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

#import "BEUnityBaseInterop.h"

#if TARGET_OS_IOS
#import <BridgeEngine/BridgeEngine.h>
#else
#import "BEController.h"
#endif

// Interop for communicating with BridgeEngineUnity.cs
#pragma mark - Interop Data Structures



#pragma mark - Interop Callback Types

typedef void (*BEControllerMotionEventCallback)(beVector3 position, beVector4 rotationQuaternion);
typedef void (*BEControllerButtonEventCallback)(BEControllerButtons current, BEControllerButtons up, BEControllerButtons down);
typedef void (*BEControllerTouchEventCallback)(beVector2 position, BEControllerTouchStatus status);

#pragma mark - Interop Functions

extern "C"
{
    /// Initialize a controller class that will hook delegates and callback the registered interop callbacks.
    void beControllerInit();
    
    /// Updated the controller frame from Unity's camera tracking.
    void beControllerUpdateCamera( beMatrix4 cameraTransform );

    /// Check if the bridge controller is presently connected.
    bool beControllerIsBridgeControllerConnected();
    
    // get a pointer to a delegate in Mono from Unity to send controller updates
    void be_registerControllerEventDidConnectCallback(void (*cb)());
    void be_registerControllerEventDidDisconnectCallback(void (*cb)());
    void be_registerControllerMotionEventCallback(void (*cb)(beVector3, beVector4));
    void be_registerControllerButtonEventCallback(void (*cb)(BEControllerButtons, BEControllerButtons, BEControllerButtons));
    void be_registerControllerTouchEventCallback(void (*cb)(beVector2, BEControllerTouchStatus));
}

#pragma mark - Interop Class

@interface BEUnityInteropController : NSObject
@property( nonatomic, strong ) BEController *beController;
@end
