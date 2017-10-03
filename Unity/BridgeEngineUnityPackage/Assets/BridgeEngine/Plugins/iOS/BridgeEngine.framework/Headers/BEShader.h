/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>

#import <GLKit/GLKit.h>

/// Utility function to create a GL program.
BE_API
GLuint BEShaderLoadProgramFromString (const char *vertex_shader_src,
                                      const char *fragment_shader_src,
                                      const int num_attributes,
                                      GLuint *attribute_ids,
                                      const char **attribute_names);

/// Experimental API to create custom shaders
BE_API
@protocol BridgeEngineShaderDelegate

/// This method should load the GL program and fill the properties listed below.
- (void) compile;

/** Prepare the shader uniforms.
 This will get called for every frame, before rendering the mapped area.
 @param projection a 4x4 column-major matrix storing the projection matrix
 @param modelView a 4x4 column-major matrix storing the modelView matrix
 @param depthTexture float texture that was already created by rendering the mapped area mesh.
 @param cameraTexture color texture with the live iOS camera feed.
*/
- (void) prepareWithProjection:(const float*)projection
                     modelview:(const float*)modelView
            depthBufferTexture:(const GLuint)depthTexture
            cameraImageTexture:(const GLuint)cameraTexture;

- (const char *) fragmentShaderSource;
- (const char *) vertexShaderSource;

@property GLuint projectionMatrixLocation;
@property GLuint modelviewMatrixLocation;
@property GLuint glProgram;
@property bool loaded;
@end
