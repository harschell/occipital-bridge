/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "AudioEngine.h"
#import "../Utils/SceneKitExtensions.h"

@interface AudioEngine () {
    NSMutableDictionary *_playerDictionary;
    NSMutableDictionary *_bufferDictionary;
}

- (instancetype) init;

@end

@implementation AudioEngine

+ (AudioEngine*) main {
    static AudioEngine *mainEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainEngine = [[AudioEngine alloc] init];
    });
    
    return mainEngine;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        //store audioNodes to play in a dictionary
        _playerDictionary = [[NSMutableDictionary alloc] init];
        _bufferDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/**
 * Load and cache sound buffers by name from <resources>/Sounds/<named>
 */
- (AVAudioPCMBuffer*)bufferForName:(NSString*)named {
    AVAudioPCMBuffer *aBuff = _bufferDictionary[named];
    if(aBuff == nil ) {
        // Attempt loading the audio subfolder.
        NSString* soundsFolder = [SceneKit pathForResourceNamed:@"Sounds"];
        
        NSString *path = [soundsFolder stringByAppendingPathComponent:named];

        NSURL *aURL = [NSURL fileURLWithPath:path];
        
        AVAudioFile *aFile = [[AVAudioFile alloc] initForReading:aURL error:nil];
        if( aFile == nil ) {
            return nil;
        }
        
        //read file to buffer
        aBuff = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[aFile processingFormat] frameCapacity:(unsigned int)[aFile length]];
        [aFile readIntoBuffer:aBuff error:nil];
        
        // Keep buffers cached.
        _bufferDictionary[named] = aBuff;
    }
    
    return aBuff;
}

/**
 * Create a player node with buffer.
 */
- (AVAudioPlayerNode*) playerWithBuffer:(AVAudioPCMBuffer*)buffer named:(NSString*)named {
    AVAudioPlayerNode *player = _playerDictionary[named];
    AVAudioEngine* audioEngine = [BEAudioEngine sharedEngine].audioEngine;
    if(player == nil) {
        //make a node for the sound
        AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
        
        //attach the node to audio engine first
        [audioEngine attachNode:player];
        
        //assign format to node
        [audioEngine connect:player to:[audioEngine mainMixerNode] format:[buffer format]];
        
        // Add this to the player pool.
        _playerDictionary[named] = player;
    }

    return player;
}

/**
 * Single shot audio playback at volume.
 */
- (void) playAudio:(NSString*)named atVolume:(float)volume {
        //occasionally, this can get called if the audio engine is not running.
    
    AVAudioEngine* audioEngine = [BEAudioEngine sharedEngine].audioEngine;
    
    if (![audioEngine isRunning]){
        NSLog(@"RobotAudioComponent: AudioEngine not running, could not play audio: %@", named);
        return;
    }
    
    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"RobotAudioComponent: Could not play, missing audio: %@", named);
        return;
    }
    
    AVAudioPlayerNode *player = [self playerWithBuffer:buffer named:named];

    //  Schedule the one-shot for immediate playback.
    [player scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    player.volume = volume;
    [player play];
}

/**
 * Load an audio file and return an audio node.
 */
- (AudioNode*) loadAudioNamed:(NSString*)named {
    
    AVAudioEngine* audioEngine = [BEAudioEngine sharedEngine].audioEngine;
    
    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"RobotAudioComponent: Could not load, missing audio: %@", named);
        return nil;
    }
    
    // Make a stand-alone node
    AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
    
    //attach the node to audio engine first
    [audioEngine attachNode:player];
    
    //assign format to node
    [audioEngine connect:player to:[audioEngine mainMixerNode] format:[buffer format]];

    AudioNode *audioNode = [[AudioNode alloc] initWithName:named buffer:buffer player:player];
    return audioNode;
}

@end

#pragma mark - AudioNode

@interface AudioNode () {
    float _volume;
}

@property(nonatomic, strong) AVAudioPCMBuffer *buffer;
@end

@implementation AudioNode

- (instancetype)initWithName:(NSString*)name buffer:(AVAudioPCMBuffer*)buffer player:(AVAudioPlayerNode*) player
{
    self = [super init];
    if (self) {
        self.name = name;
        self.buffer = buffer;
        self.player = player;
        _volume = player.volume;
    }
    return self;
}

- (void) setVolume:(float)volume {
    _volume = volume;
    _player.volume = volume;
}

- (float) volume {
    return _volume;
}

- (float) duration {
    return _buffer.frameLength / _buffer.format.sampleRate;
}

- (void) play {
    if( _looping ) {
        [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferLoops|AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    } else {
        [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    }
    [_player play];
}

- (void) stop {
    [_player stop];
}
@end
