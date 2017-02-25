/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

//  Apply a globally rendered overlay of a specific color to the screen.
//  Good for fade to Black, fade to White, or strobe effect for
//  things like taking a hit.

#import "ColorOverlayComponent.h"
#import "../Core/Core.h"
#import "../Utils/Program.h"
#import "../Utils/Math.h"
#import "../Utils/SceneKitTools.h"
#import <GLKit/GLKVector3.h>
#import <OpenGLES/EAGL.h>

//@import GLKit.GLKVector3;
//@import OpenGLES;

@interface ColorOverlayComponent ()

@end

@implementation ColorOverlayComponent

- (id) init {
    self = [super init];
    if( self ) {
        [self createOverlay];
        self.color = [UIColor clearColor];
    }
    return self;
}

- (void) createOverlay {
    self.node = [self createSceneNode];
    
    self.node.name = @"ColorOverlay";
    
    SCNVector3 positions[] = {
        SCNVector3Make(-1,-1,0),
        SCNVector3Make( 1,-1,0),
        SCNVector3Make( 1, 1,0),
        SCNVector3Make(-1, 1,0)
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

    SCNMaterial *material = self.node.geometry.firstMaterial;
    material.lightingModelName = SCNLightingModelConstant;
    material.readsFromDepthBuffer = false;
    material.writesToDepthBuffer = false;
    material.doubleSided = true;
    self.node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 999; // Stay behind HUD and FixedSizeReticle.
    [SceneKitTools setCastShadow:NO ofNode:self.node];
}

/**
 * Set the color with alpha
 * When alpha is zero, no overlay is rendered.
 */
- (void) setColor:(UIColor *)color {
    _color = color;
    self.node.geometry.firstMaterial.diffuse.contents = color;
    CGFloat white, alpha;
    [color getWhite:&white alpha:&alpha];
    if( alpha == 0 ) {
        self.node.hidden = YES;
    } else {
        self.node.hidden = NO;
    }
}

/**
 * Align the overlay directly in front of the camera
 */
- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( self.node.hidden ) {
        return;
    }

    Camera *mainCam = [Camera main];
    SCNNode *camNode = mainCam.node;
    SCNQuaternion camOrientation = camNode.orientation;
     
    GLKQuaternion orientation = GLKQuaternionMake(camOrientation.x,
                                                  camOrientation.y,
                                                  camOrientation.z,
                                                  camOrientation.w );
    
    // Place just in front of the camera.
    float forwardOffset = mainCam.camera.zNear + 0.1;
    GLKVector3 forward = GLKQuaternionRotateVector3( orientation, GLKVector3Make(0, 0, forwardOffset) );
    self.node.position = SCNVector3FromGLKVector3( GLKVector3Add( [Camera main].position, forward ) );
    self.node.orientation = camNode.orientation;
}

@end
