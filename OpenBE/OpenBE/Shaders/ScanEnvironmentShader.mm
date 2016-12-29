/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ScanEnvironmentShader.h"

#import <BridgeEngine/BridgeEngine.h>
#import <BridgeEngine/BEMixedRealityMode.h>
#import <BridgeEngine/BEShader.h>

#import "../Utils/SceneKitExtensions.h"

#include <OpenGLES/ES2/gl.h>

@interface ScanEnvironmentShader()

@property (strong) NSString * shaderName;

@property GLuint scanTimeLocation;
@property GLuint durationLocation;
@property GLuint scanRadiusLocation;
@property GLuint scanOriginLocation;

@end;

@implementation ScanEnvironmentShader

- (id) init {
    self = [super init];
    
    self.shaderName = @"Shaders/ScanEnvironment/scanEnvironmentShader";
    // Alternative shader with distortions of the camera feed.
    // self.shaderName = @"Shaders/ScanEnvironment/scanEnvironmentShaderWithDistortion";
    
    return self;
}

- (void) setActive:(bool)active {
    if( active ) {

        [self.mixedRealityMode setCustomRenderStyle:self];
        [self.mixedRealityMode setRenderStyle:BERenderStyleSceneKitAndCustomEnvironmentShader withDuration:0.f];
    } else {
        [self.mixedRealityMode setRenderStyle:BERenderStyleSceneKitAndColorCamera withDuration:0.f];
    }
}

//delegate methods
- (void) compile
{
    const int NUM_ATTRIBS = 2;
    // Vertex and Normal Layout
    GLuint attributeIds[NUM_ATTRIBS] = {0, 1};
    const char *attributeNames[NUM_ATTRIBS] = { "a_position", "a_normal" };

    self.glProgram = BEShaderLoadProgramFromString ([self vertexShaderSource],
                                                    [self fragmentShaderSource],
                                                    NUM_ATTRIBS,
                                                    attributeIds,
                                                    attributeNames);
    
    self.projectionMatrixLocation = glGetUniformLocation(self.glProgram, "u_perspective_projection");
    self.modelviewMatrixLocation = glGetUniformLocation(self.glProgram, "u_modelview");
    self.scanTimeLocation = glGetUniformLocation(self.glProgram, "u_scanTime");
    self.durationLocation = glGetUniformLocation(self.glProgram, "u_scanDuration");
    self.scanRadiusLocation = glGetUniformLocation(self.glProgram, "u_scanRadius");
    self.scanOriginLocation = glGetUniformLocation(self.glProgram, "u_scanOrigin");
    
    self.depthSamplerLocation = glGetUniformLocation(self.glProgram, "u_depthSampler");
    self.cameraSamplerLocation = glGetUniformLocation(self.glProgram, "u_colorSampler");
    self.renderResolutionLocation = glGetUniformLocation(self.glProgram, "u_resolution");
    
    self.loaded = true;
}


- (void) prepareWithProjection:(const float*)projection
                     modelview:(const float*)modelView
            depthBufferTexture:(const GLuint)depthTexture
            cameraImageTexture:(const GLuint)cameraTexture
{

    
    glUseProgram(self.glProgram);

    glUniformMatrix4fv(self.modelviewMatrixLocation, 1, GL_FALSE, modelView);
    glUniformMatrix4fv(self.projectionMatrixLocation, 1, GL_FALSE, projection);
    glUniform1f(self.scanTimeLocation, self.scanTime);
    glUniform1f(self.durationLocation, self.duration);
    glUniform1f(self.scanRadiusLocation, self.scanRadius);
    glUniform3fv(self.scanOriginLocation,1,self.scanOrigin.v);
    
    
    // Load mesh depth into texture unit 6.
    glActiveTexture(GL_TEXTURE6);
    glBindTexture(GL_TEXTURE_2D, depthTexture);
    glUniform1i (self.depthSamplerLocation, GL_TEXTURE6 - GL_TEXTURE0);
    
    // Load camera image into texture unit 7.
    glActiveTexture(GL_TEXTURE7);
    glBindTexture(GL_TEXTURE_2D, cameraTexture);
    glUniform1i (self.cameraSamplerLocation, GL_TEXTURE7 - GL_TEXTURE0);
    
    // update resolution
    GLint vp[4];
    glGetIntegerv(GL_VIEWPORT, vp);
    glUniform2f(self.renderResolutionLocation, vp[2], vp[3]);
    
    glEnable(GL_DEPTH_TEST);
    
}

-(const char *) vertexShaderSource
{
    NSURL *vertexShaderURL   = [SceneKit URLForResource:self.shaderName withExtension:@"vsh"];
    NSString *vertexShader   = [[NSString alloc] initWithContentsOfURL:vertexShaderURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
    return [vertexShader UTF8String];
}

-(const char *) fragmentShaderSource
{
    NSURL *fragmentShaderURL = [SceneKit URLForResource:self.shaderName withExtension:@"fsh"];
    NSString *fragmentShader = [[NSString alloc] initWithContentsOfURL:fragmentShaderURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
    return [fragmentShader UTF8String];
}

@end
