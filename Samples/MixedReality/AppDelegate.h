/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <UIKit/UIKit.h>

/// Use the 120° Wide View Lens
#define SETTING_USE_WVL                         @"useWVL"

/// Load existing scan and track using only the Color Camera, no structure sensor.  This is useful for debugging a live scene while wired.
#define SETTING_COLOR_CAMERA_ONLY               @"colorCameraOnly"

/// Render in stereo, for use in Bridge Headset
#define SETTING_STEREO_RENDERING                @"stereoRendering"

/// Use the in-headset stereo scanning UI
#define SETTING_STEREO_SCANNING                 @"stereoScanning"

/// Replay the last OCC recording.  This is useful for debugging and highly repeatable.
#define SETTING_REPLAY_CAPTURE                  @"replayCapture"

/// Enable the OCC in-scene recording interface.
#define SETTING_ENABLE_RECORDING                @"enableRecording"

/// Check to make sure we are executing on device
#if TARGET_IPHONE_SIMULATOR
#error Bridge Engine Framework requires an iOS device to build. It cannot be run on the simulator.
#endif

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navController;

@end

