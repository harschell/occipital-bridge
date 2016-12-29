/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Core.h"


/**
 * Control the Robot's body emoji expression behaviour.
 */
@interface RobotBodyEmojiComponent : Component
@property(nonatomic) NSTimeInterval time;

/**
 * Show this battery level when idle.
 * 0 is empty to 4 is full
 * -1 or outside of range, shows blank battery status.
 */
@property(nonatomic) int batteryLevel;

// Return to this idle state emoji.
@property(nonatomic, copy) NSString *idleName;

// Current emoji expression, until it expires, then it returns to nil.
@property(nonatomic, copy) NSString *expression;
@property(nonatomic) NSTimeInterval expressionExpiry;

/**
 * Set a Vemoji with a specified expiry duration, then returns to idle.
 */
- (void) setExpression:(NSString*)expression withDuration:(NSTimeInterval)duration;

/**
 * Play a Vemoji sequence, with a built-in duration based on framerate.
 * Resets to nil on completion.
 */
@property(nonatomic, copy) NSArray<NSString*> *expressionSequence;

/**
 * Expression framerate in frames per second.
 */
@property(nonatomic) NSTimeInterval expressionFramerate;
@property(nonatomic) NSTimeInterval expressionStartTime;

/**
 * Play a Vemoji sequence, with a built-in duration based on framerate.
 */
- (void) setExpressionSequence:(NSArray<NSString*> *)seq;


/**
 * Generate name sequence, such as ["Name01", "Name02", "Name03"]
 * @param baseName prefix to the name ex: "Name" for the above example
 * @param start starting index, can start at 1.
 * @param end ending index, inclusive. So 3 would give the above array.
 * @param digits Number of digits, with 0 prefix-padding, 2 digits will give "01" for the value 1.
 */
+ (NSArray<NSString*>*) nameArrayBase:(NSString*)baseName start:(int)start end:(int)end digits:(int)digits;

@end
