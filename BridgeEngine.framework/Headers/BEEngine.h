/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------

@class BEView;

//------------------------------------------------------------------------------

// if capture replay is enabled, the app will attempt to load a replay of Structure Sensor data from device. This allows for debugging while the device is plugged in to a development machine
BE_API extern NSString* const kBECaptureReplayEnabled;
// set to true if the app expects a WideVisionLens to be attached. This must correspond to whether a WVL is physically attached or not.
BE_API extern NSString* const kBEUsingWideVisionLens;
// render stereo, as if for a head-mounted display
BE_API extern NSString* const kBEStereoRenderingEnabled;
// set to true if you want to track without a Structure Sensor.
BE_API extern NSString* const kBEUsingColorCameraOnly;
// set to true to enable recording options during tracking
BE_API extern NSString* const kBERecordingOptionsEnabled;

//------------------------------------------------------------------------------

/** Bridge Engine Stage Status
 Whether the files associated with the stage are available
 */
typedef NS_ENUM(NSInteger, BEStageLoadingStatus) {
    BEStageLoadingStatusNotFound    = -1,
    BEStageLoadingStatusLoaded      = 0
};

/** Bridge Engine Rendering Style
 
 SceneKit represents any virtual objects
 ColorCamera is the live camera
 Wireframe is a wireframe overlaying the scanned geometry. Rendering wireframe is useful to users so they can avoid running into real-world objects, especially when you are not rendering the color camera.
 
*/
typedef NS_ENUM(NSInteger, BERenderStyle)
{
    BERenderStyleInvalid                             = -1,
    BERenderStyleSceneKitAndColorCamera              = 0,
    BERenderStyleSceneKitAndColorCameraAndWireframe  = 1,
    BERenderStyleSceneKitAndWireframe                = 2,
    BERenderStyleSceneKitOnly                        = 3,
    BERenderStyleSceneKitAndCustomEnvironmentShader  = 4,
    NumBERenderStyles
};

/** Bridge Engine Rendering Style
 
 If the scanned scene is visible and we are tracking against it, tracking is nominal
 
*/
typedef NS_ENUM(NSInteger, BETrackingState)
{
    BETrackingStateNominal               = 0,    //all is well, you can run your experience
    BETrackingStateNotTracking           = 1,    //tracking may be poor for a few reasons (sensor disconnected, model not in view)
    //BETrackingNot will be replaced by more descriptive states later.
    BETrackingStateUnknown               = -1
};

