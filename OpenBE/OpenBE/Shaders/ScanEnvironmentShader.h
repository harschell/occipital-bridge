/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// #import <BridgeEngine/BridgeEngine.h>
#import <BridgeEngine/BEMixedRealityMode.h>
#import <BridgeEngine/BEShader.h>

@interface ScanEnvironmentShader : NSObject <BridgeEngineShaderDelegate>

@property (atomic) float scanTime;
@property (atomic) float duration;
@property (atomic) float scanRadius;
@property (atomic) GLKVector3 scanOrigin;
@property (strong) BEMixedRealityMode * mixedRealityMode;

- (void) setActive:(bool)active;

- (void) compile;
- (void) prepareWithProjection:(const float*)projection
                     modelview:(const float*)modelView
            depthBufferTexture:(const GLuint)depthTexture
            cameraImageTexture:(const GLuint)cameraTexture;

- (const char *) fragmentShaderSource;
- (const char *) vertexShaderSource;

@property GLuint projectionMatrixLocation;
@property GLuint modelviewMatrixLocation;
@property GLuint depthSamplerLocation;
@property GLuint cameraSamplerLocation;
@property GLuint renderResolutionLocation;

@property GLuint glProgram;
@property bool loaded;

@end
