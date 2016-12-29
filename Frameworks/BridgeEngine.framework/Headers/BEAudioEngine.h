/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <AVFoundation/AVFoundation.h>

/** Bridge Engine Audio Engine Singleton
 
 Initializes a single AVAudioEngine in a Bridge Engine application.
 
*/

BE_API
@interface BEAudioEngine : NSObject

/// Singleton.
+ (BEAudioEngine*) sharedEngine;

// Preventing a classical init, use sharedController.
- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, strong) AVAudioSession *audioSession;
@property(nonatomic, strong) AVAudioEngine *audioEngine;
@property(nonatomic, strong) AVAudioEnvironmentNode *audioEnvironment;

@end
