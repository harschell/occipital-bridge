//
//  EnvironmentShader.h
//  MixedReality-partners
//
//  Created by Nicholas Shelton on 1/3/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#ifndef EnvironmentShader_h
#define EnvironmentShader_h

#import <BridgeEngine/BridgeEngine.h>
#import "BridgeEngine/BEShader.h"

// The OpenGL name for the camera texture.
extern GLuint CUSTOM_RENDER_MODE_CAMERA_TEXTURE_NAME;

@interface CustomRenderMode : NSObject<BridgeEngineShaderDelegate>

- (void)compile;
- (void)prepareWithProjection:(const float *)projection
                    modelview:(const float *)modelView
           depthBufferTexture:(const GLuint)depthTexture
           cameraImageTexture:(const GLuint)cameraTexture;

- (const char *)fragmentShaderSource;
- (const char *)vertexShaderSource;

@property GLuint projectionMatrixLocation;
@property GLuint modelviewMatrixLocation;
@property GLuint depthSamplerLocation;
@property GLuint cameraSamplerLocation;
@property GLuint renderResolutionLocation;

@property GLuint glProgram;
@property bool loaded;

@end

#endif /* EnvironmentShader_h */
