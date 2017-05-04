/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#define NUM_POINTS_OF_INTEREST 12
#define ROBOT_ROTATION_TIME .25f
#define MIN_CAMERA_SPEED_THAT_WILL_TRIGGER_ATTENTION .01f

#define DUCKANDDANCE_HEIGHT_THREHSOLD 0.75
#define DUCKANDDANCE_COOLDOWN 30

#define ROBOT_FLYING_THRESHOLD -1

#import "RobotBehaviourComponent.h"
#import "BehaviourComponents/BehaviourComponent.h"
#import "BehaviourComponents/ExpressionBehaviourComponent.h"
#import "BehaviourComponents/LookAtBehaviourComponent.h"
#import "BehaviourComponents/LookAtNodeBehaviourComponent.h"
#import "BehaviourComponents/LookAtCameraBehaviourComponent.h"
#import "BehaviourComponents/MoveToBehaviourComponent.h"
#import "BehaviourComponents/PathFindMoveToBehaviourComponent.h"
#import "BehaviourComponents/ScanBehaviourComponent.h"

#import "../Utils/ComponentUtils.h"
#import "../Utils/Math.h"
#import "../Core/AudioEngine.h"

#import "AnimationComponent.h"
#import "MoveRobotEventComponent.h"
#import "RobotBodyEmojiComponent.h"
#import "RobotMeshControllerComponent.h"
#import "RobotVemojiComponent.h"
#import "SpawnPortalComponent.h"

@import GLKit;

@interface RobotBehaviourComponent () {
    GLKVector3 _pointsOfInterest[NUM_POINTS_OF_INTEREST];
}

@property (weak) RobotMeshControllerComponent * meshControllerComponent;
@property (weak) GeometryComponent * geometryComponent;
@property (strong) NSMutableArray * behaviourComponents;

// points of interest
@property (atomic) int pointsOfInterestIndex;
@property (atomic) bool pointsOfInterestNewAdded;
@property(readonly) GLKVector3 *pointsOfInterest;

// idle behaviour
@property (atomic) float minCameraSpeedThatWillTriggerAttention;
@property (atomic) bool idle;
@property (atomic) bool runIdleLoop;
@property (atomic) bool cameraTriggerAttention;

// Easter-egg: when you couch down, Bridget looks at you and gives a little dance.
//@property (weak) AnimationComponent *animComponent;
@property(nonatomic) BOOL ducking;
@property(nonatomic) NSTimeInterval duckAndDanceCooldownTime;

@end


@implementation RobotBehaviourComponent

- (id) init {
    self = [super init];
    
    for( int i=0; i<NUM_POINTS_OF_INTEREST;i++) {
        self.pointsOfInterest[i] = GLKVector3Make(random11(), -random01(), random11());
    }
    self.pointsOfInterestIndex = 0;
    self.minCameraSpeedThatWillTriggerAttention = MIN_CAMERA_SPEED_THAT_WILL_TRIGGER_ATTENTION;
    
    self.idle = NO;
    self.runIdleLoop = YES;
    self.cameraTriggerAttention = YES;
    
    return self;
}

- (GLKVector3 *)pointsOfInterest
{
    return _pointsOfInterest;
}

- (void) start {
    self.meshControllerComponent = (RobotMeshControllerComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotMeshControllerComponent class]];
    self.behaviourComponents = [ComponentUtils getComponentsFromEntity:self.entity ofClass:[BehaviourComponent class]];
    
    [self stopAllBehaviours];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    
    self.idle = YES;
    for( BehaviourComponent * component in self.behaviourComponents ) {
        if( [component isRunning] && [component getIdleWeight] == 0.f ) {
            self.idle = NO;
            break;
        }
    }
    
    if( self.cameraTriggerAttention ) { // this could be a seperate behaviour component you could just enable or disable
        [self checkAttentionByCameraMovement];
    }
    
    if( self.runIdleLoop ) { // this could be a seperate behaviour component you could just enable or disable
        [self handleIdle:seconds];
    }
}

- (void) stopAllBehaviours {
    for( BehaviourComponent * component in self.behaviourComponents ) {
        
        if( [component isRunning] ) {
            [component stopRunning];
        }
    }
}

#pragma mark - Point of interest

- (void) addPointOfInterest:(GLKVector3)lookAtPosition {
    self.pointsOfInterestIndex ++;
    self.pointsOfInterestIndex %= NUM_POINTS_OF_INTEREST;
    
    self.pointsOfInterest[self.pointsOfInterestIndex] = lookAtPosition;
    self.pointsOfInterestNewAdded = YES;
    
    if( [self isIdle] ) {
        [self stopAllBehaviours];
    }
}

#pragma mark - AttentionByCameraMovement

- (void) cameraMovementTriggerAttention:(bool)triggerAttention {
    self.cameraTriggerAttention = triggerAttention;
}

- (void) checkAttentionByCameraMovement {
    for( BehaviourComponent * component in self.behaviourComponents ) {
        if( [component isRunning] && ![component allowCameraMovementTriggerAttention]) {
            return;
        }
    }
    
    if( [Camera main].speed > self.minCameraSpeedThatWillTriggerAttention ) {
        [self startLookAtMainCamera];
        
        self.minCameraSpeedThatWillTriggerAttention = MAX( [Camera main].speed, self.minCameraSpeedThatWillTriggerAttention)*3.f;
    }
}

#pragma mark - Idle


- (bool) isIdle {
    return self.idle;
}

- (void) runIdleBehaviours:(bool)runIdle {
    self.runIdleLoop = runIdle;
}


- (void) handleIdle:(NSTimeInterval)seconds {
    // Easter egg: User ducks & Bridget gets excited
    self.duckAndDanceCooldownTime -= seconds;
    GLKVector3 cameraPosition = [Camera main].position;
    GLKVector3 robotPos = [self.meshControllerComponent getPosition];
    if( cameraPosition.y > -DUCKANDDANCE_HEIGHT_THREHSOLD ) // Duck 
     {
        MoveRobotEventComponent *moveEventComponent = (MoveRobotEventComponent *)[self.entity componentForClass:MoveRobotEventComponent.class];
        SpawnPortalComponent *spawnPortalComponent = (SpawnPortalComponent*)[self.entity componentForClass:SpawnPortalComponent.class];
        BOOL canDance = [self isUnfolded] // Make sure Bridget isn't folded up still.
         && (robotPos.y >= ROBOT_FLYING_THRESHOLD) // Make sure Bridget is not flying in the air.
         && (self.isIdle || moveEventComponent.isEnabled || spawnPortalComponent.isEnabled);

        if( canDance && _duckAndDanceCooldownTime < 0 && _ducking == NO ) {
            NSLog(@"--==** Duck & Dance **==--");
            self.duckAndDanceCooldownTime = DUCKANDDANCE_COOLDOWN;
            LookAtCameraBehaviourComponent * lookAtCameraComponent = (LookAtCameraBehaviourComponent *)[self.entity componentForClass:[LookAtCameraBehaviourComponent class]];
            [self stopAllBehaviours];
            [lookAtCameraComponent runBehaviourFor:0.25 callback:^{
                [self beHappy];
            }];
        }
        
        self.ducking = YES;
    } else {
        self.ducking = NO;
    }

    // only start idle when _no_ behaviour is currently running
    for( BehaviourComponent * component in self.behaviourComponents ) {
        if( [component isRunning] ) {
            return;
        }
    }
    
    float attentionSpan = 2.f + 5.f*random01();
    
    // if a point of interest is added, look at this node
    if( self.pointsOfInterestNewAdded ) {
        
        self.pointsOfInterestNewAdded = NO;
        [self startLookAtPosition:self.pointsOfInterest[self.pointsOfInterestIndex]];
        
    } else {
        // find all possible idle behaviours, and choose one randomly based on idle weight
        float totalWeight = 0.f;
        
        for( BehaviourComponent * component in self.behaviourComponents ) {
            totalWeight += [component getIdleWeight];
        }
        
        float r = random01() *totalWeight;
        float currentWeight = 0.f;
        
        BehaviourComponent * idleComponent;
        for( idleComponent in self.behaviourComponents ) {
            currentWeight += [idleComponent getIdleWeight];
            if( currentWeight > r ) {
                break;
            }
        }
        
        // start idleComponent
        
        // handle special cases
        if( [idleComponent isKindOfClass:[LookAtCameraBehaviourComponent class]] ) {
            [idleComponent runBehaviourFor:attentionSpan callback:nil];
        }
        else if([idleComponent isKindOfClass:[ScanBehaviourComponent class]] ) {
            if(  self.navigationComponent ) {
                GLKVector3 target = [self.navigationComponent getRandomPoint:[self.meshControllerComponent getPosition] maxDistance:1.f minY:-2.f maxTry:20];
                if( target.y < 999.f ) {
                    [self startScan:target];
                }
            }else {
                self.pointsOfInterestIndex += (rand() % 3)-1 + NUM_POINTS_OF_INTEREST; // avoid index of -1
                self.pointsOfInterestIndex %= NUM_POINTS_OF_INTEREST;
                
                [self startScan:self.pointsOfInterest[self.pointsOfInterestIndex]];
            }
        } else if([idleComponent isKindOfClass:[MoveToBehaviourComponent class]] ) {
            GLKVector3 target = [self.navigationComponent getRandomPoint:[self.meshControllerComponent getPosition] maxDistance:1.f minY:-.65f maxTry:30];
            if( target.y < 999.f ) {
                [self startMoveTo:target];
            }
        } else {
            // get random target
            float t = random01();
            if( t <.5f ) {
                // - look at a point at interest based on the current point of interest (-1, 0, +1)
                
                self.pointsOfInterestIndex += (rand() % 3)-1 + NUM_POINTS_OF_INTEREST; // avoid index of -1
                self.pointsOfInterestIndex %= NUM_POINTS_OF_INTEREST;
            }
            else if( t < .75f ) {
                // - look at a random point of interest
                
                self.pointsOfInterestIndex = rand() %  NUM_POINTS_OF_INTEREST;
            }
            else  {
                // - add a new point of interest
                self.pointsOfInterestIndex = (self.pointsOfInterestIndex+1) %  NUM_POINTS_OF_INTEREST;
                self.pointsOfInterest[self.pointsOfInterestIndex] = GLKVector3Make(random11(), -random01(), random11());
            }
            
            [idleComponent runBehaviourFor:attentionSpan targetPosition:self.pointsOfInterest[self.pointsOfInterestIndex] callback:nil];
        }
    }
    
    self.minCameraSpeedThatWillTriggerAttention = MAX( MIN_CAMERA_SPEED_THAT_WILL_TRIGGER_ATTENTION,
                                                      self.minCameraSpeedThatWillTriggerAttention * .75f);
}

// start different behaviours - wrapper, you could also call the corresponding component direct

- (void) startScan:(GLKVector3)targetPosition {
    ScanBehaviourComponent * component = (ScanBehaviourComponent *)[self.entity componentForClass:[ScanBehaviourComponent class]];
    [component runBehaviourFor:2.f targetPosition:targetPosition callback:nil];
}

- (void) startMoveTo:(GLKVector3)targetPosition {
    PathFindMoveToBehaviourComponent *pathFindComponent = (PathFindMoveToBehaviourComponent *)[self.entity componentForClass:[PathFindMoveToBehaviourComponent class]];

    GLKVector3 robotPos = [self.meshControllerComponent getPosition];
    // if we're in the air, don't pathfind
    if(robotPos.y < ROBOT_FLYING_THRESHOLD)
    {
        // Initial start of movement, make sure the first location is reachable, and use it for our future reference point.
        if( [pathFindComponent occupied:targetPosition] == NO ) {
            pathFindComponent.reachableReferencePoint = targetPosition;
            [self.meshControllerComponent moveTo:targetPosition moveIn:1];
        } else {
            [self beSad];
        }
    }
    else
    {
        [pathFindComponent runBehaviourFor:999 targetPosition:targetPosition callback:^{
            [self startLookAtMainCamera];
        }];
    }
}



- (void) startLookAtNode:(SCNNode *)node {
    LookAtNodeBehaviourComponent * component = (LookAtNodeBehaviourComponent *)[self.entity componentForClass:[LookAtNodeBehaviourComponent class]];
    [component runBehaviourFor:(2.f+5.f*random01()) lookAtNode:node callback:nil];
}

- (void) startLookAtPosition:(GLKVector3)targetPosition {
    LookAtBehaviourComponent * component = (LookAtBehaviourComponent *)[self.entity componentForClass:[LookAtBehaviourComponent class]];
    [component runBehaviourFor:(2.f+5.f*random01()) targetPosition:targetPosition callback:nil];
}

- (void) startLookAtMainCamera {
    LookAtCameraBehaviourComponent * component = (LookAtCameraBehaviourComponent *)[self.entity componentForClass:[LookAtCameraBehaviourComponent class]];
    [component runBehaviourFor:(2.f+5.f*random01()) callback:nil];
}


#pragma mark - Mesh wrapper / methods

//- (void) lookAt:(GLKVector3)lookAtPosition rotateIn:(float)seconds {
//    [self.meshControllerComponent lookAt:lookAtPosition rotateIn:seconds];
//}

//- (void) lookAt:(GLKVector3)lookAtPosition {
//    [self.meshControllerComponent lookAt:lookAtPosition rotateIn:ROBOT_ROTATION_TIME];
//}

//- (void) moveTo:(GLKVector3)moveToTarget moveIn:(float)seconds {
//    [self.meshControllerComponent moveTo:moveToTarget moveIn:seconds];
//}

#pragma mark - Mesh wrapper / properties

- (BOOL) isUnfolded {
    return [self.meshControllerComponent robotBoxUnfolded];
}

- (GLKVector3) getPosition {
    return [self.meshControllerComponent getPosition];
}

- (GLKVector3) getBeamStartPosition {
    return SCNVector3ToGLKVector3( [self.meshControllerComponent.sensorCtrl convertPosition:SCNVector3Zero toNode:[Scene main].rootNode]);
}

- (GLKVector3) getEyePosition {
    return SCNVector3ToGLKVector3( [self.meshControllerComponent.headCtrl convertPosition:SCNVector3Zero toNode:[Scene main].rootNode]);
}

- (GLKVector3) getForward {
    return [self.meshControllerComponent getForward];
}

- (GLKVector3) getBodyPosition {
    return SCNVector3ToGLKVector3( [self.meshControllerComponent.bodyCtrl convertPosition:SCNVector3Zero toNode:[Scene main].rootNode]);
}


#pragma mark - Expressions

- (void) doDance {
    ExpressionBehaviourComponent *expressionComponent = (ExpressionBehaviourComponent *)[self.entity componentForClass:[ExpressionBehaviourComponent class]];
    [expressionComponent playExpression:EXPRESSION_KEY_DANCE];
}

- (void) beHappy {
    ExpressionBehaviourComponent *expressionComponent = (ExpressionBehaviourComponent *)[self.entity componentForClass:[ExpressionBehaviourComponent class]];
    [expressionComponent playExpression:EXPRESSION_KEY_HAPPY];
}

- (void) beSad {
    ExpressionBehaviourComponent *expressionComponent = (ExpressionBehaviourComponent *)[self.entity componentForClass:[ExpressionBehaviourComponent class]];
    [expressionComponent playExpression:EXPRESSION_KEY_SAD];
}

- (void) bePowerDown {
    ExpressionBehaviourComponent *expressionComponent = (ExpressionBehaviourComponent *)[self.entity componentForClass:[ExpressionBehaviourComponent class]];
    [expressionComponent playExpression:EXPRESSION_KEY_POWER_DOWN];
    
    RobotVemojiComponent *vemojiComponent = (RobotVemojiComponent*)[self.entity componentForClass:RobotVemojiComponent.class];
    vemojiComponent.idleName = @"Vemoji_LowPowerTransition16";
}

- (void) bePowerUp {
    RobotBodyEmojiComponent *bodyEmojiComponent = (RobotBodyEmojiComponent *)[self.entity componentForClass:[RobotBodyEmojiComponent class]];
    bodyEmojiComponent.batteryLevel = 4;
    
    ExpressionBehaviourComponent *expressionComponent = (ExpressionBehaviourComponent *)[self.entity componentForClass:[ExpressionBehaviourComponent class]];
    [expressionComponent playExpression:EXPRESSION_KEY_POWER_UP];

    RobotVemojiComponent *vemojiComponent = (RobotVemojiComponent*)[self.entity componentForClass:RobotVemojiComponent.class];
    vemojiComponent.idleName = @"Vemoji Smile";
}

#pragma mark - Robot Body Emoji

- (void) setBatteryLevel:(int)batteryLevel {
    RobotBodyEmojiComponent *component = (RobotBodyEmojiComponent *)[self.entity componentForClass:[RobotBodyEmojiComponent class]];
    component.batteryLevel = batteryLevel;
}

- (int) batteryLevel {
    RobotBodyEmojiComponent *component = (RobotBodyEmojiComponent *)[self.entity componentForClass:[RobotBodyEmojiComponent class]];
    return component.batteryLevel;
}

@end
