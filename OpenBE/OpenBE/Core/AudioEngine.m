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

@interface AudioEngine () {
    NSMutableDictionary<NSString*,AVAudioPlayerNode*> *_playerDictionary;
    NSMutableDictionary<NSString*,AVAudioPCMBuffer*>  *_bufferDictionary;

    bool _multichannelOutputEnabled;

    // mananging session and configuration changes
    BOOL _isSessionInterrupted;
    BOOL _isConfigChangePending;
}

@property(nonatomic, strong) AVAudioEngine *engine;
@property(nonatomic, strong) AVAudioEnvironmentNode *environment;

- (instancetype) init;

@end

@implementation AudioEngine

+ (AudioEngine*) main {
    static AudioEngine *mainEngine = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        void (^initEngine)() = ^{
            mainEngine = [[AudioEngine alloc] init];
        };

        // Avoid dead-locking and make sure we init AudioEngine on main thread.
        if( [NSThread mainThread] ) {
            initEngine();
        } else {
            dispatch_sync(dispatch_get_main_queue(), initEngine);
        }
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

        // Set up the audio category so we always hear the sound.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

        //create audio engine to play sounds
        _engine = [[AVAudioEngine alloc] init];
        _environment = [[AVAudioEnvironmentNode alloc] init];
        [_engine attachNode:_environment];

        [self makeEngineConnections];

        // Get notifications about changes in output configuration
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification
            object:_engine
            queue:nil
            usingBlock:^(NSNotification *note)
        {

            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            _isConfigChangePending = YES;

            if (!_isSessionInterrupted) {
                NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
                NSLog(@"Re-wiring connections and starting once again");
                [self makeEngineConnections];
                [self startEngine];
            }
            else {
                NSLog(@"Session is interrupted, deferring changes");
            }
        }];

        // Set up the environment with a bit of reverb.
        [_environment setVolume:1.0];
        [_environment setOutputVolume:1.0];
//        _environment.reverbParameters.enable = YES;
//        _environment.reverbParameters.level = -20;
//        [_environment.reverbParameters loadFactoryReverbPreset:AVAudioUnitReverbPresetMediumRoom];
//        [_environment setReverbBlend:0.2];

        [self startEngine];
    }
    return self;
}
/**
 * If we're connecting with a multichannel format, we need to pick a multichannel rendering algorithm
 */
- (AVAudio3DMixingRenderingAlgorithm) audioRenderingAlgo {
#ifdef USE_3DSPATIALIZED_AUDIO
    return _multichannelOutputEnabled ? AVAudio3DMixingRenderingAlgorithmSoundField : AVAudio3DMixingRenderingAlgorithmSphericalHead; //AVAudio3DMixingRenderingAlgorithmHRTF;
#else
    return _multichannelOutputEnabled ? AVAudio3DMixingRenderingAlgorithmSoundField : AVAudio3DMixingRenderingAlgorithmEqualPowerPanning;
#endif // USE_3DSPATIALIZED_AUDIO
}

- (void)makeEngineConnections
{
    [_engine connect:_environment to:_engine.outputNode format:[self constructOutputConnectionFormatForEnvironment]];

    // Set up the 3d audio environment
    AVAudio3DMixingRenderingAlgorithm renderingAlgo = self.audioRenderingAlgo;

    // Connect all of the players to the audio environment, and reset the rendering algorithm to match.
    for( NSString *playerName in _playerDictionary ) {
        AVAudioPlayerNode* player = _playerDictionary[playerName];
        AVAudioBuffer* buffer = _bufferDictionary[playerName];
        [_engine connect:player to:_environment format:buffer.format];
        player.renderingAlgorithm = renderingAlgo;
    }
}


- (void) startEngine {
    NSError *error;
    BOOL audioStartResult = [_engine startAndReturnError:&error];
    if (!audioStartResult) {
        NSLog(@"Audio Engine Start Error: %@", error.localizedDescription);
    }
}

- (AVAudioFormat *)constructOutputConnectionFormatForEnvironment
{
    AVAudioFormat *environmentOutputConnectionFormat = nil;
    AVAudioChannelCount numHardwareOutputChannels = [_engine.outputNode outputFormatForBus:0].channelCount;
    const double hardwareSampleRate = [_engine.outputNode outputFormatForBus:0].sampleRate;

    // if we're connected to multichannel hardware, create a compatible multichannel format for the environment node
    if (numHardwareOutputChannels > 2 && numHardwareOutputChannels != 3) {
        if (numHardwareOutputChannels > 8) numHardwareOutputChannels = 8;

        // find an AudioChannelLayoutTag that the environment node knows how to render to
        // this is documented in AVAudioEnvironmentNode.h
        AudioChannelLayoutTag environmentOutputLayoutTag;
        switch (numHardwareOutputChannels) {
            case 4:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_4;
                break;

            case 5:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_5_0;
                break;

            case 6:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_6_0;
                break;

            case 7:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_7_0;
                break;

            case 8:
                environmentOutputLayoutTag = kAudioChannelLayoutTag_AudioUnit_8;
                break;

            default:
                // based on our logic, we shouldn't hit this case
                environmentOutputLayoutTag = kAudioChannelLayoutTag_Stereo;
                break;
        }

        // using that layout tag, now construct a format
        AVAudioChannelLayout *environmentOutputChannelLayout = [[AVAudioChannelLayout alloc] initWithLayoutTag:environmentOutputLayoutTag];
        environmentOutputConnectionFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:hardwareSampleRate channelLayout:environmentOutputChannelLayout];
        _multichannelOutputEnabled = true;
    }
    else {
        // stereo rendering format, this is the common case
        environmentOutputConnectionFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:hardwareSampleRate channels:2];
        _multichannelOutputEnabled = false;
    }

    return environmentOutputConnectionFormat;
}

#pragma mark - Buffer Management



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
- (AVAudioPlayerNode*) playerWithBuffer:(AVAudioPCMBuffer*)buffer named:(NSString*)named {
    AVAudioPlayerNode *player = _playerDictionary[named];
    if(player == nil) {
        player = [self createNewPlayer:buffer];

        // Add this to the player pool.
        _playerDictionary[named] = player;
    }

    return player;
}

- (AVAudioPlayerNode *)createNewPlayer:(AVAudioPCMBuffer *)buffer {
    //make a node for the sound
    AVAudioPlayerNode* player = [[AVAudioPlayerNode alloc] init];

    //attach the node to audio engine first
    [_engine attachNode:player];

    //assign format to node
    [_engine connect:player to:_environment format:[buffer format]];

    // Assign the current rendering algorithm of choice.
    player.renderingAlgorithm = self.audioRenderingAlgo;
    return player;
}


/**
 * Single shot audio playback at volume.
 */
- (void) playAudio:(NSString*)named atVolume:(float)volume {
    //occasionally, this can get called if the audio engine is not running.
    if (![_engine isRunning]){
        NSLog(@"AudioEngine: AudioEngine not running, could not play audio: %@", named);
        return;
    }

    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"AudioEngine: Could not play, missing audio: %@", named);
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
- (AudioNode*) loadAudioNamed:(NSString*)named allocateNew:(bool)allocateNew {

    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"AudioEngine: Could not load, missing audio: %@", named);
        return nil;
    }

    // Prep the player.
    AVAudioPlayerNode *player;
    if (allocateNew) {
        player = [self createNewPlayer:buffer];
    } else {
        player = [self playerWithBuffer:buffer named:named];
    }

    // Make a stand-alone AudioNode.
    AudioNode *audioNode = [[AudioNode alloc] initWithName:named buffer:buffer player:player];
    return audioNode;
}

/**
 * Load an audio file and return an audio node.
 */
- (AudioNode*) loadAudioNamed:(NSString*)named {
    return [self loadAudioNamed:named allocateNew:false];
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


#pragma mark - AVAudioSession

- (void)initAVAudioSession
{
    NSError *error;

    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];

    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);

    const NSInteger desiredNumChannels = 8; // for 7.1 rendering
    const NSInteger maxChannels = sessionInstance.maximumOutputNumberOfChannels;
    if (maxChannels >= desiredNumChannels) {
        success = [sessionInstance setPreferredOutputNumberOfChannels:desiredNumChannels error:&error];
        if (!success) NSLog(@"Error setting PreferredOuputNumberOfChannels! %@", [error localizedDescription]);
    }


    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];

    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:sessionInstance];

    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];

    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");

    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        _isSessionInterrupted = YES;

        //stop the playback of the nodes
        for( NSString *playerName in _playerDictionary ) {
            AVAudioPlayerNode* player = _playerDictionary[playerName];
            [player stop];
        }
    }

    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success)
            NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        else {
            _isSessionInterrupted = NO;
            if (_isConfigChangePending) {
                //there is a pending config changed notification
                NSLog(@"Responding to earlier engine config changed notification. Re-wiring connections and starting once again");
                [self makeEngineConnections];
                [self startEngine];

                _isConfigChangePending = NO;
            }
            else {
                // start the engine once again
                [self startEngine];
            }
        }
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];

    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@"     New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }

    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // if we've received this notification, the media server has been reset
    // re-wire all the connections and start the engine
    NSLog(@"Media services have been reset!");
    NSLog(@"Re-wiring connections and starting once again");

    [self initAVAudioSession];
    [self createEngineAndAttachNodes];
    [self makeEngineConnections];
    [self startEngine];
}

/**
 * Re-establish the audio engine and connections.
 */
- (void)createEngineAndAttachNodes
{
    _engine = [[AVAudioEngine alloc] init];
    [_engine attachNode:_environment];

    for( NSString *nodeName in _playerDictionary ) {
        AVAudioPlayerNode *playerNode = _playerDictionary[nodeName];
        [_engine attachNode:playerNode];
    }
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
        be_assert(buffer && player, "Null on buffer or player");
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

- (void) setPosition:(SCNVector3)position {
    _player.position = AVAudioMake3DPoint(position.x, position.y, position.z);
}

- (SCNVector3) position {
    AVAudio3DPoint p = _player.position;
    return SCNVector3Make(p.x, p.y, p.z);
}


- (void) play {
    if( _looping ) {
        [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferLoops|AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    } else {
        [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
    }
    [_player play];
//    NSLog(@"Playing %@ (%@)", _name, _player);
//    NSLog(@"%@", [AudioEngine main].engine);
}

- (void) stop {
    [_player stop];
}
@end
