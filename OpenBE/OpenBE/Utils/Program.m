/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "Program.h"

@implementation Program

+ (SCNProgram *)createProgramWithShader:(NSString *)shaderName {
    NSURL *vertexShaderURL   = [[NSBundle mainBundle] URLForResource:shaderName withExtension:@"vsh"];
    NSURL *fragmentShaderURL = [[NSBundle mainBundle] URLForResource:shaderName withExtension:@"fsh"];
    NSString *vertexShader   = [[NSString alloc] initWithContentsOfURL:vertexShaderURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
    NSString *fragmentShader = [[NSString alloc] initWithContentsOfURL:fragmentShaderURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
    
    // Create a shader program and assign the shaders
    SCNProgram *program = [SCNProgram program];
    program.vertexShader   = vertexShader;
    program.fragmentShader = fragmentShader;
    
    // Attributes (position, normal, texture coordinate)
    [program setSemantic:SCNGeometrySourceSemanticVertex
               forSymbol:@"position"
                 options:nil];
    [program setSemantic:SCNGeometrySourceSemanticNormal
               forSymbol:@"normal"
                 options:nil];
    [program setSemantic:SCNGeometrySourceSemanticTexcoord
               forSymbol:@"textureCoordinate"
                 options:nil];
    
    // Uniforms (the three different transformation matrices)
    [program setSemantic:SCNModelViewProjectionTransform
               forSymbol:@"modelViewProjection"
                 options:nil];
    [program setSemantic:SCNModelViewTransform
               forSymbol:@"modelView"
                 options:nil];
    [program setSemantic:SCNNormalTransform
               forSymbol:@"normalTransform"
                 options:nil];
    [program setSemantic:SCNProjectionTransform
               forSymbol:@"projection"
                 options:nil];
    
    return program;
}

@end
