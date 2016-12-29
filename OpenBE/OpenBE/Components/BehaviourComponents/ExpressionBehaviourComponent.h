/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
//
//  Description:
//   Play a simultaneous set of animation, audio, and vemoji sequence
//   to express emotion on Bridget.

#import "BehaviourComponent.h"

// Built-in expressions loaded on startup
#define EXPRESSION_KEY_DANCE @"dance"
#define EXPRESSION_KEY_HAPPY @"happy"
#define EXPRESSION_KEY_SAD @"sad"
#define EXPRESSION_KEY_POWER_DOWN @"power down"
#define EXPRESSION_KEY_POWER_UP @"power up"

@interface ExpressionBehaviourComponent : BehaviourComponent
/**
 * Add an expression set for playback.
 *  Animation is applied with the AnimationComponent.
 *  Audio is played using the BEAudioEngine
 *  Vemoji sequences can be created using RobotVemojiComponent +nameArrayBase:start:end:digits:
 * @property expressionKey Name of the expression
 * @property animName (optional) name of the animation file to apply to Bridget model
 * @property audioName (optional) name of the audio file to play
 * @property vemojiSequence (optional) Image names to play in sequence at 10fps
 */
- (void) addExpression:(NSString*)expressionKey animation:(NSString*)animName audio:(NSString*)audioName vemojiSequence:(NSArray<NSString*>*)vemojiSequence;

/**
 * Play an expression that was previousely added.
 * @property expressionKey Name of the expression to play.
 */
- (void) playExpression:(NSString*)expressionKey;

@end
