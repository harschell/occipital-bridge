/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "RobotActionComponent.h"

#import "AnimationComponent.h"
#import "RobotBodyEmojiComponent.h"
#import "RobotBehaviourComponent.h"
#import "RobotMeshControllerComponent.h"
#import "RobotSeesMeComponent.h"
#import "RobotVemojiComponent.h"
#import "../Utils/SceneKitExtensions.h"
#import "../Utils/ComponentUtils.h"
#import "../Utils/Math.h"
#import "../Core/AudioEngine.h"

#import "BehaviourComponents/BeamUIBehaviourComponent.h"
#import "BehaviourComponents/LookAtBehaviourComponent.h"
#import "BehaviourComponents/LookAtCameraBehaviourComponent.h"
#import "BehaviourComponents/LookAtNodeBehaviourComponent.h"
#import "BehaviourComponents/PathFindMoveToBehaviourComponent.h"

#define ROBOT_ACTION_BUFFER_KEY @"RobotActionBufferKey"

@interface RobotActionComponent ()

@property(nonatomic, weak) RobotBehaviourComponent *robotBehaviour;
@property (weak) GeometryComponent * geometryComponent;
@property (weak) AnimationComponent * animationComponent;
@property(nonatomic, strong) NSMutableArray *actionBuffer;
@end

@implementation RobotActionComponent
@synthesize vemojiIdle = _vemojiIdle;

- (void) start {
    [super start];

    self.robotBehaviour = (RobotBehaviourComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotBehaviourComponent class]];
    
    self.geometryComponent = (GeometryComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[GeometryComponent class]];

    self.animationComponent = (AnimationComponent *)[ComponentUtils getComponentFromEntity:self.entity ofClass:[AnimationComponent class]];

    self.actionBuffer = [[NSMutableArray alloc] initWithCapacity:8];
}

/**
 * Append the action to the buffer, and run the buffer if we're not already running.
 */
- (void) appendAction:(SCNAction*)action {
    [_actionBuffer addObject:action];

    if( [_geometryComponent.node actionForKey:ROBOT_ACTION_BUFFER_KEY] == nil ) {
        [self _runNextBufferedAction];
    }
}

/**
 * Remove the created action from buffer.
 */
- (void) removeAction:(SCNAction*)action {
    // Drop action from buffer.
    [_actionBuffer removeObject:action];
    
    // If action is currently running, kill it immediately.
    SCNAction *currentAction = [_geometryComponent.node actionForKey:ROBOT_ACTION_BUFFER_KEY];
    if( [currentAction isEqual:action] ) {
        [_geometryComponent.node removeActionForKey:ROBOT_ACTION_BUFFER_KEY];
    }
    
    // Meke sure running state of next action continues, or go idle.
    if( [_geometryComponent.node actionForKey:ROBOT_ACTION_BUFFER_KEY] == nil ) {
        if( _actionBuffer.count > 0 ) {
            [self _runNextBufferedAction];
        }
    }
}

/**
 * Reset all actions immediately, clearing any buffered actions.
 */
- (void) resetImmediately {
    [_actionBuffer removeAllObjects];
    [_geometryComponent.node removeActionForKey:ROBOT_ACTION_BUFFER_KEY];
    [_robotBehaviour stopAllBehaviours];
}

/**
 * Check if we're still playing actions in the buffer.
 */
- (BOOL) isPlayingActions {
    return [_geometryComponent.node actionForKey:ROBOT_ACTION_BUFFER_KEY] != nil;
}

// Internal: Run the next buffered action, regardless of current running state.
- (void) _runNextBufferedAction {
    SCNAction *nextAction = [_actionBuffer firstObject];
    if( nextAction ) {
        [_robotBehaviour runIdleBehaviours:NO];
        [_actionBuffer removeObjectAtIndex:0];
        

        [_geometryComponent.node runAction:nextAction forKey:ROBOT_ACTION_BUFFER_KEY completionHandler:^{
            [[SceneManager main].mixedRealityMode runBlockInRenderThread:^(void) {
                [self _runNextBufferedAction];
            }];
        }];
    }
}

/**
 * Check if robot can see the main camera.
 */
- (BOOL) canSeeMe {
    RobotSeesMeComponent *sees = (RobotSeesMeComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotSeesMeComponent class]];
    return sees.robotSeesMainCamera;
}

/**
 * Check if we are looking at the robot.
 */
- (BOOL) canSeeRobot {
    RobotSeesMeComponent *sees = (RobotSeesMeComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotSeesMeComponent class]];
    return sees.mainCameraSeesRobot;
}

/**
 * Check if robot has gone idle.
 */
- (BOOL) isIdle {
    return [_robotBehaviour isIdle];
}

/**
 * Get the robot's base node.
 */
- (SCNNode*) node {
    return _geometryComponent.node;
}

#pragma mark - Robot Control Actions

- (SCNAction*)reset {
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        [_robotBehaviour stopAllBehaviours];
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)wait:(NSTimeInterval)seconds {
    SCNAction *action = [SCNAction waitForDuration:seconds];
    [self appendAction:action];
    return action;
}

// Scan

- (SCNAction*)scanX:(float)x Y:(float)y Z:(float)z Radius:(float)radius {
    SCNAction *wait = [SCNAction waitForDuration:1.5]; // Default to 1.5sec, FIXME: pickup the duration from the Scan action block.
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
//        ScanBehaviourComponent *scanBehaviour = (ScanBehaviourComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[ScanBehaviourComponent class]];
//        [scanBehaviour runBehaviourFor:1.5 targetPosition:(GLKVector3){x,y,z} radius:radius callback:nil];
        
        // Adjust the wait action duration to the scan interval.
//        wait.duration = scanBehaviour.intervalTime;
    }];
    
    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    [self appendAction:combined];
    return combined;
}

// Move

- (SCNAction*)moveToX:(float)x Y:(float)y Z:(float)z {
    SCNAction *wait = [SCNAction waitForDuration:0];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        PathFindMoveToBehaviourComponent *component = (PathFindMoveToBehaviourComponent *)[self.entity componentForClass:[PathFindMoveToBehaviourComponent class]];

        [component runBehaviourFor:0 targetPosition:(GLKVector3){x,y,z} callback:^{
            wait.duration = component.timer;
        }];
        float duration = [component durationToTarget:(GLKVector3){x,y,z}];
        wait.duration = duration+1;
    }];

    [self appendAction:action];
    [self appendAction:wait]; // NOTE: Cannot combine with SCNAction sequence, and adjust the wait duration after the fact, without also adjusting the parent action duration.
    return action;
}

- (SCNAction*)moveTo:(SCNVector3)targetPosition {
    return [self moveToX:targetPosition.x Y:targetPosition.y Z:targetPosition.z];
}

- (SCNAction*)moveToNode:(SCNNode*)targetNode {
    SCNVector3 targetPosition = targetNode.position; // [targetNode convertPosition:targetNode.position toNode:nil];
    return [self moveToX:targetPosition.x Y:targetPosition.y Z:targetPosition.z];
}

// Look

- (SCNAction*)lookAtX:(float)x Y:(float)y Z:(float)z {
    CFTimeInterval duration = (0.5f+1.f*random01());
    SCNAction *wait = [SCNAction waitForDuration:duration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        LookAtBehaviourComponent * component = (LookAtBehaviourComponent *)[self.entity componentForClass:[LookAtBehaviourComponent class]];
        [component runBehaviourFor:duration targetPosition:(GLKVector3){x,y,z} callback:nil];
    }];

    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    [self appendAction:combined];
    return combined;
}

- (SCNAction*)lookAtX:(float)x Y:(float)y Z:(float)z Duration:(CFTimeInterval)duration {
    SCNAction *wait = [SCNAction waitForDuration:duration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        LookAtBehaviourComponent * component = (LookAtBehaviourComponent *)[self.entity componentForClass:[LookAtBehaviourComponent class]];
        [component runBehaviourFor:duration targetPosition:(GLKVector3){x,y,z} callback:nil];
    }];

    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    [self appendAction:combined];
    return combined;
}

- (SCNAction*)lookAtPoint:(SCNVector3)lookAtPosition {
    return [self lookAtX:lookAtPosition.x Y:lookAtPosition.y Z:lookAtPosition.z];
}

- (SCNAction*)lookAtNode:(SCNNode *)node {
    CFTimeInterval duration = (0.5f+1.f*random01());
    SCNAction *wait = [SCNAction waitForDuration:duration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        LookAtNodeBehaviourComponent * component = (LookAtNodeBehaviourComponent *)[self.entity componentForClass:[LookAtNodeBehaviourComponent class]];
        [component runBehaviourFor:duration lookAtNode:node callback:nil];
    }];

    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    [self appendAction:combined];
    return combined;
}

- (SCNAction*)lookAtMainCamera {
    CFTimeInterval duration = (0.5f+1.f*random01());
    SCNAction *wait = [SCNAction waitForDuration:duration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        LookAtCameraBehaviourComponent * component = (LookAtCameraBehaviourComponent *)[self.entity componentForClass:[LookAtCameraBehaviourComponent class]];
        [component runBehaviourFor:duration callback:nil];
    }];
    
    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    [self appendAction:combined];
    return combined;
}

- (void) lookAtMainCameraWithDuration:(CFTimeInterval)duration {
    SCNAction *wait = [SCNAction waitForDuration:duration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        LookAtCameraBehaviourComponent * component = (LookAtCameraBehaviourComponent *)[self.entity componentForClass:[LookAtCameraBehaviourComponent class]];
        [component runBehaviourFor:duration callback:nil];
    }];
    
    [self appendAction:action];
    [self appendAction:wait];
}


- (SCNAction*)playAnimation:(CAAnimation*)animation {
    // Find an appropriate duration for animation playback.
    CFTimeInterval duration;
    if( animation.repeatDuration ) {
        duration = animation.repeatDuration;
    } else if( animation.repeatCount > 0 & animation.repeatCount < HUGE_VALF ) {
        duration = animation.duration * animation.repeatCount;
    } else {
        duration = animation.duration;
    }
    
    SCNAction *wait = [SCNAction waitForDuration:duration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        // R: I think we should add an animation behaviour component for this
        // AH: Agreed, we should refactor AnimationComponent into a new BehaviourAnimationComponent
        [_animationComponent addAnimation:animation forKey:@"RobotAction.playAnimation"];
    }];

    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    
    [self appendAction:combined];
    return combined;
}

- (SCNAction*)playAnimationNoWait:(CAAnimation*)animation {
    // Find an appropriate duration for animation playback.
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        // R: I think we should add an animation behaviour component for this
        // AH: Agreed, we should refactor AnimationComponent into a new BehaviourAnimationComponent
        [_animationComponent addAnimation:animation forKey:@"RobotAction.playAnimation"];
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)stopAnimation {
    CFTimeInterval fadeDuration = 0.2;
    SCNAction *wait = [SCNAction waitForDuration:fadeDuration];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        // I think we should add an animation behaviour component for this
        [_animationComponent removeAnimationForKey:@"RobotAction.playAnimation" fadeOutDuration:fadeDuration];
    }];
    
    SCNAction *combined = [SCNAction sequence:@[action,wait]];
    [self appendAction:combined];
    return combined;
}

- (SCNAction*)playAudio:(AudioNode*)audioNode waitForCompletion:(BOOL)wait {
//    SCNAction *action = [SCNAction playAudioSource:audioSource waitForCompletion:wait];
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        [audioNode play];
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)setMovementAudio:(AudioNode*)audioNode {
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotMeshControllerComponent *component = (RobotMeshControllerComponent *)[self.entity componentForClass:[RobotMeshControllerComponent class]];
        component.movementAudio = audioNode;
    }];
    
    [self appendAction:action];
    return action;
}
 
/**
 * Switch which world the robot is rendered in for the portal traverse.
 * @param arWorld true will render in the AR world
 * @param vrWorld true will render in the VR world.
 */
- (SCNAction*)renderInWorldsAR:(BOOL)arWorld VR:(BOOL)vrWorld {
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotMeshControllerComponent * geometry = (RobotMeshControllerComponent *)[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotMeshControllerComponent class]];
        [geometry.node setRenderingOrderRecursively:(vrWorld ? VR_WORLD_RENDERING_ORDER:0)];
    }];

    [self appendAction:action];
    return action;
}

- (SCNAction*)activateBeamUI {
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        BeamUIBehaviourComponent *component = (BeamUIBehaviourComponent *)[self.entity componentForClass:[BeamUIBehaviourComponent class]];
        [component runBehaviourFor:0.f callback:nil];
    }];

    [self appendAction:action];
    return action;
}


- (SCNAction*) idleBehaviours:(BOOL)enabled {
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        [_robotBehaviour runIdleBehaviours:enabled];
        [_robotBehaviour cameraMovementTriggerAttention:enabled];
    }];

    [self appendAction:action];
    return action;
}

- (void) setVemojiIdle:(NSString *)vemojiIdle {
    RobotActionComponent* __weak weakSelf = self;
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotActionComponent* strongSelf = weakSelf;
        if( strongSelf ) {
            RobotVemojiComponent *component = (RobotVemojiComponent *)[strongSelf.entity componentForClass:[RobotVemojiComponent class]];
            component.idleName = vemojiIdle;
        }
    }];

    [self appendAction:action];
}

- (SCNAction*)setVemoji:(NSString*)headVemoji withDuration:(float)duration {
    RobotActionComponent* __weak weakSelf = self;
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotActionComponent* strongSelf = weakSelf;
        if( strongSelf ) {
            RobotVemojiComponent *component = (RobotVemojiComponent *)[strongSelf.entity componentForClass:[RobotVemojiComponent class]];
            [component setExpression:headVemoji withDuration:duration];
        }
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)playVemojiSequence:(NSString*)baseName start:(int)start end:(int)end digits:(int)digits {
    RobotActionComponent* __weak weakSelf = self;
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotActionComponent* strongSelf = weakSelf;
        if( strongSelf ) {
            RobotVemojiComponent *component = (RobotVemojiComponent *)[strongSelf.entity componentForClass:[RobotVemojiComponent class]];
            NSArray<NSString*>* seq = [RobotVemojiComponent nameArrayBase:baseName start:start end:end digits:digits];
//            NSLog(@"Playing a vemoji sequence: %@", seq);
            [component setExpressionSequence:seq];
        }
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)setBodyEmoji:(NSString*)bodyEmoji {
    RobotActionComponent* __weak weakSelf = self;
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotActionComponent* strongSelf = weakSelf;
        if( strongSelf ) {
            RobotMeshControllerComponent *component = (RobotMeshControllerComponent *)[strongSelf.entity componentForClass:[RobotMeshControllerComponent class]];
            [component setBodyEmojiDiffuse:bodyEmoji];
        }
    }];
    
    [self appendAction:action];
    return action;
}

/**
 * Sets the body emoji to reflect its battery level
 */
- (SCNAction*)setBatteryLevel:(int)level {
    RobotActionComponent* __weak weakSelf = self;
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotActionComponent* strongSelf = weakSelf;
        if( strongSelf ) {
            RobotBodyEmojiComponent *component = (RobotBodyEmojiComponent *)[strongSelf.entity componentForClass:[RobotBodyEmojiComponent class]];
//            NSLog(@"Battery level: %d", level);
            [component setBatteryLevel:level];
        }
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)playBodyEmojiSequence:(NSString*)baseName start:(int)start end:(int)end digits:(int)digits {
    RobotActionComponent* __weak weakSelf = self;
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        RobotActionComponent* strongSelf = weakSelf;
        if( strongSelf ) {
            RobotBodyEmojiComponent *component = (RobotBodyEmojiComponent *)[strongSelf.entity componentForClass:[RobotBodyEmojiComponent class]];
            NSArray<NSString*>* seq = [RobotBodyEmojiComponent nameArrayBase:baseName start:start end:end digits:digits];
//            NSLog(@"Playing a vemoji sequence: %@", seq);
            [component setExpressionSequence:seq];
        }
    }];
    
    [self appendAction:action];
    return action;
}



- (SCNAction*)jsCallback:(JSValue*)function {
    SCNAction *action = [SCNAction runBlock:^(SCNNode * _Nonnull node) {
        [function callWithArguments:nil];
    }];
    
    [self appendAction:action];
    return action;
}

- (SCNAction*)jsAsyncCallback:(JSValue*)function withDuration:(NSTimeInterval)duration {
    SCNAction *action = [SCNAction customActionWithDuration:duration
                                                actionBlock:^(SCNNode * _Nonnull node, CGFloat elapsedTime)
    {
        [function callWithArguments:@[@(elapsedTime)]];
    }];
    
    [self appendAction:action];
    return action;
}


@end
