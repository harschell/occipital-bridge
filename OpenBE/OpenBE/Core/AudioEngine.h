/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <BridgeEngine/BridgeEngine.h>

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <JavascriptCore/JavascriptCore.h>

@class AudioNode;

/**

 Audio Engine class built on top of the lower-level BEAudioEngine class.
 
*/

@interface AudioEngine : NSObject

/// Singleton.
+ (AudioEngine*) main;

/**
 * Single shot audio playback at volume.
 */
- (void) playAudio:(NSString*)named atVolume:(float)volume;

/**
 * Load an audio file and return an audio node.
 */
- (AudioNode*) loadAudioNamed:(NSString*)name;

@end

/**
 * Make the AudioNode objects usable in a JS context.
 */
@protocol AudioNodeJSExports <JSExport>
@property(nonatomic, copy) NSString *name;
@property(nonatomic) float volume;
@property(nonatomic, readonly) float duration;
@property(nonatomic) BOOL looping;

- (void)play;
- (void)stop;
@end

@interface AudioNode : NSObject <AudioNodeJSExports>
@property(nonatomic, copy) NSString *name;
@property(nonatomic) float volume;
@property(nonatomic, readonly) float duration;
@property(nonatomic) BOOL looping;

// Internal player object... useful for looping control in the RobotMeshControllerComponent, but normaly don't touch.
@property(nonatomic, strong) AVAudioPlayerNode *player;

- (instancetype)initWithName:(NSString*)name buffer:(AVAudioPCMBuffer*)buffer player:(AVAudioPlayerNode*) player;

- (void)play;
- (void)stop;

@end
