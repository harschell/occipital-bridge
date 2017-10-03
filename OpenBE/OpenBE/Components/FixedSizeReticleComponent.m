/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "FixedSizeReticleComponent.h"
#import "../Utils/Math.h"
#import "../Core/Core.h"
#import "../Utils/SceneKitExtensions.h"

@import GLKit.GLKVector3;
@import OpenGLES;

@interface FixedSizeReticleComponent ()

@property (weak) GazeComponent * gazeComponent;

@property (nonatomic) float currentDistance;
@property (nonatomic) float targetDistance;
@property (nonatomic) float interactive;

@end

@implementation FixedSizeReticleComponent

- (id) init {
    self = [super init];
    
    self.radius = .0275f;
    self.idleDistance = 2.f;
    self.dampFactor = .01f;
    
    self.currentDistance = self.idleDistance;
    
    [self createReticle];
    
    return self;
}

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    [self updateReticleVisibility];
}

- (void) createReticle {
    self.node = [self createSceneNode];
    self.node.castsShadow = NO;
    
    self.node.name = @"FixedSizeReticle";
    
    SCNVector3 positions[] = {
        SCNVector3Make(-self.radius,-self.radius,0),
        SCNVector3Make( self.radius,-self.radius,0),
        SCNVector3Make( self.radius, self.radius,0),
        SCNVector3Make(-self.radius, self.radius,0)
    };
    int indices[] = {
        0, 1, 2,
        0, 2, 3
    };
    
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions count:4];
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                               primitiveCount:2
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource]
                                                    elements:@[element]];
    self.node.geometry = geometry;
    self.node.categoryBitMask |= RAYCAST_IGNORE_BIT;
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"shaderType" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, 1.f);
    }];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"active" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, self.interactive);
    }];
    
    SCNProgram * program = [SCNProgram programWithShader:@"Shaders/CombinedShader/combinedShader"];
    [program setOpaque:NO];
    
    self.node.geometry.firstMaterial.program = program;
    self.node.geometry.firstMaterial.blendMode = SCNBlendModeReplace;

    self.node.geometry.firstMaterial.readsFromDepthBuffer = false;
    self.node.geometry.firstMaterial.writesToDepthBuffer = false;
    self.node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 1000;
    
    [self.node setCastsShadowRecursively:NO];
}

- (void) onGazeStart:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive {
    
    [self handleGaze:gazeComponent isInteractive:isInteractive];
}

- (void) onGazeStay:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive {
    
    [self handleGaze:gazeComponent isInteractive:isInteractive];
}

- (void) onGazeExit:(GazeComponent *) gazeComponent  targetEntity:(GKEntity *) targetEntity {
    self.gazeComponent = gazeComponent;
    
    self.targetDistance = self.idleDistance;
    self.interactive = 0.f;
}


- (void) handleGaze:(GazeComponent *) gazeComponent isInteractive:(bool)isInteractive {
    
    self.gazeComponent = gazeComponent;
    self.interactive = isInteractive?1.f:0.f;
    self.targetDistance = gazeComponent.intersectionDistance;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    self.currentDistance = lerpf( self.currentDistance, self.targetDistance, 1.f-powf( self.dampFactor, seconds ) );
    self.node.position = SCNVector3FromGLKVector3( GLKVector3Add( [Camera main].position, GLKVector3MultiplyScalar( [Camera main].reticleForward, self.currentDistance)));
    
    [self updateReticleVisibility];
}

- (void) updateReticleVisibility {
    // Override showing the reticle geometry depending on tracking state,
    // so we don't overlay reticle on top of the the sign saying "Look Back at Scene" 
    BOOL hideReticleNotTracking = [SceneManager main].mixedRealityMode.lastTrackerHints.isOrientationOnly || ([SceneManager main].mixedRealityMode.lastTrackerPoseAccuracy == BETrackerPoseAccuracyNotAvailable);
    BOOL hideReticle = hideReticleNotTracking || (self.isEnabled==NO);
    if( self.node.hidden != hideReticle) {
        self.node.hidden = hideReticle;
    }
}

@end
