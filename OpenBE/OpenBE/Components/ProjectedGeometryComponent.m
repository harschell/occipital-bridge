//
//  ProjectedGeometryComponent.m
//  Bifrost
//
//  Created by Andrew Zimmer on 7/18/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#import "ProjectedGeometryComponent.h"
#import "../Utils/SceneKitExtensions.h"

@implementation ProjectedGeometryComponent

- (instancetype)initWithChildNode:(SCNNode *)node {
    if(self = [super init]) {
        self.node = [self createSceneNode];
        [self.node addChildNode:node];
        
        self.node.name = @"ProjectedGeometry";
        self.node.hidden = YES;
        
        [self setShaderForChildren:self.node];
    }
    
    return self;
}

// This recursive method sets the shader type for the component and all child nodes to the projection shader in combined shader.
- (void)setShaderForChildren:(SCNNode *)rootNode {
    SCNProgram * program = [SCNProgram programWithShader:@"Shaders/CombinedShader/combinedShader"];
    [program setOpaque:NO];
    
    [rootNode _enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 1000;
        node.castsShadow = NO;
        
        [node.geometry.materials enumerateObjectsUsingBlock:^(SCNMaterial * _Nonnull material, NSUInteger idx, BOOL * _Nonnull stop) {
            [material handleBindingOfSymbol:@"shaderType" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
                glUniform1f(location, 3.f);
            }];
            
            material.program = program;
            material.blendMode = SCNBlendModeReplace;
            
            material.readsFromDepthBuffer = false;
            material.writesToDepthBuffer = false;
        }];
    }];
}

@end
