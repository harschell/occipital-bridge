/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "RobotBodyEmojiComponent.h"
#import "RobotMeshControllerComponent.h"
#import "../Utils/ComponentUtils.h"

@interface RobotBodyEmojiComponent ()
@property(nonatomic,weak) RobotMeshControllerComponent *meshComponent;
@end

@implementation RobotBodyEmojiComponent

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
        self.idleName = @"Status Battery4.png";
        self.expressionFramerate = 2; // All the emoji animations are pretty slow.
    }
    return self;
}

- (void) setBatteryLevel:(int)level {
    _batteryLevel = level;
    if( (level >= 0) && (level <= 4) ) {
        self.idleName = [NSString stringWithFormat:@"Status Battery%d", level];
    } else {
        self.idleName = @"Status BatteryBlank";
    }
}

- (void) start {
    self.meshComponent = (RobotMeshControllerComponent *)[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotMeshControllerComponent class]];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    _time += seconds;
    
    [self updateExpression];
    [self updateExpressionSequence];

    // Composite of vemoji state.
    NSString *emoji = _idleName;

    if(_expression) {
        emoji = _expression;
    }

    // Final result, check if we need to change anything.
    if( [_meshComponent.bodyEmojiDiffuse isEqualToString:emoji] == NO ) {
        _meshComponent.bodyEmojiDiffuse = emoji;
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

@end
