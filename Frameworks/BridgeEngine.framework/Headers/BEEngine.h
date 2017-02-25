/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

//------------------------------------------------------------------------------

@class BEView;

//------------------------------------------------------------------------------

/// if enabled, the app will attempt to load a replay of Structure Sensor data from device. This allows for debugging while the device is plugged in to a development machine.
BE_API extern NSString* const kBECaptureReplayMode;

/// if enabled, the tracker will still output rotation-only updates when it gets lost, based on the IMU.
BE_API extern NSString* const kBETrackerFallbackOnIMUEnabled;

/// if enabled, the visual-inertial pose filter will make the tracking output smoother, at the cost of potentially slightly more latency.
BE_API extern NSString* const kBEVisualInertialPoseFilterEnabled;

/// set to true if the app expects a WideVisionLens to be attached. This must correspond to whether a WVL is physically attached or not.
BE_API extern NSString* const kBEUsingWideVisionLens;

/// enable this to render in stereo, as required for a head-mounted display.
BE_API extern NSString* const kBEStereoRenderingEnabled;

/// enable this to track without a Structure Sensor.
BE_API extern NSString* const kBEUsingColorCameraOnly;

/// if enabled some recording options will be shown during tracking in mono mode.
BE_API extern NSString* const kBERecordingOptionsEnabled;

/// if enabled the UI will require the user to connect a controller before loading the app.
BE_API extern NSString* const kBERequireConnectedController;

/// enable scanning in headset (beta feature)
BE_API extern NSString* const kBEEnableStereoScanningBeta;

/// control the voxel size used for the mapping phase. Larger voxels allow scanning a larger area, at decreased accuracy
BE_API extern NSString* const kBEMapperVolumeResolutionKey;


//------------------------------------------------------------------------------

/// Bridge Engine Capture Replay Mode
typedef NS_ENUM(NSInteger, BECaptureReplayMode) {
    
    /// No capture replay, the real sensor will be used.
    BECaptureReplayModeDisabled      = 0,
    
    /// Replay a recorded sequence at approximately the sensor rates, but never skipping any frame.
    BECaptureReplayModeDeterministic = 1,
    
    /// Simulate the sensor timings as accurately as possible, potentially dropping if user processing is too slow.
    BECaptureReplayModeRealTime      = 2
};

/// Bridge Engine Mapped Area Status
typedef NS_ENUM(NSInteger, BEMappedAreaStatus) {
    
    /// Could not find a mapped area to reload. The user should scan a new area first.
    BEMappedAreaStatusNotFound    = -1,
    
    /// Could reload the mapped area.
    BEMappedAreaStatusLoaded      = 0
};

/// Bridge Engine Rendering Style
typedef NS_ENUM(NSInteger, BERenderStyle)
{
    BERenderStyleInvalid                             = -1,
    
    /// SceneKit virtual objects and live iOS camera feed
    BERenderStyleSceneKitAndColorCamera              = 0,
    
    /// SceneKit virtual objects, live iOS camera feed and wireframe overlay on the mapped area.
    BERenderStyleSceneKitAndColorCameraAndWireframe  = 1,
    
    /// SceneKit virtual objects, and wireframe overlay on the mapped area.
    BERenderStyleSceneKitAndWireframe                = 2,
    
    /// Only the SceneKit virtual objects
    BERenderStyleSceneKitOnly                        = 3,
    
    /// SceneKit virtual objects and a custom rendering of the mapped area mesh
    BERenderStyleSceneKitAndCustomEnvironmentShader  = 4,
    
    /// SceneKit virtual objects and an adaptive collision avoidance shader only showing nearby geometry of the mapped area.
    BERenderStyleSceneKitAndCollisionAvoidance       = 5,
    
    NumBERenderStyles
};

/** Bridge Engine OpenGL Rendering Style
 
 These are the valid rendering modes for the low-level OpenGL API.
 
 */
typedef NS_ENUM(NSInteger, BEOpenGLRenderStyle)
{
    BEOpenGLRenderStyleInvalid                       = -1,
    
    /// Collision-avoidance shader, only showing nearby geometry.
    BEOpenGLRenderStyleCollisionAvoidance            = 0,
    
    /// Grid-like wireframe.
    BEOpenGLRenderStyleWireframe                     = 1,
    
    /// Shaded grayscale.
    BEOpenGLRenderStyleShadedGray                    = 2,
    
    /// Won't apply any shader, assumes a GL program is already set.
    BEOpenGLRenderStyleCustomShader                  = 3,

    NumBEOpenGLRenderStyles
};

/** Bridge Engine Collision Categories
 
 Can be used to make objects only interact with some specific elements of the scene.
 
 */

typedef NS_ENUM(NSInteger, BECollisionCategory)
{
    /// The mapped area.
    BECollisionCategoryRealWorld                     = SCNPhysicsCollisionCategoryStatic, // 1 << 1
    
    /// The virtual SceneKit objects.
    BECollisionCategoryVirtualObjects                = 1 << 2,
    
    /// A virtual infinite floor plane, aligned with the ground of the mapped area.
    BECollisionCategoryFloor                         = 1 << 3
};

/** Bridge Engine Sensors Status
 
 Hints about what the user should do to leverage the sensors.
 
 */
typedef struct {
    
    bool allSensorsReady; // if this is true, all the other flags are false.
    
    bool needToConnectDepthSensor;
    bool needToChargeDepthSensor;
    
    bool needToRunCalibrator;
    bool needToAuthorizeIOSCamera;
    
} BESensorsStatus;

/** Bridge Engine Pose Accuracy
 
 If the mapped area is visible and we are tracking against it, pose accuracy will be BETrackerPoseAccuracyHigh
 
*/
typedef NS_ENUM(NSInteger, BETrackerPoseAccuracy)
{
    /// Maybe tracking was not started yet, or the tracker got totally lost.
    BETrackerPoseAccuracyNotAvailable    = 0,
    
    /// The tracker is estimating accurate poses, you can run your experience
    BETrackerPoseAccuracyHigh            = 1,
    
    /// The tracker is struggling to keep track (e.g. getting out of the mapped area). Still returning poses, but may not be accurate. Check the associated BETrackerHints to get more details.
    BETrackerPoseAccuracyLow             = 2,
};

/** Bridge Engine Tracker Hints
 
 Additional information returned by the tracker.
 
 */
typedef struct
{
    /** Return the percentage of the view that contains the mapped area
      The returned float value will between 0 and 1, or NaN if not available.
      Will be NAN if not available.
      Useful to warn users before they lose tracking.
    */
    float modelVisibilityPercentage;
    
    /// true if the mapped area is not in view anymore (or only very partially)
    bool mappedAreaNotVisible;
    
    /// true if tracking was failing and fellback to orientation only with the IMU.
    bool isOrientationOnly;
    
} BETrackerHints;


// Rendering State Enums

/** Bridge Engine Node Rendering Order 
 
    The rendering order of certain nodes in the SceneKit scene graph. 
    For proper transparency blending, transparent objects like particle systems must be rendered after the Environment Scan.
    e.g. `[yourTransparentSCNNode setRenderingOrder:BEEnvironmentScanRenderingOrder + 1]`
 */
typedef NS_ENUM(NSInteger, BENodeRenderingOrder)
{
    /// The order that SceneKit will render the environment scan mesh
    BEEnvironmentScanRenderingOrder         =   99999,
    
    /// The order that SceneKit will composite shadows on the environment scan mesh
    BEEnvironmentScanShadowRenderingOrder   =   BEEnvironmentScanRenderingOrder + 1
};

/** Bridge Engine Shadow casting categories
 
    Casting shadows is controlled by the node's categoryBitMask. Shadows are accomplished by maintaining two SCNLightTypeSpot in the same location.
    If a node's `(categoryBitMask & BEShadowCategoryBitMaskCastShadowOntoEnvironment) > 0` it will be rendered into the AR shadow map.
    If a node's `(categoryBitMask & BEShadowCategoryBitMaskCastShadowOntoSceneKit) > 0` it will be rendered into the SceneKit shadow map.
 
    For SceneKit nodes, they will receive shadows from any other nodes with the mask BEShadowCategoryBitMaskCastShadowOntoSceneKit.
    For the scanned room mesh, it will recieve shadows from SceneKit objects with the mask BEShadowCategoryBitMaskCastShadowOntoEnvironment.
 
 */
typedef NS_ENUM(NSInteger, BEShadowCategoryBitMask)
{
    /// Default, node will be rendered when relocalized and tracking
    BEShadowCategoryBitMaskDefault                          =   1,

    /// The node should cast shadows onto the scanned room mesh (does not include SceneKit objects).
    BEShadowCategoryBitMaskCastShadowOntoEnvironment        =   2,
    
    /// The node should cast shadows onto other 3D objects in the SceneKit scene (does not include scanned room mesh).
    BEShadowCategoryBitMaskCastShadowOntoSceneKit           =   4,
    
};
