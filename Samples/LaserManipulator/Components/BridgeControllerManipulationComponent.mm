/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#define MAX_MOVE_DISTANCE 3

#import "BridgeControllerManipulationComponent.h"

#import <OpenBE/Core/Core.h>
#import <OpenBE/Core/AudioEngine.h>
#import <OpenBE/Utils/ComponentUtils.h>
#import <OpenBE/Utils/SceneKitTools.h>
#import <OpenBE/Components/BridgeControllerComponent.h>
#import <OpenBE/Components/PhysicsContactAudioComponent.h>


#import "../Core/GeometryHitTest.h"
#import "InputBeamComponent.h"

@interface BridgeControllerManipulationComponent()
@property (nonatomic, strong) BridgeControllerComponent *bridgeController;
@property (nonatomic, strong) InputBeamComponent *beamComponent;

@property (nonatomic, strong) id<PhysicsEventComponentProtocol> activeComponent;
@property (nonatomic, strong) id<PhysicsEventComponentProtocol> connectedComponent;

@property (nonatomic, strong) SCNPhysicsBallSocketJoint *joint;
@property (nonatomic) CGFloat distanceToJoint;

@property (nonatomic) GLKVector2 touchPosition;
@property (nonatomic) float startDistanceToJoint;

@end

@implementation BridgeControllerManipulationComponent

#pragma mark - Initilization

- (void)start {
    [super start];
    
    self.bridgeController = (BridgeControllerComponent *)[ComponentUtils getComponentFromEntity:self.entity ofClass:[BridgeControllerComponent class]];
    if (self.bridgeController == nil) {
        be_dbg("Can't start BridgeControllerManipulationComponent without a BridgeControllerComponent added to the entity.");
    }
    NSAssert(self.bridgeController != nil, @"Can't start BridgeControllerManipulationComponent without a BridgeControllerComponent added to the entity.");
    
    self.beamComponent = (InputBeamComponent *)[ComponentUtils getComponentFromEntity:self.entity ofClass:[InputBeamComponent class]];
    if (self.beamComponent == nil) {
        be_dbg("Can't start BridgeControllerManipulationComponent without an InputBeamComponent added to the entity.");
    }
    NSAssert(self.bridgeController != nil, @"Can't start BridgeControllerManipulationComponent without an InputBeamComponent added to the entity.");
    
    [self clearTouchPosition];
    
    [self.bridgeController.node setHidden:YES];
}

#pragma mark - Public

- (void)setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    
    [self.bridgeController.node setHidden:!enabled];
    [self.beamComponent setEnabled:enabled];
    [self.bridgeController setEnabled:enabled];
}

- (SCNVector3)currentIntersectionPoint {
    SCNHitTestResult *result = [self raycastFromController];
    
    if (result) {
        return result.worldCoordinates;
    } else {
        return SCNVector3Make(INTERSECTION_FAR_DISTANCE, INTERSECTION_FAR_DISTANCE, INTERSECTION_FAR_DISTANCE);
    }
}

- (void)setTriggerDown:(BOOL)down {
    if (down) {
        if (self.activeComponent) {
            [self createJoint:self.activeComponent];
            [self.beamComponent setBeamState:InputBeamStateActiveItem];
        } else {
            [self.beamComponent setBeamState:InputBeamStateActiveNoItem];
        }
    } else {
        if (self.connectedComponent) {
            [self destroyJoint];
        }
        [self.beamComponent setBeamState:InputBeamStateIdle];
    }
}

/*
 * Unfortunately status isn't functioning, so I'll have to hack this to work with just position;
 */
- (void)controllerTouchPosition:(GLKVector2)position status:(BEControllerTouchStatus)status {
    
    // Touch up hack for if you don't have that nice status.
    if (status == BECTouchIdle ) {
        [self clearTouchPosition];
        return;
    }
    
    if (self.touchPosition.x == -1 && self.touchPosition.y == -1) { // null state
        self.touchPosition = position;
        self.startDistanceToJoint = self.distanceToJoint;
    } else { // move
        CGFloat deltaY = (position.y - self.touchPosition.y) / 2;  // the pad goes from -1 to 1, so 2.
        self.distanceToJoint = self.startDistanceToJoint + MAX_MOVE_DISTANCE * deltaY;
        self.distanceToJoint = MAX(MIN(self.distanceToJoint, 6), 0.1);
    }
}

/* This is a hack. It should be removed when BEController is returning status. */
- (void)clearTouchPosition {
    self.touchPosition = GLKVector2Make(-1, -1);
}

#pragma mark - Physics

- (void)createJoint:(id<PhysicsEventComponentProtocol>)component {
    [self destroyJoint];
    
    SCNPhysicsBody *physicsBody = [component getPhysicsBody];
    
    self.distanceToJoint = [self distanceFromNode:component.node];
    self.joint = [SCNPhysicsBallSocketJoint jointWithBody:physicsBody anchor:SCNVector3Zero];
    [self movePhysicsBody];  // init the anchor position
    
    [[Scene main].scene.physicsWorld addBehavior:self.joint];
    self.connectedComponent = component;
    [self.connectedComponent heldStart];
}

- (void)destroyJoint {
    if (self.connectedComponent) {
        [[Scene main].scene.physicsWorld removeBehavior:self.joint];
        self.joint = nil;
        [self.connectedComponent heldEnded];
        self.connectedComponent = nil;
    }
    
    [self clearTouchPosition];
}

- (void)movePhysicsBody {
    GLKVector3 start = SCNVector3ToGLKVector3([SceneKitTools getWorldPos:self.beamComponent.node]);
    GLKVector3 worldPos  = GLKVector3Add(start, GLKVector3MultiplyScalar([self forwardVector], self.distanceToJoint));
    
    if (self.joint != nil) {
        self.joint.anchorB = SCNVector3FromGLKVector3(worldPos);
        self.beamComponent.endPos = GLKVector3Make(0, 0, self.distanceToJoint);
    }
}

#pragma mark - Update

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    [super updateWithDeltaTime:seconds];

    if (self.connectedComponent != nil) {  // only drag one item at a time
        [self movePhysicsBody];
        return;
    }
    
    // Raycast and set our beam length
    SCNHitTestResult *result = [self raycastFromController];
    [self setBeamLength:result];
    
    // Look for items along our raycast
    id<PhysicsEventComponentProtocol> intersectingItem = [self findIntersectionObjects:result];
    if (intersectingItem) {
        if (intersectingItem == self.activeComponent) {
            [intersectingItem gazeStay:result];            
        } else {
            [self.beamComponent setBeamState:InputBeamStateItemDetected];
            [intersectingItem gazeStart:result];
            self.activeComponent = intersectingItem;
        }
    } else {
        [self.beamComponent setBeamState:InputBeamStateIdle];
        [self.activeComponent gazeExit];
        self.activeComponent = nil;
    }
}

- (id<PhysicsEventComponentProtocol>)findIntersectionObjects:(SCNHitTestResult *)result {
    GKEntity * resultEntity = [result.node valueForKey:@"entity"];
    GKComponent<PhysicsEventComponentProtocol> *entityEventComponent = (GKComponent<PhysicsEventComponentProtocol> *)[ComponentUtils getComponentFromEntity:resultEntity ofProtocol:@protocol(PhysicsEventComponentProtocol)];
    
    if (entityEventComponent != NULL) {
        return entityEventComponent;
    }
    
    return nil;
}

- (void)setBeamLength:(SCNHitTestResult *)result {
    GLKVector3 beamStartWorld = SCNVector3ToGLKVector3( [SceneKitTools getWorldPos:self.beamComponent.node] );
    GLKVector3 hit = SCNVector3ToGLKVector3(result.worldCoordinates);
    float distance = GLKVector3Length( GLKVector3Subtract(beamStartWorld, hit) );
    self.beamComponent.endPos = GLKVector3Make(0, 0, distance);
}

#pragma mark - Math / Raycasting

- (SCNHitTestResult *)raycastFromController {
    GLKVector3 start = SCNVector3ToGLKVector3([SceneKitTools getWorldPos:self.beamComponent.node]);
    GLKVector3 forwardVector  = [self forwardVector];
    return [GeometryHitTest performHitTestWithStartPosition:start forwardOrientation:forwardVector maxDistance:INTERSECTION_FAR_DISTANCE];
}

- (GLKVector3)forwardVector {
    GLKVector3 forwardVector = GLKVector3Make(self.beamComponent.node.worldTransform.m31,
                   self.beamComponent.node.worldTransform.m32,
                   self.beamComponent.node.worldTransform.m33);
    return GLKVector3Normalize(forwardVector);
}

- (float)distanceFromNode:(SCNNode *)node {
    GLKVector3 beamStartWorld = SCNVector3ToGLKVector3( [SceneKitTools getWorldPos:self.beamComponent.node] );
    GLKVector3 nodeWorld = SCNVector3ToGLKVector3 ( [SceneKitTools getWorldPos:node] );
    GLKVector3 offset = GLKVector3Subtract(nodeWorld, beamStartWorld);
    return GLKVector3Length(offset);
}

@end
