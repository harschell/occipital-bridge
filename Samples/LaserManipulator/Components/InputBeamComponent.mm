/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#define BEAM_TRIANGLES 10
#define BEAM_WIDTH 0.01f
#define BEAM_HEIGHT 0.01f
#define BEAM_ACTIVE 0.075f

#define BEAM_INTERSECTION_FAR_DISTANCE 50

#import "InputBeamComponent.h"

#import <OpenBE/Core/Core.h>
#import <OpenBE/Utils/SceneKitExtensions.h>
#import <OpenBE/Utils/SceneKitTools.h>
#import <OpenBE/Utils/ComponentUtils.h>
#import <OpenBE/Utils/Math.h>

#import <OpenBE/Components/GazePointerProtocol.h>
#import "InteractablePhysicsComponent.h"

//@import GLKit.GLKVector3;
//@import OpenGLES;

@interface InputBeamComponent ()

@property (atomic) float beamActive;

@end

@implementation InputBeamComponent

#pragma mark - Initilization

- (id) init {
    self = [super init];
    
    self.startPos = GLKVector3Make(0, 0, 0);
    self.endPos = GLKVector3Make(0, 0, 1);
    
    self.beamWidth = BEAM_WIDTH;
    self.beamHeight = BEAM_HEIGHT;
    self.beamActive = 0.2f;

    [self createBeam];
    
    return self;
}

#pragma mark - Public

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    self.node.hidden = !enabled;
}

- (void)setBeamState:(InputBeamState)state {
    switch (state) {
        case InputBeamStateIdle:
            self.beamWidth = BEAM_WIDTH;
            self.beamHeight = BEAM_HEIGHT;
            self.node.geometry.firstMaterial.diffuse.contents = [UIColor redColor];
            break;
            
        case InputBeamStateItemDetected:
            self.beamWidth = BEAM_WIDTH * 2;
            self.beamHeight = BEAM_HEIGHT * 2;
            break;
            
        case InputBeamStateActiveNoItem:
            self.beamWidth = BEAM_WIDTH * 2;
            self.beamHeight = BEAM_HEIGHT * 2;
            break;
            
        case InputBeamStateActiveItem:
            self.beamWidth = BEAM_WIDTH * 6;
            self.beamHeight = BEAM_HEIGHT * 6;
            self.beamActive = BEAM_ACTIVE * 2;
            break;
    }
}

#pragma mark - Setup / Display

- (void) createBeam {
    self.node = [SCNNode node];
    [[Scene main].rootNode addChildNode:self.node];
    self.node.name = @"InputScanBeam";
    
    SCNVector3 positions[BEAM_TRIANGLES*3];
    int indices[BEAM_TRIANGLES*3];
    
    for( int i=0; i<BEAM_TRIANGLES; i++ ) {
        float random = (float)drand48();
        
        positions[i*3+0] = SCNVector3Make(0, 0, random);
        positions[i*3+1] = SCNVector3Make(1, 1, random);
        positions[i*3+2] = SCNVector3Make(1, 0, random);
        
        indices[i*3+0] = i*3+0;
        indices[i*3+1] = i*3+1;
        indices[i*3+2] = i*3+2;
    }
    
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions count:(BEAM_TRIANGLES*3)];
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                               primitiveCount:BEAM_TRIANGLES
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource]
                                                    elements:@[element]];
    self.node.geometry = geometry;
    self.node.categoryBitMask |= RAYCAST_IGNORE_BIT;
    
    
    SCNMaterial * material = [SCNMaterial material];
    material.doubleSided = YES;
    
    self.node.geometry.materials = @[ material ];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"width" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, self.beamWidth);
    }];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"height" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, self.beamHeight);
    }];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"active" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, self.beamActive);
    }];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"startPos" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform3fv(location, 1, self.startPos.v);
    }];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"endPos" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform3fv(location, 1, self.endPos.v);
    }];
    
    [self.node.geometry.firstMaterial handleBindingOfSymbol:@"shaderType" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, 0.f);
    }];
    
    SCNProgram * program = [SCNProgram programWithShader:@"Shaders/CombinedShader/combinedShader"];
    [program setOpaque:NO];
    
    self.node.geometry.firstMaterial.program = program;
    self.node.geometry.firstMaterial.blendMode = SCNBlendModeAdd;
    self.node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 90;
    [self.node setCastsShadowRecursively:NO];
}

@end
