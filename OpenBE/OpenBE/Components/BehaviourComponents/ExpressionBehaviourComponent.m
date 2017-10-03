/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ExpressionBehaviourComponent.h"
#import "../AnimationComponent.h"
#import "../RobotVemojiComponent.h"
#import "../RobotBodyEmojiComponent.h"
#import "../../Core/AudioEngine.h"

#define ANIMATION_KEY @"ExpressionBehaviourComponent"

@interface Expression : NSObject
@property(nonatomic, strong) CAAnimation *animation;
@property(nonatomic, strong) AudioNode *audio;
@property(nonatomic, strong) NSArray<NSString*> *vemojiSequence;
@property(nonatomic, strong) NSArray<NSString*> *bodyEmojiSequence;

/**
 * Calculate the max duration of this expression.
 */ 
- (float) duration;

@end

@implementation Expression

- (float) duration {
    float duration = 0;
    if( _animation ) {
        duration = MAX(duration, _animation.duration);
    }
    
    if( _audio ) {
        duration = MAX(duration, _audio.duration);
    }
    
    if( _vemojiSequence ) {
        float vemojiDuration = _vemojiSequence.count * 0.1; // FIXME: Assuming 10fps
        duration = MAX(duration, vemojiDuration);
    }

    if( _bodyEmojiSequence ) {
        float emojiDuration = _bodyEmojiSequence.count * 0.5; // FIXME: Assuming 2fps
        duration = MAX(duration, emojiDuration);
    }
    
    return duration;
}

@end

@interface ExpressionBehaviourComponent ()
@property(nonatomic, strong) NSMutableDictionary<NSString*, Expression*> *expressions;
@property(nonatomic, weak) AnimationComponent *animComponent;
@property(nonatomic, weak) RobotVemojiComponent *vemojiComponent;
@property(nonatomic, weak) RobotBodyEmojiComponent *bodyEmojiComponent;
@property(nonatomic, strong) AudioNode* lastAudio;
@end

@implementation ExpressionBehaviourComponent

- (id) initWithIdleWeight:(float)weight andAllowCameraMovementTriggerAttention:(bool)allowAttention {
    self = [super initWithIdleWeight:weight andAllowCameraMovementTriggerAttention:allowAttention];
    if (self) {
        _expressions = [NSMutableDictionary new];
    }
    return self;
}

- (void) addExpression:(NSString*)expressionKey animation:(NSString*)animName audio:(NSString*)audioName vemojiSequence:(NSArray<NSString*>*)vemojiSequence {
    [self addExpression:expressionKey animation:animName audio:audioName vemojiSequence:vemojiSequence bodyEmojiSequence:nil];
}

- (void) addExpression:(NSString*)expressionKey animation:(NSString*)animName audio:(NSString*)audioName vemojiSequence:(NSArray<NSString*>*)vemojiSequence bodyEmojiSequence:(NSArray<NSString*>*)bodyEmojiSequence {
    Expression *expr = [[Expression alloc] init];
    if( animName != nil ) {
        expr.animation = [_animComponent loadAnimationNamed:animName];
    }
    
    if( audioName != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            expr.audio = [[AudioEngine main] loadAudioNamed:audioName];
        });
    }
    
    expr.vemojiSequence = vemojiSequence;
    expr.bodyEmojiSequence = bodyEmojiSequence;
    
    _expressions[expressionKey] = expr;
}

- (void) playExpression:(NSString*)expressionKey {
    Expression *expr = _expressions[expressionKey];
    
    if( expr == nil ) {
        NSLog(@"Couldn't play, missing expression: %@", expressionKey);
        return;
    }
    
    [super runBehaviourFor:expr.duration callback:nil];

    if( expr.animation ) {
        [_animComponent addAnimation:expr.animation forKey:ANIMATION_KEY];
    }

    self.lastAudio = expr.audio;
    expr.audio.position = SCNVector3FromGLKVector3(self.meshController.getPosition); 
    [expr.audio play];
    
    if( expr.vemojiSequence ) {
        [_vemojiComponent setExpressionSequence:expr.vemojiSequence];
    }

    if( expr.bodyEmojiSequence ) {
        [_bodyEmojiComponent setExpressionSequence:expr.bodyEmojiSequence];
    }
}

#pragma mark - Behaviour

- (void) start {
    [super start];
    
    self.animComponent = (AnimationComponent *)[self.getRobot.entity componentForClass:[AnimationComponent class]];
    self.vemojiComponent = (RobotVemojiComponent *)[self.getRobot.entity componentForClass:[RobotVemojiComponent class]];
    self.bodyEmojiComponent = (RobotBodyEmojiComponent *)[self.getRobot.entity componentForClass:[RobotBodyEmojiComponent class]];

    // Dance Expression
    NSArray *squeeOpenEyesVemojiSequence = [RobotVemojiComponent nameArrayBase:@"Vemoji_Squee_OpenEyes" start:1 end:8 digits:1];
    squeeOpenEyesVemojiSequence = [squeeOpenEyesVemojiSequence arrayByAddingObjectsFromArray:squeeOpenEyesVemojiSequence]; // Double the animation.
    [self addExpression:EXPRESSION_KEY_DANCE animation:@"Robot_NonZeroed_Dance.dae" audio:@"Robot_Alright.caf" vemojiSequence:squeeOpenEyesVemojiSequence];

    // Happy Expression
    [self addExpression:EXPRESSION_KEY_HAPPY animation:nil audio:@"Robot_Alright.caf" vemojiSequence:squeeOpenEyesVemojiSequence];
    
    // Sad Expression
    NSArray *sadVemojiSequence = [RobotVemojiComponent nameArrayBase:@"Vemoji_Sad" start:1 end:16 digits:2];
    [self addExpression:EXPRESSION_KEY_SAD animation:nil audio:@"Robot_No.caf" vemojiSequence:sadVemojiSequence];
    
    
    // Low Power expression, from Javascript:
    //Anim.LowPower.repeatCount = 2;
    //robot.playAnimationNoWait(Anim.LowPower);
    //robot.playVemojiSequence("Vemoji_LowPowerTransition",1,16,2);
    //robot.vemojiIdle = "Vemoji_LowPowerTransition16";
    //
    //// Low Power.
    ////var lowAnimation = Anim.LowPower; // "Robot_NonZeroed_LowPowerIdle.dae"
    ////lowAnimation.repeatCount = 1;
    ////lowAnimation.speed = 1;
    //robot.setBatteryLevel(0);
    //robot.playBodyEmojiSequence("Status Low",0,7,1);
    
    NSArray *vemojiPowerDown = [RobotVemojiComponent nameArrayBase:@"Vemoji_LowPowerTransition" start:1 end:16 digits:2];
    NSArray *bodyEmojiPowerDown = [RobotBodyEmojiComponent nameArrayBase:@"Status Low" start:0 end:7 digits:1];
    [self addExpression:EXPRESSION_KEY_POWER_DOWN
        animation:nil // @"Robot_NonZeroed_LowPowerIdle.dae"
        audio:@"Robot_PowerDown.caf"
        vemojiSequence:vemojiPowerDown
        bodyEmojiSequence:bodyEmojiPowerDown];

    NSArray *vemojiPowerUp = [[vemojiPowerDown reverseObjectEnumerator] allObjects];
    NSArray *bodyEmojiPowerUp = [RobotBodyEmojiComponent nameArrayBase:@"Status Battery" start:0 end:4 digits:1];
    [self addExpression:EXPRESSION_KEY_POWER_UP
        animation:nil
        audio:@"PowerPlug_PowerUp.caf"
        vemojiSequence:vemojiPowerUp
        bodyEmojiSequence:bodyEmojiPowerUp];

}

- (void) stopRunning {
    [super stopRunning];
    [_animComponent removeAnimationForKey:ANIMATION_KEY];
    [_lastAudio stop];
    [_vemojiComponent stopExpressionSequence];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![self isRunning] ) return;
    
    [super updateWithDeltaTime:seconds];
    
    if( self.timer >= self.intervalTime ) {
        [self stopRunning];
    }
}

@end
