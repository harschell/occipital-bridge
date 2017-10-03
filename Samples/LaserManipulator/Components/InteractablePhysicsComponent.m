/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "InteractablePhysicsComponent.h"
#import <OpenBE/Core/Core.h>

@interface InteractablePhysicsComponent()
@property (nonatomic) BOOL isHeld;
@end

@implementation InteractablePhysicsComponent

#pragma mark - Init

- (instancetype) initWithVisibleNode:(SCNNode *)node physicsGeometry:(SCNGeometry *)geometry {
    self = [super init];
    if( self ) {
        self.node = node;
        self.node.categoryBitMask |= RAYCAST_IGNORE_BIT | BEShadowCategoryBitMaskCastShadowOntoSceneKit | BEShadowCategoryBitMaskCastShadowOntoEnvironment;
        
        self.node.physicsBody = [SCNPhysicsBody dynamicBody];
        [self.node.physicsBody setPhysicsShape:[SCNPhysicsShape shapeWithGeometry:geometry options:nil]];
        self.node.physicsBody.mass = 1.0;
        self.node.physicsBody.restitution = 0.5;
        self.node.physicsBody.friction = 0.8;
        self.node.physicsBody.damping = 0.05;
        self.node.physicsBody.angularDamping = 0.1;
        self.node.physicsBody.rollingFriction = 0.1;
        self.node.physicsBody.allowsResting = YES;
        
        self.node.physicsBody.categoryBitMask = SCNPhysicsCollisionCategoryDefault | BECollisionCategoryVirtualObjects;
        self.node.physicsBody.collisionBitMask = BECollisionCategoryRealWorld | BECollisionCategoryVirtualObjects | BECollisionCategoryFloor;
        self.node.physicsBody.contactTestBitMask = SCNPhysicsCollisionCategoryAll;
    }
    return self;
}

#pragma mark - PhysicsEventComponentProtocol

- (void) gazeStart:(SCNHitTestResult *)hit {
    self.node.geometry.firstMaterial.emission.contents = [UIColor whiteColor];
}

- (void) gazeStay:(SCNHitTestResult *)hit {
    
}

- (void) gazeExit {
    if (!self.isHeld) {
        self.node.geometry.firstMaterial.emission.contents = [UIColor clearColor];
    }
}

- (void)heldStart {
    self.isHeld = YES;
    self.node.geometry.firstMaterial.emission.contents = [UIColor whiteColor];
    self.node.physicsBody.angularDamping = 1;
    //self.node.physicsBody.rollingFriction = 1;
    //self.node.physicsBody.collisionBitMask = BECollisionCategoryVirtualObjects;
    [self.node.physicsBody clearAllForces];
}

- (void)heldEnded {
    self.isHeld = NO;
    self.node.geometry.firstMaterial.emission.contents = [UIColor clearColor];
    self.node.physicsBody.angularDamping = 0.1;
    self.node.physicsBody.collisionBitMask = BECollisionCategoryRealWorld | BECollisionCategoryVirtualObjects | BECollisionCategoryFloor;
}

- (SCNPhysicsBody *)getPhysicsBody {
    return self.node.physicsBody;
}

- (id)copyWithZone:(NSZone *)zone {
    be_dbg("copy with zone interactable");
    InteractablePhysicsComponent *component = [super copyWithZone:zone];
    return component;
}

@end
