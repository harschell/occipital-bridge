/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "RobotVemojiComponent.h"
#import "RobotMeshControllerComponent.h"
#import "../Utils/ComponentUtils.h"
#import "../Utils/SceneKitExtensions.h"

#import <BridgeEngine/BEDebugging.h>

#define ROBOT_BLINK_EYES_CLOSED_DURATION 0.2f
#define ROBOT_BLINK_EYES_OPEN_BASE_DURATION 2.f
#define ROBOT_BLINK_EYES_OPEN_DURATION_RANGE 3.f

#define ROBOT_SWEEP_IDLE_DURATION 2.f

@interface RobotVemojiComponent ()
@property(nonatomic,weak) RobotMeshControllerComponent *meshComponent;
@property(nonatomic) BOOL sweep;
@property(nonatomic,strong) NSArray<NSString*> *sweepSequence;
@property(nonatomic) NSTimeInterval sweepTimeNext;
@end

@implementation RobotVemojiComponent

#pragma mark - Class Methods
+ (NSArray<NSString*>*) nameArrayBase:(NSString*)baseName start:(int)start end:(int)end digits:(int)digits {
    NSMutableArray<NSString*> *seq = [[NSMutableArray alloc] initWithCapacity:(end-start+1)];
    for( int i=start; i<=end; i++ ) {
        NSString *name = [NSString stringWithFormat:@"%@%0*d", baseName, digits, i];
        [seq addObject:name];
    }
    
    return [seq copy];
}

#pragma mark - Instance Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.idleName = @"Vemoji_Default.png";
        self.blinkName = @"Vemoji_Default_Blink.png";
        self.sweepSequence = [RobotVemojiComponent nameArrayBase:@"Vemoji_Sweep" start:1 end:16 digits:2];
        self.expressionFramerate = 10;        
    }
    return self;
}

- (void) start {
    self.meshComponent = (RobotMeshControllerComponent *)[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotMeshControllerComponent class]];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    _time += seconds;
    
    [self updateBlink];
    [self updateExpression];
    [self updateExpressionSequence];

    // Composite of vemoji state.
    NSString *vemoji = _idleName;

    if(_expression) {
        vemoji = _expression;
    }

    if(_blink) {
        vemoji = _blinkName;
    }
    
    [_meshComponent setHeadVemojiDiffuse:vemoji];
    [self updateSweep]; // Directly sets the headVemojiEmissive
}

- (void) updateBlink {
    if( _time > _blinkTimeNext ) {
        _blink = !_blink;
        if(_blink) {
            _blinkTimeNext = _time + ROBOT_BLINK_EYES_CLOSED_DURATION;
        } else {
            _blinkTimeNext = _time + ROBOT_BLINK_EYES_OPEN_BASE_DURATION + ROBOT_BLINK_EYES_OPEN_DURATION_RANGE * ((float)random()/(float)RAND_MAX);
        }
    }
}

/**
 * Set a temporary Vemoji with a specified expiry duration.
 */
- (void) setExpression:(NSString*)expression withDuration:(NSTimeInterval)duration {
    self.expression = expression;
    self.expressionExpiry = _time + duration;
}

- (void) updateExpression {
    if( _expression != nil && _time > _expressionExpiry ) {
        _expression = nil; // Terminate our expression after it expires.
    }
}

/**
 * Play a Vemoji sequence, with a built-in duration based on framerate.
 */
- (void) setExpressionSequence:(NSArray<NSString*> *)seq {
    _expressionStartTime = _time;
    _expressionSequence = [seq copy];
}

/**
 * Stop playback of the expression sequence.
 */
- (void) stopExpressionSequence {
    _expressionSequence = nil;
    _expression = nil;
}


- (void) updateExpressionSequence {
    if( _expressionSequence != nil ) {
        unsigned int index = (_time - _expressionStartTime) * _expressionFramerate;
        if( index < _expressionSequence.count ) {
            _expression = _expressionSequence[index];
            _expressionExpiry = (NSTimeInterval)(index + 1) * _expressionFramerate;
        } else {
            _expressionSequence = nil;
            _expression = nil;
        }
    }
}

/**
 * refresh the sweep display on the robot's emissive layer.
 */
- (void) updateSweep {
    NSTimeInterval fullSweepDuration = _sweepSequence.count / _expressionFramerate;
    if( _time > _sweepTimeNext ) {
        _sweep = !_sweep;
        if(_sweep) {
            _sweepTimeNext = _time + fullSweepDuration;
        } else {
            _sweepTimeNext = _time + ROBOT_SWEEP_IDLE_DURATION;
        }
    }

    if(_sweep) {
        // Sweep index.
        NSTimeInterval sweepTime = _time - (_sweepTimeNext - fullSweepDuration);
        unsigned index = (unsigned int)(sweepTime * _expressionFramerate) % _sweepSequence.count;
        
        NSString *sweepImage = _sweepSequence[index];
        if( [_meshComponent.headVemojiEmissive isEqualToString:sweepImage] == NO ) {
            _meshComponent.headVemojiEmissive = sweepImage;
        }
    }
}

@end
