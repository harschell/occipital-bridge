/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "RobotMeshControllerComponent.h"
#import "../Utils/ComponentUtils.h"
#import "../Utils/Math.h"
#import "../Utils/SceneKitExtensions.h"
#import "AnimationComponent.h"
#import "MoveRobotEventComponent.h"
#import "SelectableModelComponent.h"
#import "RobotActionComponent.h"

#import <GLKit/GLKit.h>
#import "../Utils/SceneKitTools.h"
#import "../Utils/SceneKitExtensions.h"

#import "../Core/AudioEngine.h"

#import <BridgeEngine/BEDebugging.h>

#define ROBOT_HOVER_HEIGHT 0.5f
#define ROBOT_LOOK_AT_MIN_DISTANCE .2f
#define ROBOT_LOOK_X_ROTATION_LIMIT (M_PI_2-0.01)
#define ROBOT_LOOK_Y_ROTATION_LIMIT (M_PI_4-0.01)

#define ROBOT_HEAD_ROTATION_RATE_LIMIT (4*M_PI) // 360°/sec rotation rate limit.

#define ROBOT_BODY_TARGETTING_LIMIT (M_PI/6.f)  // 30 degree threshold
#define ROBOT_BODY_TARGETTING_INTERVAL .5f
#define ROBOT_BODY_ROTATION_RATE_LIMIT (1.5*M_PI) // 360°/sec rotation rate limit.

#define ROBOT_BOX_ANIMATION_KEY @"RobotMeshControllerComponent.Box"

@interface RobotMeshControllerComponent ()

@property (nonatomic) float time;

@property (nonatomic) GLKVector3 targetLookAtPosition;

@property (nonatomic) float lookAtTimer;
@property (nonatomic) float lookAtTimeInterval;

@property (nonatomic) float startHeadRotationX;
@property (nonatomic) float startHeadRotationY;

@property (nonatomic) float targetHeadRotationX;
@property (nonatomic) float targetHeadRotationY;

@property (nonatomic) float headRotationX;
@property (nonatomic) float headRotationY;

@property (nonatomic) float bodyTargettingTimer;
@property (nonatomic) float bodyTargettingTimeInterval;
@property (nonatomic) float startBodyRotationY;
@property (nonatomic) float bodyTargetRotationY;
@property (nonatomic) float bodyRotationY;

@property (nonatomic) float moveToTimer;
@property (nonatomic) float moveToTimeInterval;
@property (nonatomic) GLKVector3 moveToTarget;
@property (nonatomic) GLKVector3 moveToStart;

@property (nonatomic) float currentY;

@property (nonatomic, strong) SCNNode * robotTransformNode;
@property (nonatomic, strong) SCNNode * robotBodyNode;
@property (nonatomic, strong) SCNNode * animatedHeadCtrl;

@property (nonatomic, strong) SCNNode * robotChestCtrl;

// Robot Box node for unfolding animation.
@property (nonatomic) BOOL startWithUnboxingSequence; // Set if we want to do the unboxing opening sequence.

@property (nonatomic, strong) SelectableModelComponent *robotBoxSelectable;
@property (nonatomic) CGFloat robotBoxRadius;

@property (nonatomic, strong) SCNNode *robotBoxNode;
@property (nonatomic, strong) SCNNode *robotBoxRootCtrl;
@property (nonatomic, strong) CAAnimation *robotBoxUnfoldingAnim;
@property (nonatomic, strong) AudioNode *robotBoxUnfoldingSound;

@end


@implementation RobotMeshControllerComponent
{
    NSString* _vemojiFolderPath;
}

@synthesize robotBoxUnfolded = _robotBoxUnfolded;

- (instancetype) initWithUnboxingExperience:(BOOL)unboxingExperience {
    self = [super init];
    if( self ) {
        self.node = [self createSceneNodeForGaze];
        self = [super initWithNode:self.node];
        
        self.scale = .25f;
        self.startHeadRotationX = self.targetHeadRotationX = 0.f;
        self.startHeadRotationY = self.targetHeadRotationY = 0.f;
        
        self.moveToTimer = self.moveToTimeInterval = 0.f;
        
        self.currentY = 0.f;
        
        self.startWithUnboxingSequence = unboxingExperience;
        
        _vemojiFolderPath = [SceneKit pathForResourceNamed:@"Textures/Vemoji"];
        be_assert (_vemojiFolderPath != nil, "Cannot find the Vemoji folder.");
    }
    return self;
}

#pragma mark - Setup

- (void) start {
    [super start];
    
    self.robotTransformNode = [SCNNode node];
    self.robotTransformNode.scale = SCNVector3Make(self.scale, self.scale, self.scale);
    self.robotTransformNode.rotation = SCNVector4Make(1, 0, 1, M_PI);
    [self.node addChildNode:self.robotTransformNode];
    
    self.robotBodyNode = [SCNNode node];
    [self.robotTransformNode addChildNode:self.robotBodyNode];
    
    self.robotNode = [SCNNode firstNodeFromSceneNamed:@"Robot_NonZeroed.dae"];
    [self setLightingModelForChildren:self.robotNode];
    
    [self.robotBodyNode addChildNode:self.robotNode];
    self.animatedHeadCtrl = [self.robotNode childNodeWithName:@"Head_Ctrl" recursively:YES];
    self.rootCtrl = [self.robotNode childNodeWithName:@"Root_Ctrl" recursively:YES];
    self.sensorCtrl = [self.robotNode childNodeWithName:@"Sensor_Root" recursively:YES];
    self.bodyCtrl = [self.robotNode childNodeWithName:@"Boxy_Body_Mesh" recursively:YES];
    self.robotChestCtrl = [self.robotNode childNodeWithName:@"Body_Door_Ctrl" recursively:YES]; //Rot X to open and close.
    self.robotBoxRootCtrl = [_robotNode childNodeWithName:@"BoxRoot" recursively:YES];
    self.targetLookAtPosition = GLKVector3Make(1000.f, 0.f, 1000.f);
    
    if (!self.startWithUnboxingSequence) {
        [self setupRobotPhysics];
    }
    
    // default
    [self setBodyEmojiDiffuse:@"Status Battery2"];
    
    self.headCtrl = self.animatedHeadCtrl;
    
    self.movementPeakVolume = 0.5;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Init a default audio for movement.
        // Special set-up happens in the setMovementAudio setter.
        AudioNode *moveAudio = [[AudioEngine main] loadAudioNamed:@"Robot_IdleMovingLoop.caf"];
        moveAudio.looping = YES;
        moveAudio.volume = 0;
        [self setMovementAudio:moveAudio];
    });

    // Re-parent the head to a controllable node.
    self.headCtrl = [SCNNode node];
    
    for(SCNNode *child in self.animatedHeadCtrl.childNodes ) {
        [self.headCtrl addChildNode:child];
    }
    
    [self.robotTransformNode addChildNode:self.headCtrl];
    self.headCtrl.position = [self.headCtrl convertPosition:self.animatedHeadCtrl.position toNode:self.robotTransformNode];

    if( self.startWithUnboxingSequence ) {
        __weak RobotMeshControllerComponent *weakSelf = self;

        // Prepare for unboxing sequence. 
        _robotBoxUnfolded = NO;

        self.robotBoxNode = [SCNNode firstNodeFromSceneNamed:@"Robot_Unboxing.dae"];
        [self setLightingModelForChildren:_robotBoxNode];
        [self.robotTransformNode addChildNode:self.robotBoxNode];
        
        self.robotBoxUnfoldingAnim = [AnimationComponent animationWithSceneNamed:@"Robot_Unboxing.dae"];
        [_robotBoxUnfoldingAnim setFadeInDuration:0];
        [_robotBoxUnfoldingAnim setFadeOutDuration:0];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
        SCNAnimationEvent *liftBodyToPositionEvent = [SCNAnimationEvent animationEventWithKeyTime:0.75 block:^(id<SCNAnimation> _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
#else
        SCNAnimationEvent *liftBodyToPositionEvent = [SCNAnimationEvent animationEventWithKeyTime:0.75 block:^(CAAnimation * _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
#endif
            RobotMeshControllerComponent *strongSelf = weakSelf;
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:(1-0.75)*strongSelf.robotBoxUnfoldingAnim.duration];
            // Lift the body into position.
            self.robotBoxNode.position = SCNVector3Make(0, .5f, 0.f);
            [SCNTransaction commit];
        }];

        CGFloat nearEndFrame = (_robotBoxUnfoldingAnim.duration-(10.0/60.0))/_robotBoxUnfoldingAnim.duration;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
        SCNAnimationEvent *finishUnboxingEvent = [SCNAnimationEvent animationEventWithKeyTime:nearEndFrame block:^(id<SCNAnimation> _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
#else
        SCNAnimationEvent *finishUnboxingEvent = [SCNAnimationEvent animationEventWithKeyTime:nearEndFrame block:^(CAAnimation * _Nonnull animation, id  _Nonnull animatedObject, BOOL playingBackward) {
#endif
            RobotMeshControllerComponent *strongSelf = weakSelf;
            if( strongSelf ) {
                strongSelf->_robotBoxUnfolded = YES;
                [SCNTransaction begin];
                [SCNTransaction disableActions];
                [SCNTransaction setAnimationDuration:0];
                [strongSelf->_robotBoxNode setHidden:YES];
                [strongSelf->_robotBodyNode setHidden:NO];
                [strongSelf->_headCtrl setHidden:NO];
                
                self.robotBodyNode.position = SCNVector3Make(0, ROBOT_HOVER_HEIGHT, 0.f);
                self.headCtrl.position = [self.rootCtrl convertPosition:self.animatedHeadCtrl.position toNode:self.robotTransformNode];

                [self handleLookAt:0];
                [SCNTransaction commit];
                
                RobotActionComponent *actionComponent = (RobotActionComponent *)[self.entity componentForClass:[RobotActionComponent class]];
                [actionComponent wait:0.1];
                [actionComponent lookAtMainCamera];
                [actionComponent wait:0.2];
                [actionComponent idleBehaviours:YES];
            }
        }];
        
        // Hide Bridget until we're ready to unfold.
        [_robotBodyNode setHidden:YES];
        [_headCtrl setHidden:YES];
        [_robotBoxUnfoldingAnim setAnimationEvents:@[liftBodyToPositionEvent, finishUnboxingEvent]];
        _robotBoxUnfoldingAnim.speed = 0;
        [_robotBoxNode addAnimation:_robotBoxUnfoldingAnim forKey:ROBOT_BOX_ANIMATION_KEY];

        // Make the robotBox model a selectable that we can target.
        _robotBoxRadius = 0.2;
        self.robotBoxSelectable = [[SelectableModelComponent alloc] initWithMarkupName:@"RobotBox" withRadius:_robotBoxRadius];
        
        // Defer hooking up the component so we don't mutate the SceneManager entities while starting.
        [[SceneManager main].mixedRealityMode runBlockInRenderThread:^(void) {
            [[[SceneManager main] createEntity] addComponent:_robotBoxSelectable];
            [_robotBoxSelectable start];
        }];

        // Handle selecting the box, kick off the box unfolding sequence and remove the callback handler.
        _robotBoxSelectable.callbackBlock = ^{
            RobotMeshControllerComponent *strongSelf = weakSelf;
            if( strongSelf ) {
                [strongSelf setRobotBoxUnfolded:YES];
                [strongSelf setupRobotPhysics];
                strongSelf->_robotBoxSelectable.callbackBlock = nil;
            }
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            self.robotBoxUnfoldingSound = [[AudioEngine main] loadAudioNamed:@"Robot_Unboxing.caf"];
        });
    } else {
        // Robot is already unfolded.
        _robotBoxUnfolded = YES; 

        // Start robot at hidden position above player light is at -3, so y:-4
        // sets the robot above the light to avoid casting a shadow on the
        // ground when the session starts.
        self.node.position = SCNVector3Make(0, -4, 0);
    }

    //  [SceneKit printSceneHierarchy:self.node];
}
                                                  
- (void)setupRobotPhysics {
    SCNNode *colliderNode = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:1.38 height:1.61 length:0.89 chamferRadius:0]];
    colliderNode.scale = {self.scale, self.scale, self.scale};
    colliderNode.position = {0, 0.7, 0};
    colliderNode.opacity = 0.0;
    colliderNode.name = @"Robot Collider";
    colliderNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:nil];
    [self.robotBodyNode addChildNode:colliderNode];
}
                                                  
#pragma mark - CAAnimation control

- (BOOL) isAnimated  {
    return [_robotNode animationKeys].count > 0;
}

-(void) removeAllAnimations {
    [self removeAnimations:self.node];
}

-(void) removeAnimations:(SCNNode *)node {
    [node removeAllAnimations];
    for( SCNNode * child in node.childNodes ) {
        [self removeAnimations:child];
    }
}

-(void) setBody:(RobotBodies)body
{
    
}

-(void) setHead:(RobotHeads)head
{
    [self.headCtrl enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        [child setHidden:YES];
        
        switch (head) {
            case kVemoji:
                if([[child name] containsString:@"Vemoji"])
                    [child setHidden:NO];
                break;
            case kVega:
                if([[child name] containsString:@"Vega"])
                    [child setHidden:NO];
                break;
            case kBoxy:
                if([[child name] containsString:@"Boxy"])
                    [child setHidden:NO];
            default:
                break;
        }
    }];
}

- (GLKVector3) getPosition {
    return SCNVector3ToGLKVector3(self.node.position);
}

- (GLKVector3) getForward {
    return GLKVector3Make( cosf(self.headRotationY), 0.f, sinf(self.headRotationY) );
}

- (void) setPosition:(GLKVector3) position {
    self.node.position = SCNVector3FromGLKVector3(position);
    [self handleMoveTo:0];
}

- (void) setRotationEuler:(GLKVector3) euler {
    self.robotBodyNode.eulerAngles = SCNVector3FromGLKVector3(euler);
}
                                                  
- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    if( ![Scene main].rootNode ) return;
    
    self.time += seconds;

    if( _robotBoxUnfolded == YES || self.startWithUnboxingSequence == NO ) {
        if( !self.isAnimated ) {
            self.robotBodyNode.position = SCNVector3Make(0, ROBOT_HOVER_HEIGHT, 0.f);
            self.headCtrl.position = [self.rootCtrl convertPosition:self.animatedHeadCtrl.position toNode:self.robotTransformNode];
        } else {
            self.headCtrl.position = [self.rootCtrl.presentationNode convertPosition:self.animatedHeadCtrl.presentationNode.position toNode:self.robotTransformNode];
        }

        [self handleLookAt:seconds];
    }
    
    [self handleMoveTo:seconds];
    [self handleHeightOffsetFromNavigationComponent:seconds];
}

#pragma mark - Navigation component (used for height)

- (void) handleHeightOffsetFromNavigationComponent:(float)seconds {
    if(!self.navigationComponent) return;
    
    GLKVector3 position = [self getPosition];
    
    float height = [self.navigationComponent getInterpolatedHeight:position];
    float targetY = position.y;
    
    if( height < 999.f && position.y > height ) {
        targetY = height;
        if( self.currentY > height ) {
            self.currentY = height;
        }
    }
    
    self.currentY = lerpf( self.currentY, targetY, 1.-powf( .03f, seconds ) );
    
    self.node.position = SCNVector3Make(position.x, self.currentY, position.z);
}

#pragma mark - MoveTo


- (void) moveTo:(GLKVector3)moveToTarget moveIn:(float)seconds {
    self.moveToTimer = 0.f;
    self.moveToTimeInterval = seconds;
    self.moveToTarget = moveToTarget;
    self.moveToStart = [self getPosition];
}

- (void) handleMoveTo:(NSTimeInterval)seconds {
    if( _moveToTimeInterval > 0 ) {
        self.moveToTimer += seconds;
        
        // Modify Audio on main thread 
        dispatch_async(dispatch_get_main_queue(), ^{
            if( self.moveToTimer < self.moveToTimeInterval ) {
                if( [_movementAudio.player isPlaying] == NO) {
                    [_movementAudio play];
                }

                float frac = self.moveToTimer / self.moveToTimeInterval;
                self.movementAudio.volume = self.movementPeakVolume * smoothstepDxf(0.f, 1.f, frac);
                float progress = smoothstepf(0.f, 1.f, frac); // Try with basic accelerate/decelerate motion.
                GLKVector3 position = GLKVector3Lerp(self.moveToStart, self.moveToTarget, progress );
                self.node.position = SCNVector3FromGLKVector3(position);
                self.movementAudio.position = self.node.position;
            } else {
                self.node.position = SCNVector3FromGLKVector3(self.moveToTarget); // Get precisely on target.
                self.movementAudio.volume = 0;
                self.movementAudio.position = self.node.position;
                self.moveToTimer = self.moveToTimeInterval = 0; // Clear the timer, stop running movement ops.
            }
        });
    }

    // Track the selectable node. Move it up about half the height of the box.
    if( _robotBoxSelectable && _robotBoxSelectable.callbackBlock != nil ) {
        [SCNTransaction begin];
        [SCNTransaction disableActions];
        [SCNTransaction setAnimationDuration:0];
        SCNVector3 position = self.node.position;
        position.y -= _robotBoxRadius/2;
        _robotBoxSelectable.node.position = position;
        [SCNTransaction commit];
    }
}

- (void) setMovementAudio:(AudioNode *)movementAudio {
    if( _movementAudio != nil ) {
        [_movementAudio stop];
    }
    
    _movementAudio = movementAudio;
    
    if( _movementAudio != nil ) {
        _movementAudio.volume = 0;
        _movementAudio.looping = YES;
        [_movementAudio play];
    }
}

#pragma mark - Lookat

- (void) lookAt:(GLKVector3)lookAtPosition rotateIn:(float)seconds {
    if( GLKVector3IsNan(lookAtPosition) ) {
        return;
    }
    
    self.startHeadRotationX = self.headRotationX;
    self.startHeadRotationY = self.headRotationY;
    
    self.targetLookAtPosition = lookAtPosition;
    
    self.lookAtTimer = 0.f;
    self.lookAtTimeInterval = seconds;
    
    // Re-target body on lookAt with duration.
    [self calculateBodyTargetY];
    [self beginBodyRotationWithInterval:seconds];
}

// Closest angular difference:
// A - B
float angleDifference(float a, float b) {
    return atan2(sin(a-b), cos(a-b));
}

- (void) handleLookAt:(NSTimeInterval)seconds {
    self.lookAtTimer += seconds;

    // Reset head rotation to the animated node before re-calculating relative rotations.
    self.headCtrl.orientation = self.animatedHeadCtrl.presentationNode.orientation;
    [self updateHeadTargetRotations];
    [self handleBodyTargetting:seconds];
    
    float headProgress;
    if( self.lookAtTimeInterval > 0.f ) {
        headProgress = smoothstepf(0,1,saturatef( self.lookAtTimer/self.lookAtTimeInterval ));
    } else {
        headProgress = 1.f;
    }
    
    float xrot = [self lerpAngle:self.startHeadRotationX endAngle:self.targetHeadRotationX f:headProgress];
    float yrot = [self lerpAngle:self.startHeadRotationY endAngle:self.targetHeadRotationY f:headProgress];
    
    // Limit head rotation rate.
    float dy = angleDifference(yrot, _headRotationY);
    float rotLimit = ROBOT_HEAD_ROTATION_RATE_LIMIT * seconds;
    if( dy < -rotLimit ) {
        dy = -rotLimit;
    } else if( dy > rotLimit ) {
        dy = rotLimit;
    }
    
    // rotate head towards target
    self.headRotationY = fmodf(_headRotationY + dy + 2*M_PI, 2*M_PI);
    self.headRotationX = xrot;
    
    self.headCtrl.eulerAngles = SCNVector3Make(self.headRotationX, self.headRotationY, 0.f);
}

- (void) updateHeadTargetRotations {
    if( self.lookAtCamera ) {
        self.targetLookAtPosition = [[Camera main] position];
    }

    GLKVector3 forward = GLKVector3Subtract( SCNVector3ToGLKVector3( [self.headCtrl convertPosition:SCNVector3Zero toNode:[Scene main].rootNode]), self.targetLookAtPosition );
    forward = GLKVector3Normalize(forward);
    
    float l = sqrtf( forward.x*forward.x +forward.z*forward.z);
    
    if( [self isAnimated]
        || ((l < ROBOT_LOOK_AT_MIN_DISTANCE || self.looking == NO) && self.lookAtCamera == NO)
    ){
        // Ease back to zero pose if we're too close or not looking.
        self.targetHeadRotationX = [self lerpAngle:self.targetHeadRotationX endAngle:0 f:0.1];

// DO NOT RETURN Y to zero, or robot always looks to the right.
//        self.targetHeadRotationY = [self lerpAngle:self.targetHeadRotationY endAngle:0 f:0.1];
        return;
    }

    if( [self isAnimated] == NO ) {
        float yRot = atan2f( forward.x, -forward.z ) + M_PI_2;
        float xRot = atan2f( l, forward.y ) - M_PI_2;
        if( isnan(yRot) || isnan(xRot) ) return; // NAN happens if there are any overlaps (zero,zero).

        // Limit X rotation to just shy of M_PI_2 up and down.
        if( xRot >= ROBOT_LOOK_X_ROTATION_LIMIT ) {
            xRot = ROBOT_LOOK_X_ROTATION_LIMIT;
        } else if( xRot <= -ROBOT_LOOK_X_ROTATION_LIMIT ) {
            xRot = -ROBOT_LOOK_X_ROTATION_LIMIT;
        }
        
        // Constraint the relative Y rotation to the limits of body rotation.
        float yRelRot = angleDifference(yRot, self.bodyRotationY);
        if( yRelRot >= ROBOT_LOOK_Y_ROTATION_LIMIT) {
            yRelRot = ROBOT_LOOK_Y_ROTATION_LIMIT;
        } else if( yRelRot <= -ROBOT_LOOK_Y_ROTATION_LIMIT) {
            yRelRot = -ROBOT_LOOK_Y_ROTATION_LIMIT;
        }
        
        yRot = fmodf( yRelRot + self.bodyRotationY + 6.28318530717959f, 6.28318530717959f);
        xRot = fmodf(xRot + 6.28318530717959f, 6.28318530717959f);

        self.targetHeadRotationY = yRot;
        self.targetHeadRotationX = xRot;
    }
}

- (void) handleBodyTargetting:(NSTimeInterval)seconds {
    if( self.bodyTargettingTimeInterval > 0 ) {
        self.bodyTargettingTimer += seconds;

        float bodyProgress;
        if( self.bodyTargettingTimer < self.bodyTargettingTimeInterval ) {
            bodyProgress = saturatef( self.bodyTargettingTimer/self.bodyTargettingTimeInterval );
        } else {
            bodyProgress = 1.f;
            self.bodyTargettingTimeInterval = 0; // We're finished targetting, reset the timer.
            self.bodyTargettingTimer = 0;
        }
    
        [self calculateBodyTargetY];
        float yRotBody = [self lerpAngle:self.startBodyRotationY endAngle:self.bodyTargetRotationY f:bodyProgress];
        
        // Limit body rotation rate.
        float dy = angleDifference(yRotBody, _bodyRotationY);
        float rotLimit = ROBOT_BODY_ROTATION_RATE_LIMIT * seconds;
        if( dy < -rotLimit ) {
            dy = -rotLimit;
        } else if( dy > rotLimit ) {
            dy = rotLimit;
        }
        
        self.bodyRotationY = fmodf(_bodyRotationY + dy + 2*M_PI, 2*M_PI);
        self.robotBodyNode.eulerAngles = SCNVector3Make(0.f, self.bodyRotationY, 0.f);
    } else {
        // Calculate the relative Y-angle to target.
        [self calculateBodyTargetY];

        // Relative rotation.
        float yRelRot = angleDifference(self.bodyTargetRotationY, self.bodyRotationY);
        if( ABS(yRelRot) > ROBOT_BODY_TARGETTING_LIMIT ) {
            [self beginBodyRotationWithInterval:ROBOT_BODY_TARGETTING_INTERVAL];
        }
    }
}

// Calculate the body Y-angle to target.
- (void) calculateBodyTargetY {
    GLKVector3 forward = GLKVector3Subtract( SCNVector3ToGLKVector3( [self.robotBodyNode convertPosition:SCNVector3Zero toNode:[Scene main].rootNode]), self.targetLookAtPosition );
    forward = GLKVector3Normalize(forward);
    
    float bodyRotY = atan2f( forward.x, -forward.z ) + M_PI_2;
    if( isnan(bodyRotY) )  {
        return;
    }

    self.bodyTargetRotationY = bodyRotY;
}

// Initiate the body rotation regartetting.
- (void) beginBodyRotationWithInterval:(float)interval {
    self.startBodyRotationY = self.bodyRotationY;

    // If already moving to a target, take the remaining or greater interval.
    self.bodyTargettingTimeInterval = ROBOT_BODY_TARGETTING_INTERVAL-_bodyTargettingTimer;
    self.bodyTargettingTimer = 0;
}

- (float) lerpAngle:(float)s endAngle:(float)e f:(float)f {
    // Check if we're dealing with a wrapping situation.
    float delta = ABS(e-s);
    if( delta > M_PI ) {
        if( e > s ) {
            s += 2*M_PI; // Push up start
        } else {
            e += 2*M_PI; // Push up end
        }
    }
    
    float preClamp = lerpf(s, e, f); // Angular change should be directly linear now.
    return fmodf(preClamp + M_PI, 2*M_PI) - M_PI;
}

#pragma mark - Robot Material Assignments

- (NSString*)vemojiFilePathFromName:(NSString*)vemojiName
{
    return [NSString stringWithFormat:@"%@/%@.png", _vemojiFolderPath, vemojiName];
}

/**
 * Set's the <nodeName>.geometry.<materialName>.diffuse to the <diffuseImage>
 */
-(void) setNodeNamed:(NSString*)nodeName materialNamed:(NSString*)materialName withDiffuseImageNamed:(NSString*)diffuseImageName {
    
    SCNNode *node = [self.node childNodeWithName:nodeName recursively:YES];
    if( node == nil ) {
        NSLog(@"setNodeNamed:materialNamed:withDiffuseImageNamed: - Missing node: %@", nodeName);
        return;
    }
    
    SCNMaterial *material = [node.geometry materialWithName:materialName];
    if( material == nil ) {
        NSLog(@"setNodeNamed:materialNamed:withDiffuseImageNamed: - Missing material: %@", materialName);
        return;
    }
    
    NSString* resourcePath = [self vemojiFilePathFromName:diffuseImageName];
    UIImage *image = [UIImage imageNamed:resourcePath];
    if( image == nil ) {
        NSLog(@"setNodeNamed:materialNamed:withDiffuseImageNamed: - Missing image: %@ (%@)", diffuseImageName, resourcePath);
        return;
    }
    
//    NSLog(@"Showing %@.%@, %@", nodeName, materialName, diffuseImageName );
    material.diffuse.contents = image;
}

/**
 * Set's the <nodeName>.geometry.<materialName>.emissive to the <emissiveImage>
 */
-(void) setNodeNamed:(NSString*)nodeName materialNamed:(NSString*)materialName withEmissiveImageNamed:(NSString*)emissiveImageName {
    SCNNode *node = [self.node childNodeWithName:nodeName recursively:YES];
    if( node == nil ) {
        NSLog(@"setNodeNamed:materialNamed:withEmissiveImageNamed: - Missing node: %@", nodeName);
        return;
    }
    
    
    SCNMaterial *material = [node.geometry materialWithName:materialName];
    if( material == nil ) {
        NSLog(@"setNodeNamed:materialNamed:withEmissiveImageNamed: - Missing material: %@", materialName);
        return;
    }
    
    NSString* resourcePath = [self vemojiFilePathFromName:emissiveImageName];
    UIImage *image = [UIImage imageNamed:resourcePath];
    if( image == nil ) {
        NSLog(@"setNodeNamed:materialNamed:withEmissiveImageNamed: - Missing image: %@ (%@)", emissiveImageName, resourcePath );
        return;
    }

//    NSLog(@"Showing %@.%@, %@", nodeName, materialName, emissiveImageName );
    material.emission.contents = image;
}

/**
 * Set's the Vemoji_Head_Mesh.geometry.EmojiPrimary_Material.diffuse to the image named vemoji.
 */
-(void) setHeadVemojiDiffuse:(NSString*)vemoji {
    if ([_headVemojiDiffuse isEqualToString:vemoji])
        return;
    
    _headVemojiDiffuse = vemoji;
    [self setNodeNamed:@"Vemoji_Head_Mesh" materialNamed:@"EmojiPrimary_Material" withDiffuseImageNamed:vemoji];
}

/**
 * Set's the Vemoji_Head_Mesh.geometry.EmojiPrimary_Material.emission to the image named vemoji.
 */
-(void) setHeadVemojiEmissive:(NSString*)vemoji {
    if ([_headVemojiEmissive isEqualToString:vemoji])
        return;
    
    _headVemojiEmissive = vemoji;
    [self setNodeNamed:@"Vemoji_Head_Mesh" materialNamed:@"EmojiPrimary_Material" withEmissiveImageNamed:vemoji];
}

/**
 * Set's the Boxy_Body_Mesh.geometry.EmojiSecondary_Material.diffuse to the image named vemoji.
 */
-(void) setBodyEmojiDiffuse:(NSString*)bodyEmoji {
    if ([_bodyEmojiDiffuse isEqualToString:bodyEmoji])
        return;
    
    _bodyEmojiDiffuse = bodyEmoji;
    [self setNodeNamed:@"Boxy_Body_Mesh" materialNamed:@"EmojiSecondary_Material" withDiffuseImageNamed:bodyEmoji];
}

/**
 * this is used to make material settings on the hierarchy this is a pain to set manually in Xcode every time
 * the character is exported from modo.
 */
- (void)setLightingModelForChildren:(SCNNode*)robot
{
    [robot _enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // do what ever material settings here
            [obj setLightingModelName:SCNLightingModelConstant];
            [obj setLitPerPixel:NO];
        }];
    }];
}

#pragma mark - Unboxing Animation Control

- (void) setRobotBoxUnfolded:(BOOL)robotBoxUnfolded {
    if( robotBoxUnfolded == NO ) return;  // One-way latch.

    // Prevent multiple retriggers.
    if( _robotBoxUnfolded == NO && _robotBoxUnfoldingAnim.speed == 0 && robotBoxUnfolded == YES ) {
        [SCNTransaction begin];
        [SCNTransaction disableActions];
        [SCNTransaction setAnimationDuration:0];
        [_robotBoxNode removeAnimationForKey:ROBOT_BOX_ANIMATION_KEY];
        _robotBoxUnfoldingAnim.speed = 1.0;
        [_robotBoxNode addAnimation:_robotBoxUnfoldingAnim forKey:ROBOT_BOX_ANIMATION_KEY];
        [SCNTransaction commit];
        _robotBoxUnfoldingSound.position = self.node.position;
        [_robotBoxUnfoldingSound play];
        
        [[EventManager main] pauseGlobalEventComponents];
    }
}

- (BOOL)robotBoxUnfolded {
    if( self.startWithUnboxingSequence ) {
        BOOL completedUnfold = _robotBoxUnfolded && [_robotBoxNode animationForKey:ROBOT_BOX_ANIMATION_KEY] == nil; 
        return completedUnfold;
    } else {
        return YES;
    }
}

@end
