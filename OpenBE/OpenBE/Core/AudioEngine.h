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
 Audio Engine class built to render audio into the BridgeEngine scene environment.
 Handles re-initialization based on audio configuration changes and interruptions.
*/
@interface AudioEngine : NSObject

/// Singleton.
+ (AudioEngine*) main;

/**
 * Check if AudioEngine is currently running.
 */
@property (nonatomic, getter=isRunning) BOOL running;


/**
 * Single shot audio playback at volume.
 * THREAD SAFE
 */
- (AudioNode *)playAudio:(NSString*)named atVolume:(float)volume;

/**
 * Load an audio file and return an audio node.
 * RUN ON MAIN THREAD ONLY
 */
- (AudioNode*) loadAudioNamed:(NSString*)name;

/**
 * Take in the Camera node, and update the listener position and orientation.
 * THREAD SAFE
 */
- (void) updateListenerFromCameraNode:(SCNNode*)cameraNode;

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
@property(nonatomic) BOOL playing;
@property(nonatomic) SCNVector3 position;

// Internal player object... useful for looping control in the RobotMeshControllerComponent, but normaly don't touch.
@property(nonatomic, strong) AVAudioPlayerNode *player;

// Allocate new AudioNode objects with AudioEngine.

/// Play the audio.  THREAD SAFE
- (void)play;

// Stop the audio from playing.  THREAD SAFE
- (void)stop;

@end
