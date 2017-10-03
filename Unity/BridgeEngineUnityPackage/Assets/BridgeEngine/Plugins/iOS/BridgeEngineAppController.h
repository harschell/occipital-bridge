/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

#import "UnityAppController.h"
#import "UnityAppController+Rendering.h"
#import "UnityAppController+ViewHandling.h"

#define SETTING_REPLAY_CAPTURE                  @"replayCapture"
#define SETTING_USE_WVL                         @"useWVL"
#define SETTING_STEREO                          @"stereo"
#define SETTING_COLOR_CAMERA_ONLY               @"colorCameraOnly"
#define SETTING_AUTO_EXPOSE_DURING_RELOC        @"autoExposeWhileRelocalizing"

@interface BridgeEngineAppController : UnityAppController

/// Check to make sure we are executing on device
#if TARGET_IPHONE_SIMULATOR
#error Bridge Engine Framework requires an iOS device to build. It cannot be run on the simulator.
#endif

@end
