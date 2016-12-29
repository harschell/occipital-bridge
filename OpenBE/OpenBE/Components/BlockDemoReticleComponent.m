/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BlockDemoReticleComponent.h"
#import "../Utils/SceneKitExtensions.h"
#import "../Utils/Math.h"

@import GLKit.GLKVector3;
@import GLKit;

@interface BlockDemoReticleComponent ()

@property (weak) GazeComponent * gazeComponent;

@property (atomic) float currentDistance;
@property (atomic) float targetDistance;

@property (atomic) float xRotation;
@property (atomic) float yRotation;
@property (atomic) GLKQuaternion currentRotation;
@property (atomic) GLKQuaternion targetRotation;


@end

@implementation BlockDemoReticleComponent

- (id) init {
    self = [super init];
    
    self.radius = .075f / 2.f;
    
    self.idleDistance = 2.f;
    self.zOffset = .025f;
    self.currentDistance = self.targetDistance = self.idleDistance;
    
    [self createReticle];
    
    return self;
}

- (void) createReticle {
    SCNNode * node = [SCNNode firstNodeFromSceneNamed:@"BlockDemoReticle.dae"];
    
    node.categoryBitMask |= RAYCAST_IGNORE_BIT;
    node.castsShadow = NO;
    double scale;
    
    [node getBoundingSphereCenter:NULL radius:&scale];
    scale = self.radius/ scale;
    node.scale = SCNVector3Make(scale,scale,scale);
    
    SCNMaterial * material = [SCNMaterial material];
    
    material.diffuse.contents = [UIColor colorWithHue:.5f saturation:.8f brightness:.5f alpha:1.f];

    
    node.geometry.materials = @[material];
    
    [self registerNodeToEntity:node];
    [[Scene main].rootNode addChildNode:self.node];
}

- (void) onGazeStart:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive {
    
    [self handleGaze:gazeComponent intersection:intersection isInteractive:isInteractive];
}

- (void) onGazeStay:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive {
    
    [self handleGaze:gazeComponent intersection:intersection isInteractive:isInteractive];
}

- (void) onGazeExit:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity {
    self.gazeComponent = gazeComponent;
    
    self.targetDistance = self.idleDistance;
}


- (void) handleGaze:(GazeComponent *) gazeComponent intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive {
    
    self.gazeComponent = gazeComponent;
    
    self.targetDistance = gazeComponent.intersectionDistance - self.zOffset;
    
    GLKVector3 normal = SCNVector3ToGLKVector3( intersection.worldNormal );
    
    self.xRotation = atan2f( -normal.y, normal.z );
    self.yRotation = atan2f( normal.x, normal.z ) + M_PI;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    static float t;
    
    t = t+seconds;
    
    
    GLKMatrix3 rot = GLKMatrix3MakeXRotation(t);
    self.targetRotation = GLKQuaternionMakeWithMatrix3( rot );
    
    self.currentDistance = self.targetDistance;
    
    self.node.eulerAngles = SCNVector3Make( self.xRotation, self.yRotation, 0.f );
    
    self.node.position = SCNVector3FromGLKVector3( GLKVector3Add( [Camera main].position,
                                                                 GLKVector3MultiplyScalar( [Camera main].reticleForward, self.currentDistance)) );
}

@end
