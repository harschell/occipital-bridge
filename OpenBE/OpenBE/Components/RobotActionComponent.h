/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Core.h"
#import <SceneKit/SceneKit.h>
#import <AVFoundation/AVFoundation.h>
#import <JavascriptCore/JavascriptCore.h>

#import "../Core/AudioEngine.h"

// Make the RobotActionComponent JavaScriptable
@protocol RobotActionJSExports <JSExport>

/**
 * Reset all actions immediately, clearing any buffered actions.
 */
- (void) resetImmediately;

/**
 * Check if we're still playing actions in the buffer.
 */
- (BOOL) isPlayingActions;

/**
 * Check if robot can see the main camera.
 */
- (BOOL) canSeeMe;

/**
 * Check if we are looking at the robot.
 */
- (BOOL) canSeeRobot;

/**
 * Check if robot has gone idle.
 */
- (BOOL) isIdle;

/**
 * Get the robot's base node.
 */
- (SCNNode*) node;

// Robot callable actions that are automatically buffered and run in order.

/**
 * Stop all robot behaviours
 */
- (SCNAction*)reset;

/**
 * Wait for a duration in seconds
 */
- (SCNAction*)wait:(NSTimeInterval)seconds;

/**
 * Project a beam at the coordinate.
 */
- (SCNAction*)scanX:(float)x Y:(float)y Z:(float)z Radius:(float)radius;

/**
 * Move to the coordinate.
 */
- (SCNAction*)moveToX:(float)x Y:(float)y Z:(float)z;

/**
 * Move to the node's location (used with markupNode())
 */
- (SCNAction*)moveToNode:(SCNNode*)targetNode;

/**
 * Look at the coordinate.
 */
- (SCNAction*)lookAtX:(float)x Y:(float)y Z:(float)z;

/**
 * Look at the coordinate with duration.
 */
- (SCNAction*)lookAtX:(float)x Y:(float)y Z:(float)z Duration:(CFTimeInterval)duration;

/**
 * Look at the node's location (used with markupNode())
 */
- (SCNAction*)lookAtNode:(SCNNode *)node;

/**
 * Look at the user's camera location
 */
- (SCNAction*)lookAtMainCamera;

/**
 * Look at the user's camera location with specified duration.
 */
- (void) lookAtMainCameraWithDuration:(CFTimeInterval)duration;

/**
 * Play an animation (used with loadAnimation(name))
 */
- (SCNAction*)playAnimation:(CAAnimation*)animation;

/**
 * Play an animation without waiting for it to complete.
 */
- (SCNAction*)playAnimationNoWait:(CAAnimation*)animation;

/**
 * Stop any animation that's playing.
 */
- (SCNAction*)stopAnimation;

/**
 * Play an audio sample (used with loadAudio(name))
 */
JSExportAs(playAudio,
- (SCNAction*)playAudio:(AudioNode*)audioNode waitForCompletion:(BOOL)wait
);

/**
 * Set the looping movement audio.
 */
- (SCNAction*)setMovementAudio:(AudioNode*)audioNode;
 
/**
 * Switch which world the robot is rendered in for the portal traverse.
 * @param arWorld true will render in the AR world
 * @param vrWorld true will render in the VR world.
 */
- (SCNAction*)renderInWorldsAR:(BOOL)arWorld VR:(BOOL)vrWorld;

/**
 * Activate the interactive UI for doing a user action.
 */
- (SCNAction*)activateBeamUI;

/**
 * Enable/disable the robot's idle behaviour.
 */
- (SCNAction*)idleBehaviours:(BOOL)enabled;

/**
 * Return to vemoji to this idle state.
 */
@property(nonatomic, strong) NSString *vemojiIdle;

/**
 * Sets the Vemoji head diffuse material to image named for a duration in seconds.
 * setVemoji(name, duration)
 */
JSExportAs(setVemoji,
- (SCNAction*)setVemoji:(NSString*)headVemoji withDuration:(float)duration
);

JSExportAs(playVemojiSequence,
- (SCNAction*)playVemojiSequence:(NSString*)baseName start:(int)start end:(int)end digits:(int)digits
);

/**
 * Sets the body emoji diffuse material to image named
 */
- (SCNAction*)setBodyEmoji:(NSString*)bodyEmoji;

/**
 * Sets the body emoji to reflect its battery level
 */
- (SCNAction*)setBatteryLevel:(int)level;

JSExportAs(playBodyEmojiSequence,
- (SCNAction*)playBodyEmojiSequence:(NSString*)baseName start:(int)start end:(int)end digits:(int)digits
);

@end


@interface RobotActionComponent : Component
<
    ComponentProtocol,
    RobotActionJSExports
>

- (void) start;

/**
 * Append the action to the robot action buffer, and run the buffer if we're not already running.
 */
- (void) appendAction:(SCNAction*)action;

/**
 * Remove the created action from buffer.
 */
- (void) removeAction:(SCNAction*)action;

#pragma mark - Robot Immediate Methods

// See the @protocol RobotActionJSExports above.

///**
// * Reset all actions immediately, clearing any buffered actions.
// */
//- (void) resetImmediately;
//
///**
// * Check if we're still playing actions in the buffer.
// */
//- (BOOL) isPlayingActions;
//
///**
// * Check if robot can see the user.
// */
//- (BOOL) canSeeMe;
//
///**
// * Check if robot has gone idle.
// */
//- (BOOL) isIdle;


#pragma mark - Robot Control Actions

// Each Robot Control action is appended to the robot action buffer,
// so it runs the sequence of commands in the order they were called.

// See the @protocol RobotActionJSExports above.
 
//- (SCNAction*)reset;
//- (SCNAction*)wait:(NSTimeInterval)seconds;
//- (SCNAction*)scanX:(float)x Y:(float)y Z:(float)z Radius:(float)radius;
////- (SCNAction*)scan:(SCNVector3)targetPosition;
//- (SCNAction*)moveToX:(float)x Y:(float)y Z:(float)z;
//- (SCNAction*)moveTo:(SCNVector3)targetPosition;
//- (SCNAction*)moveToNode:(SCNNode*)targetNode;
//- (SCNAction*)lookAtX:(float)x Y:(float)y Z:(float)z;
//- (SCNAction*)lookAtPoint:(SCNVector3)lookAtPosition;
//- (SCNAction*)lookAtNode:(SCNNode *)node;
//- (SCNAction*)lookAtMainCamera;
//- (SCNAction*)playAnimation:(CAAnimation*)animation;
//- (SCNAction*)playAnimationNoWait:(CAAnimation*)animation;
//- (SCNAction*)stopAnimation;
////- (SCNAction*)playAudio:(SCNAudioSource*)audioSource waitForCompletion:(BOOL)wait;
//- (SCNAction*)playAudio:(RobotAudioNode*)audioNode waitForCompletion:(BOOL)wait;
//- (SCNAction*)setMovementAudio:(RobotAudioNode*)audioNode;
//- (SCNAction*)hide:(BOOL)enabled ;
//- (SCNAction*)renderInVRWorld:(BOOL)enabled;
//- (SCNAction*)activateBeamUI;
//- (SCNAction*)idleBehaviours:(BOOL)enabled;

//@property(nonatomic, strong) NSString *vemojiIdle;
//- (SCNAction*)setVemoji:(NSString*)headVemoji withDuration:(float)duration;
//
//- (SCNAction*)setBodyEmoji:(NSString*)bodyEmoji;


// Custom JS callbacks handled by the JavascriptComponent
/**
 * Action callback when this action is run.
 */
- (SCNAction*)jsCallback:(JSValue*)function;

/**
 * Async callback, runs repeatedly until the duration has elapsed.  (Does not wait for completion)
 */
- (SCNAction*)jsAsyncCallback:(JSValue*)function withDuration:(NSTimeInterval)duration;

@end
