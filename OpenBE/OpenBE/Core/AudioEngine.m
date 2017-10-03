/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// See "AVAudioEngine 3D Audio Example" for reference implementation
// https://developer.apple.com/library/content/samplecode/AVAEGamingExample/Introduction/Intro.html

#import "../Core/Core.h"
#import "AudioEngine.h"
#import "../Utils/SceneKitExtensions.h"

#pragma mark - Internal Forward Declared Interfaces

@interface AudioEngine () {
    NSMutableDictionary<NSString*,AudioNode*> *_nodeDictionary;
    NSMutableDictionary<NSString*,AVAudioPCMBuffer*> *_bufferDictionary;
}

@property(nonatomic, strong) AVAudioEngine *engine;
@property(nonatomic, strong) AVAudioEnvironmentNode *environment;

@property(nonatomic, strong) id<NSObject> observeAVEngineConfigurationChange;

- (instancetype) init;

@end


@interface AudioNode () {
    float _volume;
}

@property(nonatomic, strong) AVAudioPCMBuffer *buffer;
@property(nonatomic, weak) AVAudioEngine *engine;

- (instancetype)initWithName:(NSString*)name buffer:(AVAudioPCMBuffer*)buffer engine:(AVAudioEngine*)engine;

- (void) restorWithEngine:(AVAudioEngine*)engine;

@end

#pragma mark - AudioEngine

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
        _nodeDictionary = [[NSMutableDictionary alloc] init];
        _bufferDictionary = [[NSMutableDictionary alloc] init];
        
        // Set up the audio category so we always hear the sound.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

        [self startEngine];
    }
    return self;
}

- (void) dealloc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if( _engine && _observeAVEngineConfigurationChange ) {
        [nc removeObserver:_observeAVEngineConfigurationChange];
        _observeAVEngineConfigurationChange = nil;
    }
}


- (void) startEngine {
//    NSAssert([NSThread isMainThread], @"AudioEngine called outside of main thread");
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    if( _engine && _observeAVEngineConfigurationChange ) {
        [nc removeObserver:_observeAVEngineConfigurationChange];
        _observeAVEngineConfigurationChange = nil;
    }

    //create audio engine to play sounds
    _engine = [[AVAudioEngine alloc] init];

    // Get notifications about changes in output configuration
    __weak AudioEngine *weakSelf = self;
    _observeAVEngineConfigurationChange = [nc
        addObserverForName:AVAudioEngineConfigurationChangeNotification
        object:_engine
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification * _Nonnull note)
        {
           NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
           AudioEngine *strongSelf = weakSelf;
           if( strongSelf ){
            [self handleAudioConfigurationChange:note];
           }
        }
    ];
    
    //adding 3d audio environment
    _environment = [[AVAudioEnvironmentNode alloc] init];
    [_environment setRenderingAlgorithm:AVAudio3DMixingRenderingAlgorithmSphericalHead];
    [_environment setVolume:1.0];
    [_environment setOutputVolume:1.0];
    [_environment setReverbBlend:0.5];

    // Attach the audio environment.
    [_engine attachNode:_environment];
    [_engine connect:_environment to:[_engine mainMixerNode] format:nil];

    NSError *error = nil;
    BOOL audioStartResult = [_engine startAndReturnError:&error];
    if(audioStartResult == NO || error != nil) {
        NSLog(@"Audio Engine Start Error: %@", error.localizedDescription);
        return;
    } else {
        NSLog(@"Audio Engine Started OK");
    }
        
    // Connect all of the players to the audio environment, and reset the rendering algorithm to match.
    for( NSString *nodeName in _nodeDictionary ) {
        AudioNode* node = _nodeDictionary[nodeName];
        [node restorWithEngine:_engine];
        [_engine connect:node.player to:_environment format:nil];
//        // Restart playback of looping nodes.
//        if( node.looping ) {
//            NSLog(@"Resuming Loopig Audio: %@", nodeName);
//            [node play];
//        }
     }
 }

- (void) handleAudioConfigurationChange:(NSNotification*)notification {
//    NSAssert([NSThread isMainThread], @"AudioEngine handleAudioConfigurationChange called outside of main thread");

    NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
    NSLog(@"Re-wiring connections and starting once again");
    [_engine startAndReturnError:nil];
    for( NSString *nodeName in _nodeDictionary ) {
        AudioNode *node = _nodeDictionary[nodeName];
        [node restorWithEngine:_engine];
    }
}


/**
 * Load and cache sound buffers by name from <resources>/Sounds/<named>
 */
- (AVAudioPCMBuffer*)bufferForName:(NSString*)named {
    AVAudioPCMBuffer *aBuff = _bufferDictionary[named];
    if(aBuff == nil ) {
        // Attempt loading the audio subfolder.
        NSString *soundPath = [SceneKit pathForResourceNamed:[@"Sounds" stringByAppendingPathComponent:named]];
        NSURL *aURL = [NSURL fileURLWithPath:soundPath];
        
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
- (AudioNode*) nodeWithBuffer:(AVAudioPCMBuffer*)buffer named:(NSString*)named {
    AudioNode *node = _nodeDictionary[named];
    if(node == nil) {
        // Add this to the player pool.
        node = [[AudioNode alloc] initWithName:named buffer:buffer engine:_engine];
        _nodeDictionary[named] = node;
    }

    return node;
}

/**
 * Single shot audio playback at volume.
 */
- (AudioNode*) playAudio:(NSString*)named atVolume:(float)volume {
    //occasionally, this can get called if the audio engine is not running.
    if (![_engine isRunning]){
        NSLog(@"AudioEngine: AudioEngine not running, could not play audio: %@", named);
        return nil;
    }
    
    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"AudioEngine: Could not play, missing audio: %@", named);
        return nil;
    }
    
    AudioNode *node = [self nodeWithBuffer:buffer named:named];

    //  Schedule the one-shot for immediate playback.
    [node.player scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    node.volume = volume;
    [node play];
    return node;
}

/**
 * Load an audio file and return an audio node.
 */
- (AudioNode*) loadAudioNamed:(NSString*)named {
    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"AudioEngine: Could not load, missing audio: %@", named);
        return nil;
    }
    
    AudioNode *audioNode = [self nodeWithBuffer:buffer named:named];
    return audioNode;
}

/**
 * Take in the Camera node, and update the listener position and orientation.
 */
- (void) updateListenerFromCameraNode:(SCNNode*)cameraNode {
    SCNVector3 sp = cameraNode.position;
    [_environment setListenerPosition:AVAudioMake3DPoint(sp.x, sp.y, sp.z)];

    SCNQuaternion so = cameraNode.orientation;
    GLKQuaternion go = GLKQuaternionMake( so.x, so.y, so.z, so.w );
    GLKVector3 gfwd = GLKQuaternionRotateVector3(go, GLKVector3Make(0, 0, -1));
    GLKVector3 gup = GLKQuaternionRotateVector3(go, GLKVector3Make(0, 1, 0));
    

    AVAudio3DVector afwd = AVAudioMake3DVector(gfwd.x, gfwd.y, gfwd.z);
    AVAudio3DVector aup = AVAudioMake3DVector(gup.x, gup.y, gup.z);

    [_environment setListenerVectorOrientation:AVAudioMake3DVectorOrientation(afwd, aup)];
}

@end

#pragma mark - AudioNode

@implementation AudioNode

- (instancetype)initWithName:(NSString*)name buffer:(AVAudioPCMBuffer*)buffer engine:(AVAudioEngine*)engine
{
    self = [super init];
    if (self) {
        be_assert(buffer && engine, "Null on buffer or engine");
        _name = name;
        _buffer = buffer;
        _volume = 1;
        _player = [[AVAudioPlayerNode alloc] init];
        
        [self restorWithEngine:engine];
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

- (void) setPlaying:(BOOL)value {
    _playing = value;
    
    if( _playing ) {
        if( _looping ) {
            [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferLoops|AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
        } else {
            __weak AudioNode *weakSelf = self;
            [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:^{
                AudioNode *strongSelf = weakSelf;
                if( strongSelf ) {
                    strongSelf->_playing = NO;
                }
            }];
        }
        
        if( [_engine isRunning] == YES ) {
            [_player play];
            _player.volume = _volume;
        } else {
            NSLog(@"AudioEngine is not running, can't play %@", self.name);
        }
    } else {
        [_player stop];
    }
}

- (float) duration {
    return _buffer.frameLength / _buffer.format.sampleRate;
}

- (void) setPosition:(SCNVector3)position {
    _player.position = AVAudioMake3DPoint(position.x, position.y, position.z);
}

- (SCNVector3) position {
    AVAudio3DPoint p = _player.position;
    return SCNVector3Make(p.x, p.y, p.z);
}

- (void) restorWithEngine:(AVAudioEngine*)engine {
    if( _engine ) {
        [_engine detachNode:_player];
    }

    _engine = engine;

    //attach the node to audio engine first
    [_engine attachNode:_player];
    
    //assign format to node
    [_engine connect:_player to:[_engine mainMixerNode] format:[_buffer format]];

    // Restore playing state, only restart looping audio.
    if( _playing ) {
        if( _looping ) {
            [self setPlaying:YES];
        } else {
            // FIXME: resume playing if there's more audio to continue playing.
            _playing = NO;
        }
    }
}

- (void) play {
    [self setPlaying:YES];
}

- (void) stop {
    [self setPlaying:NO];
}
@end
