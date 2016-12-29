/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "FetchEventComponent.h"
#import "AnimationComponent.h"
#import "BeamComponent.h"
#import "BehaviourComponents/BeamUIBehaviourComponent.h"
#import "BehaviourComponents/LookAtNodeBehaviourComponent.h"
#import "BehaviourComponents/LookAtCameraBehaviourComponent.h"
#import "BehaviourComponents/PathFindMoveToBehaviourComponent.h"
#import "BehaviourComponents/MoveToBehaviourComponent.h"
#import "Behaviourcomponents/LookAtBehaviourComponent.h"
#import "GazeComponent.h"
#import "RobotVemojiComponent.h"
#import "SelectableModelComponent.h"
#import "../Core/Core.h"
#import "../Core/AudioEngine.h"
#import "../Utils/Math.h"
#import "../Utils/SceneKitExtensions.h"
//#import "BESceneKitTools.h"

#define FETCH_IDLE_DISTANCE .75f
#define FETCH_IDLE_DISTANCE_OFF_CENTER .35f
#define FETCH_THROW_VELOCITY 5.f
#define FETCH_WAIT_FOR_FETCH_MIN_TIME 0.5f
#define FETCH_WAIT_FOR_FETCH_MAX_TIME 3.f
#define FETCH_BEAM_DISTANCE .35f
#define FETCH_MAX_DISTANCE_TO_CUBE 1.0

typedef NS_ENUM (NSUInteger, FetchEventState) {
    FETCH_THROW_START,
    FETCH_THROW,
    FETCH_FETCH,
    FETCH_FETCH_TURN_TO_CUBE,
    FETCH_FETCH_TURN_TO_CAMERA,
    FETCH_FETCH_BRINGBACK,
    FETCH_FETCH_BEAM_BACK,
    FETCH_BE_SAD,
    FETCH_POWER_LOW, // Bridget enters low power while moving towards you.
    FETCH_POWER_DIE, // Bridget's power is dead, and presents the plug, user taps plug to pickup
    FETCH_POWER_FIND, // User taps on outlet
    FETCH_POWER_PLACE_PLUG, // Plug flies to outlet, bridget navigates to outlet
    FETCH_POWER_GET, // Project beam from chest to plug.tail, begin powering up.
    FETCH_POWER_UP, // Plug snaps back into Bridget, faces camera, dances
    FETCH_POWER_UP_DONE, // Finished powering up, animate the plug back to chest.
    FETCH_POWER_DANCE, // Dance, then go fetch the ball.
    FETCH_IDLE
};

typedef NS_ENUM (NSUInteger, FetchPositionState) {
    FETCH_CENTER,
    FETCH_LEFT,
    FETCH_RIGHT
};


@interface FetchEventComponent()
@property (weak) BeamComponent * beamComponent;
@property (weak) LookAtNodeBehaviourComponent * lookAtNode;
@property (weak) LookAtCameraBehaviourComponent * lookAtCamera;
@property (weak) LookAtBehaviourComponent * lookAt;
@property (weak) PathFindMoveToBehaviourComponent * moveTo;
@property (weak) RobotVemojiComponent *vemojiComponent;

@property (atomic) FetchEventState fetchState;

@property (atomic) GLKVector3 rotation;
@property (atomic) bool rotationSet;


@property (atomic) float timer;
@property (atomic) float globalTimer;

@property (atomic) FetchPositionState idlePosition;

@property (strong) SCNNode * physicsCube;
@property (strong) SCNNode * representationCube;

//@property(strong) AudioNode *audioBallCarryLoop;
@property(nonatomic, strong) AudioNode *audioBallToss;
@property(nonatomic, strong) AudioNode *audioBallReturn;
@property(nonatomic, strong) AudioNode *audioBallPickup;
@property(nonatomic, strong) PhysicsContactAudio *bounce; //ball bouncing noise

@property(nonatomic, strong) NSArray *squeeOpenEyesVemojiSequence;

@property(nonatomic) BOOL happyOnSuccess; // One-shot flag for triggering the dance animation on successful path finding.

// Power-up sequence
@property(nonatomic) BOOL runLowPowerSequence;
@property(nonatomic, strong) SelectableModelComponent *plug;
@property(nonatomic, strong) AudioNode *audioPowerPlugConnect;
@property(nonatomic, strong) AudioNode *audioPowerPlugPickup;

// Moving parts
@property (atomic, strong) SCNNode * EndA_Ctrl;
@property (atomic, strong) SCNNode * EndB_Ctrl;
@property (atomic, strong) SCNNode * SideA_Ctrl;
@property (atomic, strong) SCNNode * SideB_Ctrl;
@property (atomic, strong) SCNNode * SideC_Ctrl;
@property (atomic, strong) SCNNode * SideD_Ctrl;
@end

@implementation FetchEventComponent

- (void) start {
    [super start];
    self.node = [self createSceneNode];
    
    self.physicsCube = [self createCube];
    self.representationCube = [self createCube];
    
    SCNPhysicsBody *cubeBody = [SCNPhysicsBody dynamicBody];
    [cubeBody setPhysicsShape:[SCNPhysicsShape shapeWithGeometry:[SCNSphere sphereWithRadius:0.11] options:nil]];
    cubeBody.mass = 1.0;
    cubeBody.restitution = 0.5;
    cubeBody.friction = 0.9;
    cubeBody.rollingFriction = 0.75;
    cubeBody.damping = 0.5;
    cubeBody.angularDamping = 0.50;
    cubeBody.allowsResting = YES;

    cubeBody.categoryBitMask = SCNPhysicsCollisionCategoryDefault;
    cubeBody.collisionBitMask = SCNPhysicsCollisionCategoryAll; // SCNPhysicsCollisionCategoryStatic | BECollisionCategoryRealWorld | BECollisionCategoryVirtualObjects;
    self.physicsCube.physicsBody = cubeBody;
    
    [self.node addChildNode:self.physicsCube];
    [self.node addChildNode:self.representationCube];
    
    [self.physicsCube setHidden:YES];
    
    self.idlePosition = FETCH_RIGHT;
    self.fetchState = FETCH_IDLE;
    
    self.rotationSet = NO;
    self.endExperience = NO;
    
    self.timer = 0.f;
    self.globalTimer = 0.f;
    
    // try to get components from robot
    self.beamComponent = (BeamComponent *)[self.robotBehaviourComponent.entity componentForClass:[BeamComponent class]];
    self.lookAtNode = (LookAtNodeBehaviourComponent *)[self.robotBehaviourComponent.entity componentForClass:[LookAtNodeBehaviourComponent class]];
    self.moveTo = (PathFindMoveToBehaviourComponent *)[self.robotBehaviourComponent.entity componentForClass:[PathFindMoveToBehaviourComponent class]];
    self.lookAtCamera = (LookAtCameraBehaviourComponent *)[self.robotBehaviourComponent.entity componentForClass:[LookAtCameraBehaviourComponent class]];
    self.lookAt = (LookAtBehaviourComponent *)[self.robotBehaviourComponent.entity componentForClass:[LookAtBehaviourComponent class]];
    self.vemojiComponent = (RobotVemojiComponent *)[self.robotBehaviourComponent.entity componentForClass:[RobotVemojiComponent class]];

    self.audioBallToss = [[AudioEngine main] loadAudioNamed:@"BallToss.caf"];
    self.audioBallPickup = [[AudioEngine main] loadAudioNamed:@"BallPickup.caf"];
    self.audioBallReturn = [[AudioEngine main] loadAudioNamed:@"BallReturn.caf"];
    self.bounce = [_physicsContactAudio addNodeName:@"ball" audioName:@"BallBounce.caf"];
    
    self.squeeOpenEyesVemojiSequence = [RobotVemojiComponent nameArrayBase:@"Vemoji_Squee_OpenEyes" start:1 end:8 digits:1];
    self.squeeOpenEyesVemojiSequence = [_squeeOpenEyesVemojiSequence arrayByAddingObjectsFromArray:_squeeOpenEyesVemojiSequence]; // Double the animation.
    self.squeeOpenEyesVemojiSequence = [_squeeOpenEyesVemojiSequence arrayByAddingObjectsFromArray:_squeeOpenEyesVemojiSequence]; // Tripple the animation.

}

- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    if( self.fetchState == FETCH_IDLE ) {
        [self throw];
    }
    
    if( self.fetchState == FETCH_BE_SAD ) {
        [self resetBeSad];
    }
    
    return NO;
}

- (bool) touchCanceledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit {
    return NO;
}

- (void) setPause:(bool)pausing {
    if( pausing ) {
        [self setEnabled:false];
    }
}

- (bool) handleRotation:(GLKVector3)rotation {
    self.rotation = rotation;
    self.rotationSet = YES;
    return YES;
}

- (void) switchToPhysicsCube {
    [self.physicsCube setHidden:NO];
    [self.representationCube setHidden:YES];
    
    self.physicsCube.position = self.representationCube.position;
    self.physicsCube.orientation = self.representationCube.orientation;

    self.physicsCube.physicsBody.velocity = SCNVector3Zero;
    self.physicsCube.physicsBody.angularVelocity = SCNVector4Zero;
    
    [self.physicsCube.physicsBody clearAllForces];
    [self.physicsCube.physicsBody resetTransform];
}

- (void) switchToRepresentationCubeWithPhysicsFrame:(BOOL)usePhysicsFrame {
    [self.physicsCube setHidden:YES];
    [self.representationCube setHidden:NO];
    
    if( usePhysicsFrame ) {
        self.representationCube.position = self.physicsCube.presentationNode.position;
        self.representationCube.orientation = self.physicsCube.presentationNode.orientation;
    }
}

#pragma mark - Update Loop

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    
    self.timer += seconds;
    self.globalTimer += seconds;
    
//    [self updatePhysics:seconds];
    
    if( self.fetchState == FETCH_THROW_START ) {
        [self switchToPhysicsCube];
        
        GLKVector3 velocity = GLKVector3MultiplyScalar([Camera main].forward, FETCH_THROW_VELOCITY);
        velocity.y -= 1.5f;
        self.physicsCube.physicsBody.velocity = SCNVector3FromGLKVector3( velocity );
        self.physicsCube.physicsBody.angularVelocity = SCNVector4Make(10, 10, 10, random11()); // Spin the ball?
        self.fetchState = FETCH_THROW;
        self.timer = 0.f;
    }
    
    if( self.fetchState == FETCH_THROW ) {
        [self.lookAtNode runBehaviourFor:999.f lookAtNode:self.physicsCube callback:nil];
        
        if( (self.timer > FETCH_WAIT_FOR_FETCH_MIN_TIME && [self.physicsCube.physicsBody isResting]) || self.timer > FETCH_WAIT_FOR_FETCH_MAX_TIME ) {
            self.moveTo.stoppingDistance = 0.3;
            GLKVector3 target = SCNVector3ToGLKVector3(self.physicsCube.presentationNode.position);

            // Align the target height with the robot's current Y.
            target.y = [self.robotBehaviourComponent getPosition].y;
            
            [self.lookAt stopRunning];
            [self.lookAtNode stopRunning];
            [self.lookAtCamera stopRunning];

            [self.moveTo runBehaviourFor:999 targetPosition:target callback:nil];
            self.moveTo.showSadOnPathingFailure = NO;
            self.happyOnSuccess = YES; // prime the one-shot trigger.

            self.fetchState = FETCH_FETCH;
        }
    }
    
    if( self.fetchState == FETCH_FETCH ) {
        
        if( [self.moveTo isRunning] ) {
            // If we determine we succeded in pathfinding, then do a little happy expression.
            if( self.moveTo.pathFindingSucceded && self.happyOnSuccess ) {
                self.happyOnSuccess = NO; // clear the one-shot trigger.
                [self.robotBehaviourComponent beHappy];
            }
        } else {
            self.moveTo.stoppingDistance = 0.0;
            [self switchToRepresentationCubeWithPhysicsFrame:YES];
            
            self.timer = 0.f;
            
            [self.lookAt stopRunning];
            [self.lookAtNode stopRunning];
            [self.lookAtCamera stopRunning];
            
            self.fetchState = FETCH_FETCH_TURN_TO_CUBE;
        }
    }
    
    if( self.fetchState == FETCH_FETCH_TURN_TO_CUBE ) {
        [self.lookAtNode runBehaviourFor:999.f lookAtNode:self.physicsCube callback:nil];
        
        if( self.timer > .5 ) {
            self.timer = 0.f;
            
            [self.lookAtNode stopRunning];
            [self.lookAtCamera runBehaviourFor:1.f callback:nil];

            // Do reachability check, if we can reach with the beam then great.
            GLKVector3 beamStart = [_robotBehaviourComponent getBeamStartPosition];
            GLKVector3 ball = SCNVector3ToGLKVector3(self.physicsCube.presentationNode.position);
            float distToCube = GLKVector3Distance(beamStart, ball);
            
            if( distToCube >= FETCH_MAX_DISTANCE_TO_CUBE ) {
                NSLog(@"Distance to cube is too far. distance=%f", distToCube);
            }
            
            // Intersection check, from beam to ball.
            SCNNode *rootNode = [[Scene main] rootNode];
            NSArray<SCNHitTestResult *> *hitTestResults = [rootNode hitTestWithSegmentFromPoint:SCNVector3FromGLKVector3(beamStart)
                                                                    toPoint:SCNVector3FromGLKVector3(ball)
                                                                    options:nil];
            BOOL hitSomething = NO;
            for( SCNHitTestResult *result in hitTestResults ) {
                if( !(result.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) {
                    hitSomething = YES;
                    NSLog(@"%@ blocking our line of sight.", result.node.name);
                }
            }

            if( distToCube < _moveTo.stoppingDistance // If we're close enough, grab the ball anyway.
             || (distToCube < FETCH_MAX_DISTANCE_TO_CUBE && hitSomething == NO) ) {
                // Reachable. Great, keep going!
                [_audioBallPickup play];
                [self.vemojiComponent setIdleName:@"Vemoji_Squee_OpenEyes"];
                self.fetchState = FETCH_FETCH_TURN_TO_CAMERA;
            } else {
                [self beSad];  // Couldn't get to the cube, so fail out.
            }
        }
    }
    
    if( self.fetchState == FETCH_FETCH_TURN_TO_CAMERA ) {
        [self.beamComponent setEnabled:YES];
        
        GLKVector3 cubePosition = [self getMovingCubePosition];
        cubePosition = GLKVector3Lerp(SCNVector3ToGLKVector3(self.physicsCube.presentationNode.position), cubePosition, saturatef(self.timer * 2.f));
        
        self.representationCube.position = SCNVector3FromGLKVector3(cubePosition);
        
        self.beamComponent.startPos = [self.robotBehaviourComponent getBeamStartPosition];
        self.beamComponent.endPos = cubePosition;
        [self.beamComponent setActive:0.5f beamWidth:.1f beamHeight:.1f];
        
        if( self.timer > 1. ) {
            // Lose a power-bar
            if( self.endExperience && self.runLowPowerSequence && self.robotBehaviourComponent.batteryLevel >= 0 ) {
                self.robotBehaviourComponent.batteryLevel--;
            }
            
            // Chart a path back to camera.
            GLKVector3 forward = GLKVector3Make( [Camera main].forward.x, 0.f, [Camera main].forward.z );
            forward = GLKVector3Normalize(forward);
            
            forward = GLKVector3MultiplyScalar(forward, FETCH_IDLE_DISTANCE); // 1.5f*FETCH_IDLE_DISTANCE);  FIXME: Make a little closer to be more predictable.
            GLKVector3 target = GLKVector3Add(forward, [Camera main].position);
            
            target.y = [self.robotBehaviourComponent getPosition].y;
            
            [self.moveTo runBehaviourFor:999 targetPosition:target callback:nil];
            self.moveTo.showPathPlan = NO; // Don't show the path on return to camera.
            self.moveTo.showSadOnPathingFailure = NO;
            
            [self.vemojiComponent setExpressionSequence:_squeeOpenEyesVemojiSequence];

            self.fetchState = FETCH_FETCH_BRINGBACK;
        }
    }
    
    if( self.fetchState == FETCH_FETCH_BRINGBACK ) {
        
        GLKVector3 cubePosition = [self getMovingCubePosition];
        self.representationCube.position = SCNVector3FromGLKVector3(cubePosition);
        
        self.beamComponent.startPos = [self.robotBehaviourComponent getBeamStartPosition];
        self.beamComponent.endPos = cubePosition;
        
        if( ![self.moveTo isRunning] ) {
            if( [self.moveTo pathFindingSucceded] ) {
                self.timer = 0.f;
                self.fetchState = FETCH_FETCH_BEAM_BACK;
            } else {
                NSLog(@"Failed to find a path back.");
                [self beSad];
            }
        }
    }
    
    if( self.fetchState == FETCH_FETCH_BEAM_BACK ) {
        
        [self.lookAtNode runBehaviourFor:999.f lookAtNode:self.representationCube callback:nil];
        
        GLKVector3 cubePosition = [self getMovingCubePosition];
        
        float progress = self.timer;
        GLKVector3 target = [self getIdlePosition:self.idlePosition];
        
        cubePosition = GLKVector3Lerp(cubePosition, target, progress);
        
        self.representationCube.position = SCNVector3FromGLKVector3(cubePosition);
        
        self.beamComponent.startPos = [self.robotBehaviourComponent getBeamStartPosition];
        self.beamComponent.endPos = cubePosition;
        
        if( self.timer > 1.f) {
            [self.beamComponent setEnabled:NO];
            
            // move robot a little bit
            GLKVector3 target;
            if( self.idlePosition == FETCH_LEFT ) {
                target = [self getIdlePosition:FETCH_RIGHT];
            } else if( self.idlePosition == FETCH_RIGHT ) {
                target = [self getIdlePosition:FETCH_LEFT];
            } else{
                target = [self getIdlePosition:(FetchPositionState)(FETCH_LEFT + (rand() & 1))];
            }
            
            target.y = [self.robotBehaviourComponent getPosition].y;
            [self.moveTo runBehaviourFor:999 targetPosition:target callback:nil];
            self.moveTo.showPathPlan = NO; // Don't show the path plan on re-adustment.
            self.moveTo.showSadOnPathingFailure = NO; // Don't express sadness on pathing adjustment failure.

            self.fetchState = FETCH_IDLE;
        }
    }
    
    if( self.fetchState == FETCH_IDLE ) {
//        [self.vemojiComponent stopExpressionSequence];
        [self.vemojiComponent setIdleName:@"Vemoji Smile"];

        GLKVector3 position = [self getIdlePosition:self.idlePosition];
        self.representationCube.position = SCNVector3FromGLKVector3(position);
        [self.lookAtNode runBehaviourFor:999.f lookAtNode:self.representationCube callback:nil];
    }
    
    if( self.fetchState > FETCH_FETCH && self.rotationSet) {
        self.representationCube.eulerAngles = SCNVector3FromGLKVector3(self.rotation);
    }
}

- (SCNNode *) createCube {
    SCNNode *cube = [SCNNode firstNodeFromSceneNamed:@"Objects/SphereToy.dae"];
    cube.name = @"ball";
    cube.scale = SCNVector3Make(0.65, 0.65, 0.65);
    cube.categoryBitMask |= RAYCAST_IGNORE_BIT | CATEGORY_BIT_MASK_LIGHTING;
    return cube;
}

- (void) throw {
    self.fetchState = FETCH_THROW_START;
    [self.audioBallToss play];
    [self.beamComponent setEnabled:NO];
    [_bounce resetBounceCooloffTimer];
}

- (GLKVector3) getMovingCubePosition {
    GLKVector3 position;
    
    GLKVector3 forward = [self.robotBehaviourComponent getForward];
    forward = GLKVector3MultiplyScalar(forward, FETCH_BEAM_DISTANCE);
    
    position = GLKVector3Add([self.robotBehaviourComponent getEyePosition], forward);
    
    position.y += .05f*sinf( self.globalTimer * 3.f );
    
    return position;
}

- (GLKVector3) getIdlePosition:(FetchPositionState)alignment {
    GLKVector3 forward = [Camera main].forward;
    forward = GLKVector3Normalize(forward);
    
    GLKVector3 offset = GLKVector3MultiplyScalar(forward, FETCH_IDLE_DISTANCE_OFF_CENTER);
    forward = GLKVector3MultiplyScalar(forward, FETCH_IDLE_DISTANCE);
    
    if( alignment == FETCH_CENTER ) {
        offset = forward;
    } else  if( alignment == FETCH_LEFT ) {
        offset = GLKVector3Add(forward, GLKVector3Make(-offset.z, -offset.y, offset.x));
    } else {
        offset = GLKVector3Add(forward, GLKVector3Make(offset.z, -offset.y, -offset.x));
    }
    
    GLKVector3 target = GLKVector3Add([Camera main].position, offset);
    return target;
}

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    
    [self.robotBehaviourComponent runIdleBehaviours:!enabled];
    [self.robotBehaviourComponent cameraMovementTriggerAttention:!enabled];
    
    self.globalTimer = 0.f;
    
    [self.lookAtNode stopRunning];
    [self.moveTo stopRunning];

    self.moveTo.stoppingDistance = 0.0;

    if( !enabled ) {
        [self.beamComponent setEnabled:NO];
        
        // Reset to expression to regular smile.
        [self.vemojiComponent setIdleName:@"Vemoji Smile"];
    } else {
        [self switchToRepresentationCubeWithPhysicsFrame:NO];
        self.fetchState = FETCH_IDLE;
        [self.lookAtNode runBehaviourFor:999.f lookAtNode:self.representationCube callback:nil];
    }
}


// Do certain robot behaviours

/**
 * Robot expresses sadness.
 */
- (void) beSad {
    NSLog(@"Be Sad: failed in event state: %lu", self.fetchState);

    [self.lookAt stopRunning];
    [self.lookAtNode stopRunning];
    [self.lookAtCamera runBehaviourFor:1.f callback:nil];
    [self.robotBehaviourComponent beSad];

    self.timer = 0.f;
    self.fetchState=FETCH_BE_SAD;
}

/**
 * Reset the cube and get ready to throw again.
 */
- (void) resetBeSad {
    [self switchToRepresentationCubeWithPhysicsFrame:NO];
    [self.beamComponent setEnabled:NO];
    self.fetchState = FETCH_IDLE;
    [self.lookAtNode runBehaviourFor:999.f lookAtNode:self.representationCube callback:nil];
}

@end
