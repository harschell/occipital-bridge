/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

// Uncomment this to get performance reports.
// #define BE_PROFILING 1

#import <BridgeEngine/BridgeEngine.h>
#import "BEUnityBaseInterop.h"

// Wireless logging is available, see BridgeEngineAppController.mm 

@class BEView;
@class UnityView;
@class BridgeEngineUnity;

@protocol BridgeEngineUnityDelegate <NSObject>

// Notify our delegate that the engine is ready
- (void) beUnityReady;

@end

@interface BridgeEngineUnity : NSObject

@property(nonatomic, weak) id<BridgeEngineUnityDelegate> delegate;

- (id)initWithUnityView:(UnityView*)unityView unityVC:(UIViewController*)unityVC;
- (void)onDisplayLink;

@end

struct beTrackerHints {
    int32_t isOrientationOnly;
    float modelVisibilityPercentage;
    int32_t mappedAreaNotVisible;
};

struct beStereoSetup {
    struct beVector3 leftPosePosition;
    struct beVector4 leftPoseRotation;
    struct beMatrix4 leftProjection;
    
    struct beVector3 rightPosePosition;
    struct beVector4 rightPoseRotation;
    struct beMatrix4 rightProjection;
};

struct beTextureInfo {
    uint32_t textureId;
    int32_t width;
    int32_t height;
    struct beMatrix4 texturePerspectiveProj;
    struct beMatrix4 textureViewpoint;
};

struct BETrackerUpdateInterop
{
    double timestamp;
    struct beVector3 position;
    struct beVector3 scale;
    struct beVector4 rotationQuaternion;
    int32_t trackerPoseAccuracy;
    struct beTrackerHints trackerHints;
    struct beStereoSetup stereoSetup;
    struct beTextureInfo cameraTextureInfo;
};

#pragma mark - Interop Callback Types

typedef void (*BETrackerEventCallback)(BETrackerUpdateInterop trackerUpdateInterop);
typedef void (*BEMeshEventCallback)(int32_t meshIndx, int32_t meshCount, int32_t verticesCount, intptr_t positions, intptr_t normals, intptr_t colors, intptr_t uvs, int32_t indiciesCount, intptr_t indicies);

#pragma mark - Interop Functions

extern "C"
{
    /// Check if BE is running in stereo mode 
    bool be_isStereoMode();
    
    /// get a pointer to a delegate in Mono from Unity to send tracker updates
    void be_registerTrackerEventCallback(void (*cb)(BETrackerUpdateInterop));
    
    /// get a pointer to a delegate in Mono from Unity to send mesh updates
    void be_registerScannedMeshEventCallback(BEMeshEventCallback cb);
}
