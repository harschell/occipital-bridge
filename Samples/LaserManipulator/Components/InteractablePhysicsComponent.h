/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>

#import <OpenBE/Core/GeometryComponent.h>
#import "../Core/PhysicsEventComponentProtocol.h"

/**
 `InteractablePhysicsComponent` is a component that has both geometry and a physics body.  It can be manipulated as it conforms to 'PhysicsEventComponentProtocol'.
 
 This class also conforms to copyWithZone:, and it creates deep copies with new geometries and materials. Don't make a lot of copies or you'll hurt performance.
 */

@interface InteractablePhysicsComponent : GeometryComponent<PhysicsEventComponentProtocol>

/**
 Initializes an `InteractablePhysicsComponent` object with a node and geometry to base the physics object on.
 @param node The node for this object. This node should already have geometry and materials defined.
 @param geometry The general shape of the physics collider.
 @return The newly-initialized component.
 */
- (instancetype) initWithVisibleNode:(SCNNode *)node physicsGeometry:(SCNGeometry *)geometry;

@end
